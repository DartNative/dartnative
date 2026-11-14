import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'graphql.dart';

/// Channel to the iOS host (endpoint override and the benchmark log marker).
const MethodChannel nativeChannel = MethodChannel('shopbench/native');

const String _defaultEndpoint = 'https://apparel-large-catalog.mock.shop/api';
const String _buildTimeEndpoint = String.fromEnvironment('SHOP_API_URL');

/// Resolves the endpoint: on iOS the `SHOP_API_URL` launch environment
/// variable (read natively), then the `SHOP_API_URL` build-time define
/// (Android), then the default mock.shop endpoint.
Future<Uri> resolveEndpoint() async {
  if (Platform.isIOS) {
    try {
      final String? env = await nativeChannel.invokeMethod<String>('apiUrl');
      if (env != null && env.isNotEmpty) return Uri.parse(env);
    } catch (_) {}
  }
  if (_buildTimeEndpoint.isNotEmpty) return Uri.parse(_buildTimeEndpoint);
  return Uri.parse(_defaultEndpoint);
}

/// Adds the `width` query parameter to an image URL returned by the API.
String sizedImage(String url, int width) =>
    url.contains('?') ? '$url&width=$width' : '$url?width=$width';

class Money {
  const Money(this.amount);
  final double amount;

  static Money? parse(Object? json) {
    if (json is! Map) return null;
    final Object? a = json['amount'];
    if (a == null) return null;
    return Money(double.tryParse(a.toString()) ?? 0);
  }

  String format() => '\$${amount.toStringAsFixed(2)}';
}

String? _imageUrl(Object? json) => json is Map ? json['url'] as String? : null;

class ProductSummary {
  ProductSummary({
    required this.handle,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.compareAt,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> j) {
    final Money price =
        Money.parse(j['priceRange']?['minVariantPrice']) ?? const Money(0);
    final Money? compare = Money.parse(j['compareAtPriceRange']?['minVariantPrice']);
    return ProductSummary(
      handle: j['handle'] as String,
      title: j['title'] as String? ?? '',
      imageUrl: _imageUrl(j['featuredImage']),
      price: price,
      compareAt: compare != null && compare.amount > price.amount ? compare : null,
    );
  }

  final String handle;
  final String title;
  final String? imageUrl;
  final Money price;

  /// Only set when it is greater than [price].
  final Money? compareAt;
}

class CollectionSummary {
  CollectionSummary({required this.handle, required this.title, this.imageUrl});
  final String handle;
  final String title;
  final String? imageUrl;
}

class HomeData {
  HomeData(this.collections, this.bestSellers);
  final List<CollectionSummary> collections;
  final List<ProductSummary> bestSellers;
}

class ProductPage {
  ProductPage(this.products, this.hasNextPage, this.endCursor,
      {this.description, this.totalCount});
  final List<ProductSummary> products;
  final bool hasNextPage;
  final String? endCursor;
  final String? description;
  final int? totalCount;
}

class Variant {
  Variant({
    required this.id,
    required this.title,
    required this.availableForSale,
    required this.selectedOptions,
    required this.price,
    required this.compareAt,
  });
  final String id;
  final String title;
  final bool availableForSale;
  final Map<String, String> selectedOptions;
  final Money price;
  final Money? compareAt;
}

class ProductOption {
  ProductOption(this.name, this.values);
  final String name;
  final List<String> values;
}

class ProductDetail {
  ProductDetail({
    required this.title,
    required this.description,
    required this.images,
    required this.options,
    required this.variants,
    required this.recommendations,
  });
  final String title;
  final String description;
  final List<String> images;
  final List<ProductOption> options;
  final List<Variant> variants;
  final List<ProductSummary> recommendations;
}

class CartLine {
  CartLine({
    required this.id,
    required this.quantity,
    required this.total,
    required this.productTitle,
    required this.variantTitle,
    required this.imageUrl,
  });
  final String id;
  final int quantity;
  final Money total;
  final String productTitle;
  final String variantTitle;
  final String? imageUrl;
}

class Cart {
  Cart({
    required this.id,
    required this.checkoutUrl,
    required this.totalQuantity,
    required this.subtotal,
    required this.lines,
  });

  factory Cart.fromJson(Map<String, dynamic> j) {
    final List<dynamic> nodes = j['lines']?['nodes'] as List<dynamic>? ?? <dynamic>[];
    return Cart(
      id: j['id'] as String,
      checkoutUrl: j['checkoutUrl'] as String? ?? '',
      totalQuantity: (j['totalQuantity'] as num?)?.toInt() ?? 0,
      subtotal: Money.parse(j['cost']?['subtotalAmount']) ?? const Money(0),
      lines: nodes.map((dynamic n) {
        final Map<String, dynamic> m = n as Map<String, dynamic>;
        final Map<String, dynamic> merch =
            m['merchandise'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final Map<String, dynamic> product =
            merch['product'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return CartLine(
          id: m['id'] as String,
          quantity: (m['quantity'] as num?)?.toInt() ?? 0,
          total: Money.parse(m['cost']?['totalAmount']) ?? const Money(0),
          productTitle: product['title'] as String? ?? '',
          variantTitle: merch['title'] as String? ?? '',
          imageUrl: _imageUrl(merch['image']) ?? _imageUrl(product['featuredImage']),
        );
      }).toList(),
    );
  }

  final String id;
  final String checkoutUrl;
  final int totalQuantity;
  final Money subtotal;
  final List<CartLine> lines;
}

class CartResult {
  CartResult(this.cart, this.errorMessage);
  final Cart? cart;
  final String? errorMessage;
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StorefrontApi {
  StorefrontApi._();

  static final StorefrontApi instance = StorefrontApi._();

  final Future<Uri> _endpoint = resolveEndpoint();
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  Future<Map<String, dynamic>> _send(
      String operationName, Map<String, dynamic> variables) async {
    final HttpClientRequest req = await _client.postUrl(await _endpoint);
    final List<int> payload = utf8.encode(jsonEncode(<String, dynamic>{
      'operationName': operationName,
      'query': kStorefrontDocument,
      'variables': variables,
    }));
    req.headers.contentType = ContentType.json;
    req.contentLength = payload.length;
    req.add(payload);
    final HttpClientResponse res =
        await req.close().timeout(const Duration(seconds: 30));
    final String body =
        await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 30));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}');
    }
    final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('No data');
    }
    return data;
  }

  Future<HomeData> home() async {
    final Map<String, dynamic> d = await _send('Home', <String, dynamic>{});
    final List<dynamic> cols = d['collections']['nodes'] as List<dynamic>;
    final List<dynamic> prods = d['products']['nodes'] as List<dynamic>;
    return HomeData(
      cols
          .map((dynamic c) => CollectionSummary(
                handle: c['handle'] as String,
                title: c['title'] as String? ?? '',
                imageUrl: _imageUrl(c['image']),
              ))
          .toList(),
      prods.map((dynamic p) => ProductSummary.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }

  Future<ProductPage> collectionProducts({
    required String handle,
    String? after,
    required String sortKey,
    required bool reverse,
  }) async {
    final Map<String, dynamic> d = await _send('CollectionProducts', <String, dynamic>{
      'handle': handle,
      'first': 24,
      'after': after,
      'sortKey': sortKey,
      'reverse': reverse,
    });
    final Map<String, dynamic>? c = d['collection'] as Map<String, dynamic>?;
    if (c == null) throw ApiException('Collection not found');
    return _page(c['products'] as Map<String, dynamic>,
        description: c['description'] as String? ?? '');
  }

  Future<ProductPage> search(String query, {String? after}) async {
    final Map<String, dynamic> d = await _send('Search', <String, dynamic>{
      'query': query,
      'first': 24,
      'after': after,
    });
    final Map<String, dynamic> s = d['search'] as Map<String, dynamic>;
    return _page(s, totalCount: (s['totalCount'] as num?)?.toInt() ?? 0);
  }

  ProductPage _page(Map<String, dynamic> conn, {String? description, int? totalCount}) {
    final Map<String, dynamic> info = conn['pageInfo'] as Map<String, dynamic>;
    final List<dynamic> nodes = conn['nodes'] as List<dynamic>;
    return ProductPage(
      nodes
          .whereType<Map<String, dynamic>>()
          .where((Map<String, dynamic> n) => n['handle'] != null)
          .map(ProductSummary.fromJson)
          .toList(),
      info['hasNextPage'] as bool? ?? false,
      info['endCursor'] as String?,
      description: description,
      totalCount: totalCount,
    );
  }

  Future<ProductDetail> product(String handle) async {
    final Map<String, dynamic> d =
        await _send('Product', <String, dynamic>{'handle': handle});
    final Map<String, dynamic>? p = d['product'] as Map<String, dynamic>?;
    if (p == null) throw ApiException('Product not found');
    final List<dynamic> recs = d['productRecommendations'] as List<dynamic>? ?? <dynamic>[];
    return ProductDetail(
      title: p['title'] as String? ?? '',
      description: p['description'] as String? ?? '',
      images: (p['images']['nodes'] as List<dynamic>)
          .map((dynamic i) => i['url'] as String?)
          .whereType<String>()
          .toList(),
      options: (p['options'] as List<dynamic>)
          .map((dynamic o) => ProductOption(
                o['name'] as String,
                (o['optionValues'] as List<dynamic>)
                    .map((dynamic v) => v['name'] as String)
                    .toList(),
              ))
          .toList(),
      variants: (p['variants']['nodes'] as List<dynamic>).map((dynamic v) {
        final Money price = Money.parse(v['price']) ?? const Money(0);
        final Money? compare = Money.parse(v['compareAtPrice']);
        return Variant(
          id: v['id'] as String,
          title: v['title'] as String? ?? '',
          availableForSale: v['availableForSale'] as bool? ?? false,
          selectedOptions: <String, String>{
            for (final dynamic so in v['selectedOptions'] as List<dynamic>)
              so['name'] as String: so['value'] as String,
          },
          price: price,
          compareAt: compare != null && compare.amount > price.amount ? compare : null,
        );
      }).toList(),
      recommendations: recs
          .map((dynamic r) => ProductSummary.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<CartResult> _cartMutation(
      String op, String field, Map<String, dynamic> variables) async {
    final Map<String, dynamic> d = await _send(op, variables);
    final Map<String, dynamic>? payload = d[field] as Map<String, dynamic>?;
    if (payload == null) throw ApiException('No cart');
    final List<dynamic> errors = payload['userErrors'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic>? cart = payload['cart'] as Map<String, dynamic>?;
    return CartResult(
      cart == null ? null : Cart.fromJson(cart),
      errors.isEmpty ? null : (errors.first['message'] as String? ?? 'Error'),
    );
  }

  Future<CartResult> cartCreate(String variantId) =>
      _cartMutation('CartCreate', 'cartCreate', <String, dynamic>{
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{'merchandiseId': variantId, 'quantity': 1},
        ],
      });

  Future<CartResult> cartLinesAdd(String cartId, String variantId) =>
      _cartMutation('CartLinesAdd', 'cartLinesAdd', <String, dynamic>{
        'cartId': cartId,
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{'merchandiseId': variantId, 'quantity': 1},
        ],
      });

  Future<CartResult> cartLinesUpdate(String cartId, String lineId, int quantity) =>
      _cartMutation('CartLinesUpdate', 'cartLinesUpdate', <String, dynamic>{
        'cartId': cartId,
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{'id': lineId, 'quantity': quantity},
        ],
      });
}

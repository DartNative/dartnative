// Adapted from flutter_http_example, the "Dart Package Search" app in
// dart-lang/http (pkgs/flutter_http_example: lib/main.dart and
// lib/package.dart).
// Copyright (c) 2022, 2026, the Dart project authors. BSD-3-Clause; see
// THIRD_PARTY_NOTICES.
//
// The screens, states, requests and text are upstream's. What differs:
// - one NativeHttpClient for the app, the same code on iOS and Android, in
//   place of the client factory that picks a client per platform;
// - the root widget's State owns the client, hands it down and closes it,
//   in place of package:provider;
// - the list is a FastList, which builds its rows as they near the screen,
//   as Flutter's ListView.builder does;
// - the publisher's icon is an Image.network, in place of
//   package:http_image_provider;
// - the screen keeps the platform's defaults: no theme, no text colours or
//   weights, and the bar places its title where the platform does.

import 'dart:convert';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_http/http.dart';
import 'package:http/http.dart';

/// Searches pub.dev's package names as you type and shows each package's
/// publisher, likes and downloads. Every request goes through one
/// [NativeHttpClient].
class PackageSearchApp extends StatefulWidget {
  const PackageSearchApp({super.key});

  @override
  State<PackageSearchApp> createState() => _PackageSearchAppState();
}

class _PackageSearchAppState extends State<PackageSearchApp> {
  // One client for the whole app: created with the root widget, handed to
  // every widget that makes requests, and closed when the root is disposed.
  // NativeHttpClient uses NSURLSession on iOS and OkHttp on Android, so the
  // same line serves both platforms.
  //
  // Reusing the same `Client` may:
  // - reduce memory usage
  // - allow caching of fetched URLs
  // - allow connections to be persisted
  final Client _client = NativeHttpClient();

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchPage(client: _client);
}

class SearchPage extends StatefulWidget {
  final Client client;

  const SearchPage({required this.client, super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<String>? _allPackages;
  List<String>? _matchingNames;
  bool _loadingPackages = false;
  String? _errorMessage;
  String? _lastQuery;
  late Client _client;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _loadPackageList();
  }

  Future<void> _loadPackageList() async {
    setState(() {
      _loadingPackages = true;
      _errorMessage = null;
    });
    try {
      final response = await _client.get(
        Uri.https('pub.dev', '/api/package-name-completion-data'),
      );
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final packagesList = (json['packages'] as List<dynamic>).cast<String>()
          ..sort((a, b) => a.compareTo(b));
        setState(() {
          _allPackages = packagesList;
          _loadingPackages = false;
          _runSearch(_lastQuery ?? '');
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load package list: Status ${response.statusCode}';
          _loadingPackages = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load package list: $e';
        _loadingPackages = false;
      });
    }
  }

  void _runSearch(String query) {
    _lastQuery = query;
    final allPackages = _allPackages;
    if (allPackages == null) return;

    if (query.isEmpty) {
      setState(() => _matchingNames = allPackages);
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _matchingNames = allPackages
          .where((name) => name.toLowerCase().contains(lowercaseQuery))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loadingPackages) {
      body = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading package database...'),
          ],
        ),
      );
    } else if (_errorMessage != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPackageList,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_matchingNames == null) {
      body = const Center(child: Text('Loading...'));
    } else {
      body = PackageList(
        packageNames: _matchingNames!,
        client: _client,
      );
    }

    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(title: const Text('Dart Package Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // The field draws its own icon (`prefixIcon` takes an icon, not a
            // widget): a rounded field on iPhone, and Material's outlined
            // field with a floating label on Android. The padding keeps the
            // icon off the border.
            TextField(
              onChanged: _runSearch,
              prefixIcon: Icons.search,
              prefixIconPadding: const EdgeInsets.only(left: 8),
              decoration: const InputDecoration(
                labelText: 'Search packages',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class PackageList extends StatelessWidget {
  final List<String> packageNames;
  final Client client;

  const PackageList({
    required this.packageNames,
    required this.client,
    super.key,
  });

  // Rows are built as they come near the screen, and a row more than 250
  // points away from it is released, as in Flutter's ListView. So a card
  // fetches its package's details just before it is seen, and the requests
  // and the memory follow the screen, not the length of the list. A row that
  // scrolls back in fetches again.
  @override
  Widget build(BuildContext context) => FastList(
        itemCount: packageNames.length,
        cacheExtent: 250,
        itemBuilder: (context, index) {
          final name = packageNames[index];
          return PackageCard(
            key: ValueKey(name),
            name: name,
            client: client,
          );
        },
      );
}

class PackageCard extends StatefulWidget {
  final String name;
  final Client client;

  const PackageCard({
    required this.name,
    required this.client,
    super.key,
  });

  @override
  State<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  late Future<Package> _packageFuture;

  @override
  void initState() {
    super.initState();
    _packageFuture = _fetchPackageInfo(widget.name, widget.client);
  }

  Future<Package> _fetchPackageInfo(String name, Client client) async {
    final results = await Future.wait([
      client.get(Uri.https('pub.dev', '/api/packages/$name/score')),
      client.get(Uri.https('pub.dev', '/api/packages/$name/publisher')),
    ]);

    final scoreResponse = results[0];
    final publisherResponse = results[1];

    if (scoreResponse.statusCode == 200 &&
        publisherResponse.statusCode == 200) {
      final scoreJson = jsonDecode(utf8.decode(scoreResponse.bodyBytes))
          as Map<String, dynamic>;
      final publisherJson = jsonDecode(utf8.decode(publisherResponse.bodyBytes))
          as Map<String, dynamic>;
      final publisherId = publisherJson['publisherId'] as String?;
      return Package.fromJson(name, scoreJson, publisherId: publisherId);
    } else {
      throw Exception('Failed to load package info');
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Package>(
            future: _packageFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Text('Error loading info for ${widget.name}');
              }

              final package = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(package.name, style: const TextStyle(fontSize: 18)),
                  if (package.publisherId != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          // Image.network loads and caches the icon on the
                          // native side; it does not go through the app's
                          // Client.
                          child: Image.network(
                            Uri.https('www.google.com', '/s2/favicons', {
                              'sz': '64',
                              'domain': package.publisherId,
                            }).toString(),
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                            errorWidget: const Icon(Icons.public, size: 16),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(package.publisherId!),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('${package.likes} Likes'),
                      const SizedBox(width: 24),
                      const Icon(Icons.download_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('${package.downloads} Downloads'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class Package {
  final String name;
  final int likes;
  final int downloads;
  final String? publisherId;

  Package({
    required this.name,
    required this.likes,
    required this.downloads,
    required this.publisherId,
  });

  factory Package.fromJson(
    String name,
    Map<String, dynamic> json, {
    required String? publisherId,
  }) =>
      Package(
        name: name,
        likes: json['likeCount'] as int? ?? 0,
        downloads: json['downloadCount30Days'] as int? ?? 0,
        publisherId: publisherId,
      );
}

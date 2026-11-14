import 'dart:io';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

bool _homeReadyLogged = false;

void _logHomeReady() {
  if (_homeReadyLogged) return;
  _homeReadyLogged = true;
  if (Platform.isIOS) {
    nativeChannel.invokeMethod<void>('homeReady').catchError((Object _) {});
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeData? _data;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = false;
      _data = null;
    });
    try {
      final HomeData data = await StorefrontApi.instance.home();
      if (!mounted) return;
      setState(() => _data = data);
      WidgetsBinding.instance.addPostFrameCallback((_) => _logHomeReady());
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: SafeArea(
        bottom: false,
        child: _error
            ? Column(
                children: <Widget>[
                  const _Header(),
                  Expanded(child: ErrorState(onRetry: _load)),
                ],
              )
            : _data == null
                ? const _HomeSkeleton()
                : _HomeContent(data: _data!),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text('Everbloom', style: ts(22, weight: FontWeight.w700, letterSpacing: -0.4)),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: <Widget>[
                SkeletonBox(width: 52, height: 36, radius: 999),
                SizedBox(width: 8),
                SkeletonBox(width: 110, height: 36, radius: 999),
                SizedBox(width: 8),
                SkeletonBox(width: 96, height: 36, radius: 999),
                SizedBox(width: 8),
                SkeletonBox(width: 80, height: 36, radius: 999),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SkeletonBox(height: 240, radius: 12),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: SkeletonBox(width: 120, height: 18, radius: 4),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                SkeletonBox(width: 140, height: 175),
                SizedBox(width: 12),
                SkeletonBox(width: 140, height: 175),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 175)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.data});
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final List<CollectionSummary> cols = data.collections;
    return Semantics(
      identifier: 'home-scroll',
      container: true,
      explicitChildNodes: true,
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36 + 8 + 12,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: cols.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int i) => Tap(
                  id: 'collection-chip-$i',
                  onTap: () => openCollection(context, cols[i]),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(cols[i].title, style: ts(14, weight: FontWeight.w500)),
                  ),
                ),
              ),
            ),
          ),
          if (cols.isNotEmpty) SliverToBoxAdapter(child: _FeaturedBanner(collection: cols.first)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Text('Collections', style: ts(17, weight: FontWeight.w700)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 175 + 8 + MediaQuery.textScalerOf(context).scale(36),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cols.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int i) => Tap(
                  id: 'collection-card-$i',
                  onTap: () => openCollection(context, cols[i]),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 140,
                          height: 175,
                          child: NetImage(cols[i].imageUrl, width: 480, radius: 8),
                        ),
                        const SizedBox(height: 8),
                        Text(cols[i].title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ts(14, weight: FontWeight.w600, lineHeight: 18)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Text('Best sellers', style: ts(17, weight: FontWeight.w700)),
            ),
          ),
          productGridSliver(data.bestSellers, 'best-seller'),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.collection});
  final CollectionSummary collection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Tap(
        id: 'featured-collection',
        onTap: () => openCollection(context, collection),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                NetImage(collection.imageUrl, width: 1080, alignment: const Alignment(0, -0.4)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: AppColors.overlay,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('FEATURED COLLECTION',
                            style: ts(12,
                                weight: FontWeight.w600,
                                color: AppColors.background,
                                letterSpacing: 0.6)),
                        const SizedBox(height: 2),
                        Text(collection.title,
                            style: ts(20, weight: FontWeight.w700, color: AppColors.background)),
                        const SizedBox(height: 2),
                        Text('Shop now', style: ts(14, color: AppColors.background)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

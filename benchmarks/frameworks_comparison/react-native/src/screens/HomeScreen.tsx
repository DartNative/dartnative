import React, { useCallback, useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { Collection, gql, HomeData, ProductCardData } from '../api';
import { HOME } from '../graphql';
import { colors } from '../theme';
import { useNav } from '../navigation';
import { ErrorState, ProductCard, RemoteImage, textStyles, TopInset } from '../components/common';
import NativeShopBench from '../../specs/NativeShopBench';

type State = { status: 'loading' } | { status: 'error' } | { status: 'ready'; data: HomeData };

export function HomeScreen() {
  const nav = useNav();
  const { width } = useWindowDimensions();
  const [state, setState] = useState<State>({ status: 'loading' });

  const load = useCallback(() => {
    setState({ status: 'loading' });
    gql<HomeData>('Home', HOME)
      .then(data => setState({ status: 'ready', data }))
      .catch(() => setState({ status: 'error' }));
  }, []);

  useEffect(load, [load]);

  useEffect(() => {
    if (state.status === 'ready') {
      try {
        NativeShopBench.markHomeReady();
      } catch {}
    }
  }, [state.status]);

  const openCollection = (c: Collection) => nav.push('Collection', { handle: c.handle, title: c.title });
  const openProduct = (p: ProductCardData) => nav.push('Product', { handle: p.handle });

  const header = (
    <View style={styles.header}>
      <Text style={styles.wordmark}>Everbloom</Text>
    </View>
  );

  if (state.status === 'error') {
    return (
      <View style={styles.screen}>
        <TopInset />
        {header}
        <ErrorState onRetry={load} />
      </View>
    );
  }

  if (state.status === 'loading') {
    return (
      <View style={styles.screen}>
        <TopInset />
        {header}
        <View style={styles.chipsRow}>
          {[52, 110, 96, 80].map(w => (
            <View key={w} style={[styles.skelChip, { width: w }]} />
          ))}
        </View>
        <View style={[styles.banner, styles.skeleton]} />
        <View style={styles.skelHeading}>
          <View style={styles.skelHeadingBar} />
        </View>
        <View style={styles.skelCards}>
          {[0, 1, 2].map(i => (
            <View key={i} style={styles.skelCard} />
          ))}
        </View>
      </View>
    );
  }

  const { collections, products } = state.data;
  const featured = collections.nodes[0];
  const cardWidth = (width - 32 - 12) / 2;

  return (
    <View style={styles.screen}>
      <TopInset />
      <ScrollView testID="home-scroll" contentContainerStyle={styles.scrollContent}>
        {header}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.chipsRow}>
          {collections.nodes.map((c, i) => (
            <Pressable key={c.id} testID={`collection-chip-${i}`} style={styles.chip} onPress={() => openCollection(c)}>
              <Text style={styles.chipText}>{c.title}</Text>
            </Pressable>
          ))}
        </ScrollView>
        {featured ? (
          <Pressable testID="featured-collection" style={styles.banner} onPress={() => openCollection(featured)}>
            <RemoteImage url={featured.image?.url} width={1080} style={StyleSheet.absoluteFill} />
            <View style={styles.bannerOverlay}>
              <Text style={styles.bannerLabel}>FEATURED COLLECTION</Text>
              <Text style={styles.bannerTitle}>{featured.title}</Text>
              <Text style={styles.bannerCta}>Shop now</Text>
            </View>
          </Pressable>
        ) : null}
        <View style={styles.section}>
          <Text style={[textStyles.sectionHeading, styles.sectionHeadingPad]}>Collections</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.carousel}>
            {collections.nodes.map((c, i) => (
              <Pressable
                key={c.id}
                testID={`collection-card-${i}`}
                style={styles.collectionCard}
                onPress={() => openCollection(c)}>
                <RemoteImage url={c.image?.url} width={480} style={styles.collectionImage} />
                <Text style={styles.collectionTitle} numberOfLines={2}>
                  {c.title}
                </Text>
              </Pressable>
            ))}
          </ScrollView>
        </View>
        <View style={[styles.section, styles.bestSellers]}>
          <Text style={[textStyles.sectionHeading, styles.bestHeading]}>Best sellers</Text>
          <View style={styles.grid}>
            {products.nodes.map((p, i) => (
              <ProductCard
                key={p.id}
                testID={`best-seller-${i}`}
                product={p}
                width={cardWidth}
                onPress={openProduct}
              />
            ))}
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  scrollContent: { paddingBottom: 24 },
  header: { height: 44, paddingHorizontal: 16, justifyContent: 'center' },
  wordmark: { fontSize: 22, fontWeight: '700', letterSpacing: -0.4, color: colors.text },
  chipsRow: { flexDirection: 'row', gap: 8, paddingTop: 8, paddingBottom: 12, paddingHorizontal: 16 },
  chip: {
    height: 36,
    paddingHorizontal: 14,
    borderRadius: 999,
    backgroundColor: colors.surface,
    justifyContent: 'center',
  },
  chipText: { fontSize: 14, fontWeight: '500', color: colors.text },
  banner: {
    marginTop: 4,
    marginHorizontal: 16,
    height: 240,
    borderRadius: 12,
    overflow: 'hidden',
    backgroundColor: colors.surface,
  },
  bannerOverlay: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    padding: 16,
    gap: 2,
    backgroundColor: 'rgba(28, 27, 25, 0.72)',
  },
  bannerLabel: { color: colors.white, fontSize: 12, fontWeight: '600', letterSpacing: 0.6 },
  bannerTitle: { color: colors.white, fontSize: 20, fontWeight: '700' },
  bannerCta: { color: colors.white, fontSize: 14 },
  section: { paddingTop: 28 },
  sectionHeadingPad: { paddingHorizontal: 16, paddingBottom: 12 },
  carousel: { flexDirection: 'row', gap: 12, paddingHorizontal: 16 },
  collectionCard: { width: 140, gap: 8 },
  collectionImage: { width: 140, height: 175, borderRadius: 8 },
  collectionTitle: { fontSize: 14, fontWeight: '600', lineHeight: 18, color: colors.text },
  bestSellers: { paddingHorizontal: 16 },
  bestHeading: { marginBottom: 12 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', columnGap: 12, rowGap: 20 },
  skeleton: { backgroundColor: colors.skeleton },
  skelChip: { height: 36, borderRadius: 999, backgroundColor: colors.skeleton },
  skelHeading: { paddingTop: 28, paddingHorizontal: 16, paddingBottom: 12 },
  skelHeadingBar: { width: 120, height: 18, borderRadius: 4, backgroundColor: colors.skeleton },
  skelCards: { flexDirection: 'row', gap: 12, paddingHorizontal: 16 },
  skelCard: { width: 140, height: 175, borderRadius: 8, backgroundColor: colors.skeleton },
});

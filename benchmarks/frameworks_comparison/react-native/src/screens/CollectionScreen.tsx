import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import { CollectionProductsData, gql, PageInfo, ProductCardData } from '../api';
import { COLLECTION_PRODUCTS } from '../graphql';
import { colors } from '../theme';
import { useNav } from '../navigation';
import { ErrorState, Loading, NavBar, ProductCard, TopInset } from '../components/common';

const SORTS = [
  { id: 'featured', label: 'Featured', sortKey: 'COLLECTION_DEFAULT', reverse: false },
  { id: 'best-selling', label: 'Best selling', sortKey: 'BEST_SELLING', reverse: false },
  { id: 'price-asc', label: 'Price: low to high', sortKey: 'PRICE', reverse: false },
  { id: 'price-desc', label: 'Price: high to low', sortKey: 'PRICE', reverse: true },
] as const;

type SortId = (typeof SORTS)[number]['id'];

type State = {
  status: 'loading' | 'error' | 'ready';
  products: ProductCardData[];
  pageInfo: PageInfo | null;
  loadingMore: boolean;
  moreError: boolean;
};

const initial: State = { status: 'loading', products: [], pageInfo: null, loadingMore: false, moreError: false };

export function CollectionScreen({ handle, title }: { handle: string; title: string }) {
  const nav = useNav();
  const { width } = useWindowDimensions();
  const [sort, setSort] = useState<SortId>('featured');
  const [description, setDescription] = useState<string>('');
  const [navTitle, setNavTitle] = useState<string>(title);
  const [state, setState] = useState<State>(initial);
  const requestId = useRef(0);
  const stateRef = useRef(state);
  stateRef.current = state;

  const fetchPage = useCallback(
    (sortId: SortId, after: string | null) => {
      const s = SORTS.find(x => x.id === sortId)!;
      return gql<CollectionProductsData>('CollectionProducts', COLLECTION_PRODUCTS, {
        handle,
        first: 24,
        after,
        sortKey: s.sortKey,
        reverse: s.reverse,
      });
    },
    [handle],
  );

  const loadFirst = useCallback(
    (sortId: SortId) => {
      const id = ++requestId.current;
      setState(initial);
      fetchPage(sortId, null)
        .then(data => {
          if (id !== requestId.current) {
            return;
          }
          const c = data.collection;
          if (!c) {
            throw new Error('Collection not found');
          }
          setDescription(c.description);
          setNavTitle(c.title);
          setState({
            status: 'ready',
            products: c.products.nodes,
            pageInfo: c.products.pageInfo,
            loadingMore: false,
            moreError: false,
          });
        })
        .catch(() => {
          if (id === requestId.current) {
            setState({ ...initial, status: 'error' });
          }
        });
    },
    [fetchPage],
  );

  useEffect(() => loadFirst(sort), [loadFirst, sort]);

  const loadMore = useCallback(() => {
    const s = stateRef.current;
    if (s.status !== 'ready' || s.loadingMore || !s.pageInfo?.hasNextPage) {
      return;
    }
    const id = requestId.current;
    setState(prev => ({ ...prev, loadingMore: true, moreError: false }));
    fetchPage(sort, s.pageInfo.endCursor)
      .then(data => {
        if (id !== requestId.current) {
          return;
        }
        const c = data.collection;
        if (!c) {
          throw new Error('Collection not found');
        }
        setState(prev => ({
          ...prev,
          products: [...prev.products, ...c.products.nodes],
          pageInfo: c.products.pageInfo,
          loadingMore: false,
        }));
      })
      .catch(() => {
        if (id === requestId.current) {
          setState(prev => ({ ...prev, loadingMore: false, moreError: true }));
        }
      });
  }, [fetchPage, sort]);

  const cardWidth = (width - 32 - 12) / 2;
  const openProduct = useCallback((p: ProductCardData) => nav.push('Product', { handle: p.handle }), [nav]);

  const header = (
    <View>
      {description ? (
        <View style={styles.descriptionWrap}>
          <Text style={styles.description}>{description}</Text>
        </View>
      ) : null}
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.sorts}>
        {SORTS.map(s => {
          const selected = s.id === sort;
          return (
            <Pressable
              key={s.id}
              testID={`sort-${s.id}`}
              accessibilityRole="radio"
              accessibilityState={{ checked: selected }}
              style={[styles.sortChip, selected && styles.sortChipSelected]}
              onPress={() => setSort(s.id)}>
              <Text style={[styles.sortText, selected && styles.sortTextSelected]}>{s.label}</Text>
            </Pressable>
          );
        })}
      </ScrollView>
    </View>
  );

  let body: React.ReactNode;
  if (state.status === 'error') {
    body = <ErrorState onRetry={() => loadFirst(sort)} />;
  } else if (state.status === 'loading') {
    body = <Loading />;
  } else {
    body = null;
  }

  return (
    <View style={styles.screen}>
      <TopInset />
      <NavBar title={navTitle} />
      {body !== null ? (
        <View style={styles.flex}>
          {header}
          {body}
        </View>
      ) : (
        <FlatList
          testID="product-grid"
          style={styles.flex}
          data={state.products}
          numColumns={2}
          keyExtractor={(item, index) => `${index}-${item.id}`}
          ListHeaderComponent={header}
          columnWrapperStyle={styles.row}
          contentContainerStyle={styles.gridContent}
          renderItem={({ item, index }) => (
            <ProductCard testID={`product-card-${index}`} product={item} width={cardWidth} onPress={openProduct} />
          )}
          onEndReached={loadMore}
          onEndReachedThreshold={1}
          initialNumToRender={6}
          maxToRenderPerBatch={6}
          windowSize={5}
          ListFooterComponent={
            state.loadingMore ? (
              <View style={styles.footer}>
                <ActivityIndicator color={colors.textMuted} />
              </View>
            ) : state.moreError ? (
              <View style={styles.footer}>
                <Pressable testID="error-retry" style={styles.footerRetry} onPress={loadMore}>
                  <Text style={styles.footerRetryText}>Retry</Text>
                </Pressable>
              </View>
            ) : undefined
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  descriptionWrap: { paddingTop: 4, paddingHorizontal: 16 },
  description: { fontSize: 14, lineHeight: 20, color: colors.textMuted },
  sorts: { flexDirection: 'row', gap: 8, paddingVertical: 12, paddingHorizontal: 16 },
  sortChip: {
    height: 32,
    paddingHorizontal: 12,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.white,
    justifyContent: 'center',
  },
  sortChipSelected: { borderColor: colors.text, backgroundColor: colors.text },
  sortText: { fontSize: 13, fontWeight: '500', color: colors.text },
  sortTextSelected: { fontWeight: '600', color: colors.white },
  gridContent: { paddingBottom: 24 },
  row: { paddingHorizontal: 16, gap: 12, marginBottom: 20 },
  footer: { paddingVertical: 16, alignItems: 'center' },
  footerRetry: {
    height: 44,
    paddingHorizontal: 24,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.text,
    justifyContent: 'center',
  },
  footerRetryText: { fontSize: 16, fontWeight: '600', color: colors.text },
});

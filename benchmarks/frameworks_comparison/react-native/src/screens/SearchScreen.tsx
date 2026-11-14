import React, { useCallback, useEffect, useRef, useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { gql, isProduct, PageInfo, ProductCardData, SearchData } from '../api';
import { SEARCH } from '../graphql';
import { colors } from '../theme';
import { useNav } from '../navigation';
import { ErrorState, Loading, Price, RemoteImage, TopInset } from '../components/common';
import { SearchIcon } from '../components/Icons';

type State = {
  status: 'idle' | 'loading' | 'error' | 'ready';
  query: string;
  totalCount: number;
  products: ProductCardData[];
  pageInfo: PageInfo | null;
  loadingMore: boolean;
  moreError: boolean;
};

const idle: State = {
  status: 'idle',
  query: '',
  totalCount: 0,
  products: [],
  pageInfo: null,
  loadingMore: false,
  moreError: false,
};

export function SearchScreen() {
  const nav = useNav();
  const [text, setText] = useState('');
  const [state, setState] = useState<State>(idle);
  const currentQuery = useRef('');
  const stateRef = useRef(state);
  stateRef.current = state;

  const runSearch = useCallback((query: string) => {
    currentQuery.current = query;
    if (query === '') {
      setState(idle);
      return;
    }
    setState({ ...idle, status: 'loading', query });
    gql<SearchData>('Search', SEARCH, { query, first: 24, after: null })
      .then(data => {
        if (currentQuery.current !== query) {
          return; // stale response
        }
        setState({
          status: 'ready',
          query,
          totalCount: data.search.totalCount,
          products: data.search.nodes.filter(isProduct),
          pageInfo: data.search.pageInfo,
          loadingMore: false,
          moreError: false,
        });
      })
      .catch(() => {
        if (currentQuery.current === query) {
          setState({ ...idle, status: 'error', query });
        }
      });
  }, []);

  // Send the query 300 ms after the user stops typing.
  useEffect(() => {
    const q = text.trim();
    if (q === '') {
      runSearch('');
      return;
    }
    const t = setTimeout(() => runSearch(q), 300);
    return () => clearTimeout(t);
  }, [text, runSearch]);

  const loadMore = useCallback(() => {
    const s = stateRef.current;
    if (s.status !== 'ready' || s.loadingMore || !s.pageInfo?.hasNextPage) {
      return;
    }
    const query = s.query;
    setState(prev => ({ ...prev, loadingMore: true, moreError: false }));
    gql<SearchData>('Search', SEARCH, { query, first: 24, after: s.pageInfo.endCursor })
      .then(data => {
        if (currentQuery.current !== query) {
          return;
        }
        setState(prev => ({
          ...prev,
          totalCount: data.search.totalCount,
          products: [...prev.products, ...data.search.nodes.filter(isProduct)],
          pageInfo: data.search.pageInfo,
          loadingMore: false,
        }));
      })
      .catch(() => {
        if (currentQuery.current === query) {
          setState(prev => ({ ...prev, loadingMore: false, moreError: true }));
        }
      });
  }, []);

  const openProduct = (p: ProductCardData) => nav.push('Product', { handle: p.handle });

  let body: React.ReactNode;
  if (text.trim() === '') {
    body = <Text style={styles.hint}>Search across 995 products by name.</Text>;
  } else if (state.status === 'error') {
    body = <ErrorState onRetry={() => runSearch(state.query)} />;
  } else if (state.status === 'ready') {
    body = (
      <>
        <Text style={styles.count}>{state.totalCount} results</Text>
        <FlatList
          testID="search-results"
          style={styles.flex}
          data={state.products}
          keyExtractor={(item, index) => `${index}-${item.id}`}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode="on-drag"
          renderItem={({ item, index }) => (
            <Pressable testID={`search-result-${index}`} style={styles.row} onPress={() => openProduct(item)}>
              <RemoteImage url={item.featuredImage?.url} width={240} style={styles.thumb} />
              <View style={styles.rowText}>
                <Text style={styles.rowTitle}>{item.title}</Text>
                <Price
                  price={item.priceRange.minVariantPrice}
                  compareAt={item.compareAtPriceRange?.minVariantPrice}
                />
              </View>
            </Pressable>
          )}
          onEndReached={loadMore}
          onEndReachedThreshold={1}
          initialNumToRender={8}
          maxToRenderPerBatch={8}
          windowSize={5}
          contentContainerStyle={styles.listContent}
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
      </>
    );
  } else {
    body = <Loading />;
  }

  return (
    <View style={styles.screen}>
      <TopInset />
      <View style={styles.searchWrap}>
        <View style={styles.field}>
          <SearchIcon size={20} color={colors.textMuted} />
          {/* Uncontrolled on purpose: avoids dropped keystrokes during fast typing. */}
          <TextInput
            testID="search-input"
            style={styles.input}
            onChangeText={setText}
            placeholder="Search products"
            placeholderTextColor={colors.textMuted}
            autoCorrect={false}
            autoCapitalize="none"
            returnKeyType="search"
            accessibilityLabel="Search products"
          />
        </View>
      </View>
      {body}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  searchWrap: { paddingTop: 4, paddingHorizontal: 16, paddingBottom: 12 },
  field: {
    height: 44,
    borderRadius: 12,
    backgroundColor: colors.surface,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  input: { flex: 1, minWidth: 0, fontSize: 16, color: colors.text, padding: 0 },
  hint: {
    paddingVertical: 48,
    paddingHorizontal: 32,
    textAlign: 'center',
    color: colors.textMuted,
    fontSize: 15,
    lineHeight: 22,
  },
  count: { paddingTop: 4, paddingHorizontal: 16, paddingBottom: 8, fontSize: 13, color: colors.textMuted },
  listContent: { paddingBottom: 16 },
  row: { flexDirection: 'row', gap: 12, alignItems: 'center', paddingVertical: 8, paddingHorizontal: 16 },
  thumb: { width: 64, height: 85, borderRadius: 8 },
  rowText: { flex: 1, minWidth: 0, gap: 4 },
  rowTitle: { fontSize: 15, lineHeight: 20, color: colors.text },
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

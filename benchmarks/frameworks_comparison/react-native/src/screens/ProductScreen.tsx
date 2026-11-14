import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  FlatList,
  NativeScrollEvent,
  NativeSyntheticEvent,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { formatMoney, gql, ProductCardData, ProductData, Variant } from '../api';
import { PRODUCT } from '../graphql';
import { colors } from '../theme';
import { useNav } from '../navigation';
import { useCart } from '../cart';
import { ErrorState, Loading, Price, RemoteImage } from '../components/common';
import { BackIcon } from '../components/Icons';

type State = { status: 'loading' } | { status: 'error' } | { status: 'ready'; data: ProductData };

function initialVariant(variants: Variant[]): Variant | undefined {
  return variants.find(v => v.availableForSale) ?? variants[0];
}

export function ProductScreen({ handle }: { handle: string }) {
  const nav = useNav();
  const insets = useSafeAreaInsets();
  const [state, setState] = useState<State>({ status: 'loading' });

  const load = useCallback(() => {
    setState({ status: 'loading' });
    gql<ProductData>('Product', PRODUCT, { handle })
      .then(data => {
        if (!data.product) {
          throw new Error('Product not found');
        }
        setState({ status: 'ready', data });
      })
      .catch(() => setState({ status: 'error' }));
  }, [handle]);

  useEffect(load, [load]);

  const backButton = (
    <Pressable
      testID="back"
      accessibilityLabel="Back"
      style={[styles.back, { top: insets.top }]}
      onPress={nav.pop}>
      <BackIcon size={22} color={colors.text} />
    </Pressable>
  );

  if (state.status !== 'ready') {
    return (
      <View style={[styles.screen, { paddingTop: insets.top + 52 }]}>
        {state.status === 'error' ? <ErrorState onRetry={load} /> : <Loading />}
        {backButton}
      </View>
    );
  }

  return <ProductContent data={state.data} backButton={backButton} />;
}

function ProductContent({ data, backButton }: { data: ProductData; backButton: React.ReactNode }) {
  const product = data.product!;
  const nav = useNav();
  const cart = useCart();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const variants = product.variants.nodes;
  const [variant, setVariant] = useState<Variant | undefined>(() => initialVariant(variants));
  const [adding, setAdding] = useState(false);
  const [page, setPage] = useState(0);
  const carouselRef = useRef<FlatList<{ url: string }>>(null);

  const images = product.images.nodes.slice(0, 10);
  const imageHeight = (width * 4) / 3;

  const options = useMemo(
    () =>
      product.options.filter(
        o => !(o.name === 'Title' && o.optionValues.length === 1 && o.optionValues[0].name === 'Default Title'),
      ),
    [product.options],
  );

  const selectedValue = (name: string) => variant?.selectedOptions.find(o => o.name === name)?.value;

  const selectOption = (name: string, value: string) => {
    const wanted = new Map((variant?.selectedOptions ?? []).map(o => [o.name, o.value]));
    wanted.set(name, value);
    const match =
      variants.find(v => v.selectedOptions.every(o => wanted.get(o.name) === o.value)) ??
      variants.find(v => v.selectedOptions.some(o => o.name === name && o.value === value));
    if (match) {
      setVariant(match);
    }
  };

  const onAdd = async () => {
    if (!variant || adding) {
      return;
    }
    setAdding(true);
    const ok = await cart.addLine(variant.id);
    setAdding(false);
    if (ok) {
      nav.switchTab('cart');
    }
  };

  const onScrollEnd = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
    setPage(Math.round(e.nativeEvent.contentOffset.x / width));
  };

  const openRec = (p: ProductCardData) => nav.push('Product', { handle: p.handle });
  const recs = data.productRecommendations ?? [];
  const disabled = adding || cart.busy || !variant;

  return (
    <View style={styles.screen}>
      <ScrollView style={styles.flex} contentContainerStyle={styles.scrollContent}>
        <View style={{ width, height: imageHeight, backgroundColor: colors.surface }}>
          <FlatList
            ref={carouselRef}
            testID="product-carousel"
            data={images}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            keyExtractor={(item, i) => `${i}-${item.url}`}
            getItemLayout={(_, index) => ({ length: width, offset: width * index, index })}
            onMomentumScrollEnd={onScrollEnd}
            renderItem={({ item }) => (
              <RemoteImage url={item.url} width={1080} style={{ width, height: imageHeight }} />
            )}
          />
          {images.length > 1 ? (
            <View style={styles.dots}>
              {images.map((_, i) => (
                <Pressable
                  key={i}
                  accessibilityLabel={`Show image ${i + 1}`}
                  style={styles.dotHit}
                  onPress={() => {
                    carouselRef.current?.scrollToIndex({ index: i, animated: true });
                    setPage(i);
                  }}>
                  <View style={[styles.dot, i === page && styles.dotActive]} />
                </Pressable>
              ))}
            </View>
          ) : null}
        </View>
        <View style={styles.titleBlock}>
          <Text style={styles.title}>{product.title}</Text>
          {variant ? (
            <Price price={variant.price} compareAt={variant.compareAtPrice} size={20} compareSize={15} />
          ) : null}
        </View>
        {options.map(option => {
          const current = selectedValue(option.name);
          return (
            <View key={option.name} style={styles.option}>
              <Text style={styles.optionLabel}>
                {option.name}: <Text style={styles.optionValue}>{current ?? ''}</Text>
              </Text>
              <View style={styles.pills}>
                {option.optionValues.map(v => {
                  const selected = v.name === current;
                  return (
                    <Pressable
                      key={v.name}
                      testID={`option-${option.name}-${v.name}`}
                      accessibilityState={{ selected }}
                      style={[styles.pill, selected && styles.pillSelected]}
                      onPress={() => selectOption(option.name, v.name)}>
                      <Text style={[styles.pillText, selected && styles.pillTextSelected]}>{v.name}</Text>
                    </Pressable>
                  );
                })}
              </View>
            </View>
          );
        })}
        <View style={styles.descSection}>
          <Text style={styles.descHeading}>Description</Text>
          <Text style={styles.descText}>{product.description}</Text>
        </View>
        {recs.length > 0 ? (
          <View style={styles.recSection}>
            <Text style={styles.recHeading}>You may also like</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.recRow}>
              {recs.map((p, i) => (
                <Pressable key={`${i}-${p.id}`} testID={`recommendation-${i}`} style={styles.recCard} onPress={() => openRec(p)}>
                  <RemoteImage url={p.featuredImage?.url} width={480} style={styles.recImage} />
                  <Text style={styles.recTitle} numberOfLines={2}>
                    {p.title}
                  </Text>
                  <Price
                    price={p.priceRange.minVariantPrice}
                    compareAt={p.compareAtPriceRange?.minVariantPrice}
                    size={14}
                  />
                </Pressable>
              ))}
            </ScrollView>
          </View>
        ) : null}
      </ScrollView>
      <View style={[styles.bar, { paddingBottom: 12 + insets.bottom }]}>
        <Pressable
          testID="add-to-cart"
          disabled={disabled}
          accessibilityState={{ disabled }}
          style={[styles.addButton, disabled && styles.addButtonDisabled]}
          onPress={onAdd}>
          <Text style={styles.addText}>Add to cart · {variant ? formatMoney(variant.price) : ''}</Text>
        </Pressable>
      </View>
      {backButton}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  scrollContent: { paddingBottom: 24 },
  back: {
    position: 'absolute',
    left: 12,
    width: 40,
    height: 40,
    borderRadius: 999,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dots: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 12,
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 4,
  },
  dotHit: { width: 24, height: 24, alignItems: 'center', justifyContent: 'center' },
  dot: { width: 8, height: 8, borderRadius: 999, backgroundColor: 'rgba(28, 27, 25, 0.25)' },
  dotActive: { backgroundColor: colors.text },
  titleBlock: { paddingTop: 20, paddingHorizontal: 16, gap: 6 },
  title: { fontSize: 22, lineHeight: 28, fontWeight: '700', color: colors.text },
  option: { marginTop: 24, paddingHorizontal: 16 },
  optionLabel: { paddingBottom: 12, fontSize: 15, fontWeight: '600', color: colors.text },
  optionValue: { fontWeight: '400', color: colors.textMuted },
  pills: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  pill: {
    minWidth: 56,
    height: 44,
    paddingHorizontal: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pillSelected: { borderWidth: 2, borderColor: colors.text },
  pillText: { fontSize: 15, fontWeight: '500', color: colors.text },
  pillTextSelected: { fontWeight: '600' },
  descSection: { paddingTop: 24, paddingHorizontal: 16 },
  descHeading: { marginBottom: 8, fontSize: 15, fontWeight: '600', color: colors.text },
  descText: { fontSize: 15, lineHeight: 22, color: colors.body },
  recSection: { paddingTop: 32 },
  recHeading: {
    marginBottom: 12,
    paddingHorizontal: 16,
    fontSize: 17,
    fontWeight: '700',
    color: colors.text,
  },
  recRow: { flexDirection: 'row', gap: 12, paddingHorizontal: 16 },
  recCard: { width: 140, gap: 6 },
  recImage: { width: 140, height: 187, borderRadius: 8 },
  recTitle: { fontSize: 14, lineHeight: 18, color: colors.text },
  bar: {
    paddingTop: 12,
    paddingHorizontal: 16,
    backgroundColor: colors.background,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  addButton: {
    height: 52,
    borderRadius: 12,
    backgroundColor: colors.text,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addButtonDisabled: { opacity: 0.5 },
  addText: { color: colors.white, fontSize: 16, fontWeight: '600' },
});

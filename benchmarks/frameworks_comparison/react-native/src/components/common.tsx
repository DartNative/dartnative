import React from 'react';
import {
  ActivityIndicator,
  Image,
  ImageStyle,
  Pressable,
  StyleProp,
  StyleSheet,
  Text,
  TextStyle,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { formatMoney, imageUrl, isDiscounted, Money, ProductCardData } from '../api';
import { colors } from '../theme';
import { AlertIcon, BackIcon } from './Icons';
import { useNav } from '../navigation';

export function RemoteImage({
  url,
  width,
  style,
}: {
  url: string | null | undefined;
  width: number;
  style: StyleProp<ImageStyle>;
}) {
  const uri = imageUrl(url, width);
  return (
    <Image
      source={uri ? { uri } : undefined}
      resizeMode="cover"
      style={[styles.image, style]}
    />
  );
}

export function Price({
  price,
  compareAt,
  size = 15,
  compareSize = 13,
}: {
  price: Money;
  compareAt?: Money | null;
  size?: number;
  compareSize?: number;
}) {
  const sale = isDiscounted(price, compareAt);
  return (
    <View style={styles.priceRow}>
      <Text style={[styles.price, { fontSize: size }, sale && styles.sale]}>{formatMoney(price)}</Text>
      {sale ? (
        <Text style={[styles.compare, { fontSize: compareSize }]}>{formatMoney(compareAt)}</Text>
      ) : null}
    </View>
  );
}

export function ProductCard({
  product,
  width,
  testID,
  onPress,
}: {
  product: ProductCardData;
  width: number;
  testID: string;
  onPress: (p: ProductCardData) => void;
}) {
  return (
    <Pressable testID={testID} style={[styles.card, { width }]} onPress={() => onPress(product)}>
      <RemoteImage
        url={product.featuredImage?.url}
        width={480}
        style={{ width, height: (width * 4) / 3, borderRadius: 8 }}
      />
      <Text style={styles.cardTitle} numberOfLines={2}>
        {product.title}
      </Text>
      <Price
        price={product.priceRange.minVariantPrice}
        compareAt={product.compareAtPriceRange?.minVariantPrice}
      />
    </Pressable>
  );
}

export function ErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <View style={styles.center}>
      <AlertIcon color={colors.textMuted} />
      <Text style={styles.stateTitle}>Couldn't load products</Text>
      <Text style={styles.stateBody}>Check your connection and try again.</Text>
      <Pressable testID="error-retry" style={styles.secondaryButton} onPress={onRetry}>
        <Text style={styles.secondaryButtonText}>Retry</Text>
      </Pressable>
    </View>
  );
}

export function Loading() {
  return (
    <View style={styles.center}>
      <ActivityIndicator color={colors.textMuted} />
    </View>
  );
}

export function NavBar({ title }: { title: string }) {
  const nav = useNav();
  return (
    <View style={styles.navBar}>
      <Pressable testID="back" accessibilityLabel="Back" style={styles.navBack} onPress={nav.pop}>
        <BackIcon color={colors.text} />
      </Pressable>
      <Text style={styles.navTitle} numberOfLines={1}>
        {title}
      </Text>
      <View style={styles.navSpacer} />
    </View>
  );
}

export function TopInset() {
  const insets = useSafeAreaInsets();
  return <View style={{ height: insets.top }} />;
}

export const textStyles = StyleSheet.create({
  sectionHeading: { fontSize: 17, lineHeight: 22, fontWeight: '700', color: colors.text },
  screenTitle: { fontSize: 22, lineHeight: 28, fontWeight: '700', color: colors.text },
});

const styles = StyleSheet.create({
  image: { backgroundColor: colors.surface },
  priceRow: { flexDirection: 'row', alignItems: 'baseline', gap: 6 },
  price: { fontWeight: '700', color: colors.text },
  sale: { color: colors.sale },
  compare: { color: colors.textMuted, textDecorationLine: 'line-through' } as TextStyle,
  card: { gap: 8 },
  cardTitle: { fontSize: 14, lineHeight: 18, color: colors.text },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    paddingHorizontal: 32,
  },
  stateTitle: { fontSize: 17, fontWeight: '700', color: colors.text, textAlign: 'center' },
  stateBody: { fontSize: 15, lineHeight: 22, color: colors.textMuted, textAlign: 'center' },
  secondaryButton: {
    marginTop: 8,
    height: 48,
    paddingHorizontal: 24,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.text,
    backgroundColor: colors.white,
    justifyContent: 'center',
  },
  secondaryButtonText: { fontSize: 16, fontWeight: '600', color: colors.text },
  navBar: { height: 44, paddingHorizontal: 8, flexDirection: 'row', alignItems: 'center' },
  navBack: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  navTitle: { flex: 1, fontSize: 17, fontWeight: '600', color: colors.text, textAlign: 'center' },
  navSpacer: { width: 44 },
});

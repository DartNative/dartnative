import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors } from '../theme';
import { CartIcon, HomeIcon, SearchIcon } from './Icons';
import { TabName } from '../navigation';
import { useCart } from '../cart';

const TABS: { name: TabName; label: string; Icon: typeof HomeIcon }[] = [
  { name: 'home', label: 'Home', Icon: HomeIcon },
  { name: 'search', label: 'Search', Icon: SearchIcon },
  { name: 'cart', label: 'Cart', Icon: CartIcon },
];

export function TabBar({ active, onSelect }: { active: TabName; onSelect: (t: TabName) => void }) {
  const insets = useSafeAreaInsets();
  const { cart } = useCart();
  const count = cart?.totalQuantity ?? 0;
  return (
    <View style={[styles.bar, { height: 49 + insets.bottom, paddingBottom: insets.bottom }]}>
      {TABS.map(({ name, label, Icon }) => {
        const selected = name === active;
        const color = selected ? colors.text : colors.textMuted;
        return (
          <View key={name} style={styles.cell}>
            <Pressable
              testID={`tab-${name}`}
              accessibilityRole="button"
              accessibilityLabel={label}
              accessibilityState={{ selected }}
              style={styles.tab}
              onPress={() => onSelect(name)}>
              <Icon color={color} />
              <Text style={[styles.label, { color, fontWeight: selected ? '600' : '500' }]}>{label}</Text>
            </Pressable>
            {name === 'cart' && count > 0 ? (
              <View testID="cart-badge" accessible accessibilityLabel={String(count)} pointerEvents="none" style={styles.badge}>
                <Text style={styles.badgeText}>{count}</Text>
              </View>
            ) : null}
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    backgroundColor: colors.background,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  cell: { flex: 1 },
  tab: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 2 },
  label: { fontSize: 11 },
  badge: {
    position: 'absolute',
    top: 4,
    left: '50%',
    marginLeft: 6,
    minWidth: 18,
    height: 18,
    paddingHorizontal: 5,
    borderRadius: 999,
    backgroundColor: colors.sale,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: { color: colors.white, fontSize: 11, fontWeight: '700' },
});

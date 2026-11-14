import React from 'react';
import { Linking, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { formatMoney } from '../api';
import { useCart } from '../cart';
import { colors } from '../theme';
import { useNav } from '../navigation';
import { RemoteImage, textStyles, TopInset } from '../components/common';
import { CartIcon, MinusIcon, PlusIcon } from '../components/Icons';

export function CartScreen() {
  const nav = useNav();
  const { cart, busy, updateLine } = useCart();
  const lines = cart?.lines.nodes ?? [];

  const header = (
    <View style={styles.header}>
      <Text style={textStyles.screenTitle}>Cart</Text>
    </View>
  );

  if (!cart || lines.length === 0) {
    return (
      <View style={styles.screen}>
        <TopInset />
        {header}
        <View style={styles.empty}>
          <CartIcon size={48} strokeWidth={1.25} color={colors.textMuted} />
          <Text style={styles.emptyTitle}>Your cart is empty</Text>
          <Text style={styles.emptyBody}>Items you add will appear here.</Text>
          <Pressable style={styles.primarySmall} onPress={() => nav.switchTab('home')}>
            <Text style={styles.primaryText}>Start shopping</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.screen}>
      <TopInset />
      {header}
      <ScrollView style={styles.flex} contentContainerStyle={styles.list}>
        {lines.map((line, i) => {
          const m = line.merchandise;
          const img = m.image?.url ?? m.product.featuredImage?.url;
          return (
            <View key={line.id} testID={`cart-line-${i}`} style={styles.line}>
              <RemoteImage url={img} width={240} style={styles.thumb} />
              <View style={styles.lineInfo}>
                <Text style={styles.lineTitle}>{m.product.title}</Text>
                {m.title !== 'Default Title' ? <Text style={styles.variant}>{m.title}</Text> : null}
                <View style={styles.lineBottom}>
                  <View style={styles.stepper}>
                    <Pressable
                      testID={`qty-dec-${i}`}
                      accessibilityLabel="Decrease quantity"
                      disabled={busy}
                      style={styles.stepButton}
                      onPress={() => updateLine(line.id, line.quantity - 1)}>
                      <MinusIcon color={colors.text} />
                    </Pressable>
                    <Text style={styles.qty}>{line.quantity}</Text>
                    <Pressable
                      testID={`qty-inc-${i}`}
                      accessibilityLabel="Increase quantity"
                      disabled={busy}
                      style={styles.stepButton}
                      onPress={() => updateLine(line.id, line.quantity + 1)}>
                      <PlusIcon color={colors.text} />
                    </Pressable>
                  </View>
                  <Text style={styles.lineTotal}>{formatMoney(line.cost.totalAmount)}</Text>
                </View>
              </View>
            </View>
          );
        })}
      </ScrollView>
      <View style={styles.summary}>
        <View style={styles.subtotalRow}>
          <Text style={styles.subtotalLabel}>Subtotal</Text>
          <Text testID="cart-subtotal" style={styles.subtotal}>
            {formatMoney(cart.cost.subtotalAmount)}
          </Text>
        </View>
        <Text style={styles.note}>Taxes and shipping are calculated at checkout.</Text>
        <Pressable
          testID="checkout"
          style={styles.primary}
          onPress={() => {
            Linking.openURL(cart.checkoutUrl).catch(() => {});
          }}>
          <Text style={styles.primaryText}>Check out</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  header: { height: 44, paddingHorizontal: 16, justifyContent: 'center' },
  list: { paddingHorizontal: 16 },
  line: {
    flexDirection: 'row',
    gap: 12,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  thumb: { width: 80, height: 107, borderRadius: 8 },
  lineInfo: { flex: 1, minWidth: 0, gap: 4 },
  lineTitle: { fontSize: 15, lineHeight: 20, fontWeight: '600', color: colors.text },
  variant: { fontSize: 13, color: colors.textMuted },
  lineBottom: {
    marginTop: 'auto',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  stepper: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 12,
    height: 36,
  },
  stepButton: { width: 36, height: 34, alignItems: 'center', justifyContent: 'center' },
  qty: { minWidth: 24, textAlign: 'center', fontSize: 15, fontWeight: '600', color: colors.text },
  lineTotal: { fontSize: 15, fontWeight: '700', color: colors.text },
  summary: {
    padding: 16,
    gap: 12,
    backgroundColor: colors.background,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  subtotalRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'baseline' },
  subtotalLabel: { fontSize: 15, color: colors.text },
  subtotal: { fontSize: 17, fontWeight: '700', color: colors.text },
  note: { fontSize: 13, color: colors.textMuted },
  primary: {
    height: 52,
    borderRadius: 12,
    backgroundColor: colors.text,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primarySmall: {
    marginTop: 8,
    height: 48,
    paddingHorizontal: 24,
    borderRadius: 12,
    backgroundColor: colors.text,
    justifyContent: 'center',
  },
  primaryText: { color: colors.white, fontSize: 16, fontWeight: '600' },
  empty: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12, paddingHorizontal: 32 },
  emptyTitle: { fontSize: 17, fontWeight: '700', color: colors.text },
  emptyBody: { fontSize: 15, lineHeight: 22, color: colors.textMuted, textAlign: 'center' },
});

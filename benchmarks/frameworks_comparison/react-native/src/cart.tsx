import React, { createContext, useCallback, useContext, useMemo, useRef, useState } from 'react';
import { Alert } from 'react-native';
import { Cart, CartPayload, gql } from './api';
import { CART_CREATE, CART_LINES_ADD, CART_LINES_UPDATE } from './graphql';

type CartStore = {
  cart: Cart | null;
  busy: boolean;
  addLine: (merchandiseId: string) => Promise<boolean>;
  updateLine: (lineId: string, quantity: number) => Promise<boolean>;
};

const CartContext = createContext<CartStore | null>(null);

export function useCart(): CartStore {
  const store = useContext(CartContext);
  if (!store) {
    throw new Error('useCart outside provider');
  }
  return store;
}

// In-memory only; never persisted.
export function CartProvider({ children }: { children: React.ReactNode }) {
  const [cart, setCart] = useState<Cart | null>(null);
  const [busy, setBusy] = useState(false);
  const cartIdRef = useRef<string | null>(null);
  const busyRef = useRef(false);

  const run = useCallback(async (op: () => Promise<CartPayload>): Promise<boolean> => {
    if (busyRef.current) {
      return false;
    }
    busyRef.current = true;
    setBusy(true);
    try {
      const payload = await op();
      if (payload.cart) {
        cartIdRef.current = payload.cart.id;
        setCart(payload.cart);
      }
      if (payload.userErrors && payload.userErrors.length > 0) {
        Alert.alert(payload.userErrors[0].message);
        return false;
      }
      return payload.cart !== null;
    } catch {
      Alert.alert("Couldn't update cart", 'Check your connection and try again.');
      return false;
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  }, []);

  const addLine = useCallback(
    (merchandiseId: string) =>
      run(async () => {
        const lines = [{ merchandiseId, quantity: 1 }];
        if (cartIdRef.current === null) {
          const d = await gql<{ cartCreate: CartPayload }>('CartCreate', CART_CREATE, { lines });
          return d.cartCreate;
        }
        const d = await gql<{ cartLinesAdd: CartPayload }>('CartLinesAdd', CART_LINES_ADD, {
          cartId: cartIdRef.current,
          lines,
        });
        return d.cartLinesAdd;
      }),
    [run],
  );

  const updateLine = useCallback(
    (lineId: string, quantity: number) =>
      run(async () => {
        const d = await gql<{ cartLinesUpdate: CartPayload }>('CartLinesUpdate', CART_LINES_UPDATE, {
          cartId: cartIdRef.current,
          lines: [{ id: lineId, quantity }],
        });
        return d.cartLinesUpdate;
      }),
    [run],
  );

  const value = useMemo(() => ({ cart, busy, addLine, updateLine }), [cart, busy, addLine, updateLine]);
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

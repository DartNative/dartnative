import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { BackHandler, StyleSheet, View } from 'react-native';

// Minimal tab + stack navigator built from plain React Native views (React Native has no
// built-in navigator). Every route of every visited tab stays mounted, so switching tabs or
// popping keeps state and scroll positions; only the top route of the active tab is displayed.

export type TabName = 'home' | 'search' | 'cart';
export type RouteName = 'Home' | 'Collection' | 'Product' | 'Search' | 'Cart';
export type Route = { key: string; name: RouteName; params?: any };

type Stacks = Record<TabName, Route[]>;

type Nav = {
  push: (name: RouteName, params?: any) => void;
  pop: () => void;
  switchTab: (tab: TabName) => void;
};

const NavContext = createContext<Nav | null>(null);

export function useNav(): Nav {
  const nav = useContext(NavContext);
  if (!nav) {
    throw new Error('useNav outside navigator');
  }
  return nav;
}

let keySeq = 0;
const nextKey = () => `r${++keySeq}`;

const initialStacks: Stacks = {
  home: [{ key: 'home-root', name: 'Home' }],
  search: [{ key: 'search-root', name: 'Search' }],
  cart: [{ key: 'cart-root', name: 'Cart' }],
};

const TABS: TabName[] = ['home', 'search', 'cart'];

type Props = {
  renderRoute: (route: Route) => React.ReactNode;
  renderTabBar: (active: TabName, onSelect: (tab: TabName) => void) => React.ReactNode;
  hideTabBarFor: RouteName[];
};

export function Navigator({ renderRoute, renderTabBar, hideTabBarFor }: Props) {
  const [active, setActive] = useState<TabName>('home');
  const [stacks, setStacks] = useState<Stacks>(initialStacks);
  const [visited, setVisited] = useState<Record<TabName, boolean>>({ home: true, search: false, cart: false });
  const activeRef = useRef(active);
  activeRef.current = active;
  const stacksRef = useRef(stacks);
  stacksRef.current = stacks;

  const switchTab = useCallback((tab: TabName) => {
    setVisited(v => (v[tab] ? v : { ...v, [tab]: true }));
    setActive(tab);
  }, []);

  const nav = useMemo<Nav>(
    () => ({
      push: (name, params) => {
        const tab = activeRef.current;
        setStacks(s => ({ ...s, [tab]: [...s[tab], { key: nextKey(), name, params }] }));
      },
      pop: () => {
        const tab = activeRef.current;
        setStacks(s => (s[tab].length > 1 ? { ...s, [tab]: s[tab].slice(0, -1) } : s));
      },
      switchTab,
    }),
    [switchTab],
  );

  useEffect(() => {
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      const tab = activeRef.current;
      if (stacksRef.current[tab].length > 1) {
        nav.pop();
        return true;
      }
      if (tab !== 'home') {
        switchTab('home');
        return true;
      }
      return false;
    });
    return () => sub.remove();
  }, [nav, switchTab]);

  const activeStack = stacks[active];
  const top = activeStack[activeStack.length - 1];
  const showTabBar = !hideTabBarFor.includes(top.name);

  return (
    <NavContext.Provider value={nav}>
      <View style={styles.root}>
        <View style={styles.content}>
          {TABS.map(tab =>
            visited[tab] ? (
              <View key={tab} style={[StyleSheet.absoluteFill, tab !== active && styles.hidden]}>
                {stacks[tab].map((route, i) => (
                  <View
                    key={route.key}
                    style={[StyleSheet.absoluteFill, i !== stacks[tab].length - 1 && styles.hidden]}>
                    <RouteView route={route} render={renderRoute} />
                  </View>
                ))}
              </View>
            ) : null,
          )}
        </View>
        {showTabBar ? renderTabBar(active, switchTab) : null}
      </View>
    </NavContext.Provider>
  );
}

const RouteView = React.memo(function RouteView({
  route,
  render,
}: {
  route: Route;
  render: (route: Route) => React.ReactNode;
}) {
  return <>{render(route)}</>;
});

const styles = StyleSheet.create({
  root: { flex: 1 },
  content: { flex: 1 },
  hidden: { display: 'none' },
});

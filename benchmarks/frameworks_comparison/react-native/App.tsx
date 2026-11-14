import React, { useCallback } from 'react';
import { StatusBar, StyleSheet, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { CartProvider } from './src/cart';
import { Navigator, Route } from './src/navigation';
import { TabBar } from './src/components/TabBar';
import { HomeScreen } from './src/screens/HomeScreen';
import { CollectionScreen } from './src/screens/CollectionScreen';
import { ProductScreen } from './src/screens/ProductScreen';
import { SearchScreen } from './src/screens/SearchScreen';
import { CartScreen } from './src/screens/CartScreen';
import { colors } from './src/theme';

function renderRoute(route: Route) {
  switch (route.name) {
    case 'Home':
      return <HomeScreen />;
    case 'Collection':
      return <CollectionScreen handle={route.params.handle} title={route.params.title} />;
    case 'Product':
      return <ProductScreen handle={route.params.handle} />;
    case 'Search':
      return <SearchScreen />;
    case 'Cart':
      return <CartScreen />;
  }
}

const HIDE_TAB_BAR: Route['name'][] = ['Product'];

export default function App() {
  const renderTabBar = useCallback(
    (active: Parameters<typeof TabBar>[0]['active'], onSelect: Parameters<typeof TabBar>[0]['onSelect']) => (
      <TabBar active={active} onSelect={onSelect} />
    ),
    [],
  );
  return (
    <SafeAreaProvider>
      <StatusBar barStyle="dark-content" />
      <CartProvider>
        <View style={styles.root}>
          <Navigator renderRoute={renderRoute} renderTabBar={renderTabBar} hideTabBarFor={HIDE_TAB_BAR} />
        </View>
      </CartProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.background },
});

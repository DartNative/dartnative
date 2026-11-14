import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // Endpoint override (iOS: SHOP_API_URL launch env var; Android: build-time setting). Empty when unset.
  getApiUrl(): string;
  // Writes "SHOPBENCH home_ready" to the platform log (once per process).
  markHomeReady(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeShopBench');

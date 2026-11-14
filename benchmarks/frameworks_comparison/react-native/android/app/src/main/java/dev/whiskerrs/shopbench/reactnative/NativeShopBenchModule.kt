package dev.whiskerrs.shopbench.reactnative

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext

class NativeShopBenchModule(reactContext: ReactApplicationContext) :
    NativeShopBenchSpec(reactContext) {

  override fun getName() = NAME

  override fun getApiUrl(): String = BuildConfig.SHOP_API_URL

  override fun markHomeReady() {
    if (!homeReadyLogged) {
      homeReadyLogged = true
      Log.i("SHOPBENCH", "SHOPBENCH home_ready")
    }
  }

  companion object {
    const val NAME = "NativeShopBench"
    @Volatile private var homeReadyLogged = false
  }
}

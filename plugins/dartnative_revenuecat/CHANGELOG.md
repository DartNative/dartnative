## 1.0.2

* iOS: simulator builds work again with Xcode 26. 1.0.1's native library was
  built by a tool that left its simulator half unaligned, which Xcode 26
  refuses to link ("Slice is not page aligned"); it is built again. The code
  is unchanged.

## 1.0.1

* Android: Google Play Billing's purchase activity no longer crashes the app
  when it is started without a purchase intent. The library dereferenced the
  missing intent in its own `onCreate`, which showed in crash reports as a
  `NullPointerException` in `ProxyBillingActivity` with no app frame on the
  stack; it happens on modified Play Stores, rooted devices and test farms.
  On Android 10 and later the plugin now hands the activity a cancelled
  purchase instead: the app stays up and a purchase in flight ends with a
  store error in your callback.

## 1.0.0

* Initial release: configure, offerings, purchases, restore and customer info
  on iOS and Android through RevenueCat.

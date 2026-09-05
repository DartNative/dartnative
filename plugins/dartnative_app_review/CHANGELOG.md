## 1.0.0

* Initial release — in-app review prompt + store listing for iOS and Android
  over FFI, adapted from `in_app_review` (BSD-3-Clause).
  * `InAppReview.instance.isAvailable()` / `requestReview()` / `openStoreListing({appStoreId})`.
  * iOS: `AppStore.requestReview(in:)` (16+) / `SKStoreReviewController`.
  * Android: Play In-App Review API (`ReviewManager`).

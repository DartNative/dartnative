//! Where the app reads its data from, and the benchmark's log marker.

use std::sync::{
    OnceLock,
    atomic::{AtomicBool, Ordering},
};

/// The Storefront API mock.shop serves.
const DEFAULT_ENDPOINT: &str = "https://apparel-large-catalog.mock.shop/api";

/// The GraphQL endpoint: `SHOP_API_URL` from the environment at launch
/// (iOS), else `SHOP_API_URL` as it was when the app was built (Android),
/// else mock.shop.
pub fn endpoint() -> &'static str {
    static ENDPOINT: OnceLock<String> = OnceLock::new();
    ENDPOINT.get_or_init(|| {
        let runtime = std::env::var("SHOP_API_URL").ok();
        let built = option_env!("SHOP_API_URL").map(str::to_owned);
        runtime
            .into_iter()
            .chain(built)
            .map(|url| url.trim().to_owned())
            .find(|url| !url.is_empty())
            .unwrap_or_else(|| DEFAULT_ENDPOINT.to_owned())
    })
}

static HOME_READY_HOOK: OnceLock<fn()> = OnceLock::new();

/// Sets what writes `SHOPBENCH home_ready` to the platform's log (the iOS
/// project's `os_log`). Without one, nothing is written.
pub fn set_home_ready_hook(hook: fn()) {
    let _ = HOME_READY_HOOK.set(hook);
}

/// Home shows loaded content: writes the marker, once per process.
pub(crate) fn home_ready() {
    static WRITTEN: AtomicBool = AtomicBool::new(false);
    if !WRITTEN.swap(true, Ordering::SeqCst)
        && let Some(hook) = HOME_READY_HOOK.get()
    {
        hook();
    }
}

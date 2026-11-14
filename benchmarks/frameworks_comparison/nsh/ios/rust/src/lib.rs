//! The iOS app's Rust half: `main.m` calls [`everbloom_main`], which runs
//! the app's root on NSH's UIKit backend, full window, until the app quits.

#[cfg(target_os = "ios")]
unsafe extern "C" {
    /// `main.m`: writes `SHOPBENCH home_ready` with `os_log`.
    fn everbloom_log_home_ready();
}

/// Runs the app. Never returns.
#[cfg(target_os = "ios")]
#[unsafe(no_mangle)]
pub extern "C" fn everbloom_main() {
    use nsh_platform_ios::{AppOptions, AppSource, Root, run_app, set_ui_sets};

    everbloom::set_home_ready_hook(|| unsafe { everbloom_log_home_ready() });
    set_ui_sets(vec![nsh_base::registry(), everbloom::registry()]);
    run_app(
        AppSource::Rust(Root::of::<everbloom::App>().app_id("dev.whiskerrs.shopbench.nsh")),
        AppOptions::default(),
    )
}

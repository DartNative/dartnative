//! Development only: `cargo run` shows the app in a phone-sized macOS
//! window. The shipped apps are the iOS project in `ios/` and the Android
//! package `nsh package --target android` builds.

#[cfg(target_os = "macos")]
fn main() -> impl std::process::Termination {
    use nsh_platform_macos as platform;
    platform::run_app(
        platform::AppSource::Rust(platform::Root::of::<everbloom::App>()),
        platform::AppOptions {
            title: "Everbloom".to_owned(),
            size: (390, 844),
            ..Default::default()
        },
    )
}

#[cfg(not(target_os = "macos"))]
fn main() {}

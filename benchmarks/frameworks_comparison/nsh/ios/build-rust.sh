#!/bin/sh
# Xcode's "Build Rust" phase: builds the app's Rust half (ios/rust) as a
# static library for the SDK being built, in release mode, into
# ios/rust/target/<rust target>/release/libeverbloom_ios.a.
set -eu

case "${PLATFORM_NAME:-iphonesimulator}" in
  iphoneos) TARGET=aarch64-apple-ios ;;
  iphonesimulator) TARGET=aarch64-apple-ios-sim ;;
  *) echo "error: unsupported platform ${PLATFORM_NAME}" >&2; exit 1 ;;
esac

HERE="$(cd "$(dirname "$0")" && pwd)"
CARGO_BIN="${CARGO_HOME:-$HOME/.cargo}/bin"

# A clean environment: Xcode's SDKROOT and friends would point the host
# build scripts at the iOS SDK.
exec env -i \
  HOME="$HOME" \
  PATH="$CARGO_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  ${RUSTUP_HOME:+RUSTUP_HOME="$RUSTUP_HOME"} \
  ${CARGO_HOME:+CARGO_HOME="$CARGO_HOME"} \
  IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-15.0}" \
  cargo build --release --locked \
    --manifest-path "$HERE/rust/Cargo.toml" \
    --target "$TARGET"

#!/bin/sh
# Builds the Android release APK: `nsh package --target android` (release
# runtime, the app's Rust root in libnsh.so), then links the APK again with
# android/AndroidManifest.xml (cleartext HTTP, portrait), aligns it and signs
# it with the debug key. Writes build/android/Everbloom.apk.
#
# SHOP_API_URL, when set, is compiled in as the API endpoint.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
BT="$(ls -d "$SDK"/build-tools/* | sort -V | tail -1)"
JAR="$SDK/platforms/android-35/android.jar"
OUT="$ROOT/build/android"
WORK="$OUT/work"

cd "$ROOT"
nsh package --target android --out "$OUT/nsh"

rm -rf "$WORK" && mkdir -p "$WORK/files"
"$BT/aapt2" link -o "$WORK/base.apk" -I "$JAR" \
  --manifest "$ROOT/android/AndroidManifest.xml" \
  --min-sdk-version 28 --target-sdk-version 35 \
  --version-code 1 --version-name 1.0.0

# Code, native libraries (stored, page aligned) and assets from nsh's APK.
(cd "$WORK/files" && unzip -q "$OUT/nsh/Everbloom.apk" 'classes.dex' 'lib/*' 'assets/*')
cp "$WORK/base.apk" "$WORK/unaligned.apk"
(cd "$WORK/files" && zip -q -X "$WORK/unaligned.apk" classes.dex && zip -q -X -r "$WORK/unaligned.apk" assets && zip -q -X -0 -r "$WORK/unaligned.apk" lib)
"$BT/zipalign" -P 16 -f 4 "$WORK/unaligned.apk" "$WORK/aligned.apk"

KEYSTORE="$HOME/.android/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
  mkdir -p "$HOME/.android"
  keytool -genkeypair -keystore "$KEYSTORE" -storepass android -keypass android \
    -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA -keysize 2048 -validity 10000
fi
"$BT/apksigner" sign --ks "$KEYSTORE" --ks-pass pass:android --key-pass pass:android \
  --ks-key-alias androiddebugkey --out "$OUT/Everbloom.apk" "$WORK/aligned.apk"
rm -rf "$WORK"
echo "built $OUT/Everbloom.apk"

#!/bin/bash
# Builds Legend List's own example app at a pinned commit, with the
# benchmark's advanced-mode screens added to it, as one app per screen and
# list.
#
# The React Native side of this benchmark is Legend List's example app as
# its authors wrote it: nothing of theirs is copied into this repository and
# nothing in their code is edited. The script clones their repository at the
# commit below, installs the exact dependency versions from their lockfiles,
# adds the files under advanced/ and builds the app in release mode. Those
# files are routes beside theirs: one per screen the benchmark opens, which
# shows the example's own screen under a bar title naming the list
# ("Cards (RN - Legend List)"); three for the Cards screen in the
# benchmark's advanced mode; and three for the Chat screen, the example's
# chat with Lottie stickers in it. For the stickers the script adds one
# package to the example's dependencies, lottie-react-native, and the
# sticker files to its assets. On iOS the harness's auto-scroll driver
# (../harness/ios/autoscroll) goes into the generated Podfile, as it goes
# into the other apps.
#
# Each build is one app that opens straight on one screen and one list, as
# the DartNative and platform apps do, with its own id and a name that says
# both, so all of them can sit on one phone:
#
#   ./setup.sh android|ios <screen> <list>
#
#   cards    legend | flashlist | flatlist         CardsList (RN - Legend) ...
#   chat     legend | flashlist | flatlist         ChatList (RN - FlashList) ...
#
# Android writes a release APK (arm64-v8a); iOS builds in release for a
# connected iPhone and installs it there, or, with IOS_BUILD_ONLY=1 and
# DEVELOPMENT_TEAM=<your Apple team id>, only builds it and prints where the
# app is.
#
# Needs: git, Node.js (bun runs through npx), a JDK 17 and the Android SDK
# for Android, Xcode and CocoaPods for iOS.
set -euo pipefail

LEGEND_COMMIT=3d80d167e243cbaa089fda9f2dbcca5ea59da9d8 # Legend List 3.6.0
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK=${WORK:-"$HERE/.work"}
USAGE="usage: ./setup.sh android|ios <cards|chat> <legend|flashlist|flatlist>"
PLATFORM=${1:?$USAGE}; SCREEN=${2:?$USAGE}; LIST=${3:?$USAGE}

# The route each app opens on, and its name.
case "$SCREEN:$LIST" in
  cards:legend) ROUTE=cards-advanced ;;
  cards:flashlist|cards:flatlist) ROUTE=cards-advanced-$LIST ;;
  chat:legend) ROUTE=chat-stickers ;;
  chat:flashlist|chat:flatlist) ROUTE=chat-stickers-$LIST ;;
  *) echo "$USAGE"; exit 1 ;;
esac
case "$LIST" in
  legend) LIST_NAME="Legend" ;;
  flashlist) LIST_NAME="FlashList" ;;
  flatlist) LIST_NAME="FlatList" ;;
esac
SCREEN_NAME="$(echo "${SCREEN:0:1}" | tr '[:lower:]' '[:upper:]')${SCREEN:1}"
APP_NAME="${SCREEN_NAME}List (RN - $LIST_NAME)"
APP_ID="com.legendapp.listtest.$SCREEN.${LIST//-/}"

mkdir -p "$WORK"
if [ ! -d "$WORK/legend-list" ]; then
  git clone https://github.com/LegendApp/legend-list.git "$WORK/legend-list"
fi
cd "$WORK/legend-list"
git fetch --quiet origin "$LEGEND_COMMIT" 2>/dev/null || true
git checkout --quiet "$LEGEND_COMMIT"
# The one change this script makes to their files, the Lottie package in the
# example's dependencies, is undone first, so it is made again from scratch.
git checkout --quiet -- example/package.json example/bun.lock
git diff --quiet || { echo "their checkout has local changes; refusing to build"; exit 1; }

# The benchmark's own files, beside theirs: a static route in app/ takes
# precedence over their [slug] route, so no file of theirs changes.
ADVANCED="$HERE/advanced"
cp "$ADVANCED"/components/*.ts* example/components/
cp "$ADVANCED"/app/*.tsx example/app/
echo "export const START_ROUTE = \"$ROUTE\";" > example/components/BenchStart.ts
mkdir -p example/assets/stickers
cp "$HERE"/../assets/stickers/*.json example/assets/stickers/

# Their lockfiles pin every version: React Native 0.81.5 (New Architecture),
# Expo 54, FlashList 2.3.2, Reanimated 4.3.0.
npx -y bun@1 install --frozen-lockfile
(cd example && npx -y bun@1 install --frozen-lockfile)
# The Chat screen's stickers: lottie-react-native, the newest release in the
# range Expo 54 lists for it (~7.3.1).
(cd example && npx -y bun@1 add lottie-react-native@7.3.8)

# The app's name and id are set in the native project prebuild generates,
# over whatever id an earlier build left there; their app.json is left as
# it is.
cd example
case "$PLATFORM" in
  android)
    CI=1 npx expo prebuild --platform android --no-install
    perl -pi -e "s|<string name=\"app_name\">[^<]*</string>|<string name=\"app_name\">$APP_NAME</string>|" \
      android/app/src/main/res/values/strings.xml
    perl -pi -e "s|applicationId 'com\.legendapp\.listtest[a-z.]*'|applicationId '$APP_ID'|" android/app/build.gradle
    grep -q "applicationId '$APP_ID'" android/app/build.gradle || { echo "could not set the app id"; exit 1; }
    (cd android && ./gradlew assembleRelease -PreactNativeArchitectures=arm64-v8a)
    echo "APK ($APP_NAME, $APP_ID): $PWD/android/app/build/outputs/apk/release/app-release.apk"
    ;;
  ios)
    CI=1 npx expo prebuild --platform ios
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" ios/listtest/Info.plist
    perl -pi -e "s|PRODUCT_BUNDLE_IDENTIFIER = \"?com\.legendapp\.listtest[a-z.]*\"?;|PRODUCT_BUNDLE_IDENTIFIER = $APP_ID;|" \
      ios/listtest.xcodeproj/project.pbxproj
    grep -q "PRODUCT_BUNDLE_IDENTIFIER = $APP_ID;" ios/listtest.xcodeproj/project.pbxproj || { echo "could not set the app id"; exit 1; }
    # The auto-scroll driver the harness launches the app with
    # (../harness/README.md), added as a pod to the generated Podfile; it
    # stays idle in every other launch.
    perl -pi -e "s|^(target 'listtest' do)\$|\$1\n  pod 'BenchAutoScroll', :path => '$HERE/../harness/ios/autoscroll'|" ios/Podfile
    grep -q "BenchAutoScroll" ios/Podfile || { echo "could not add the auto-scroll pod"; exit 1; }
    (cd ios && pod install)
    if [ -n "${IOS_BUILD_ONLY:-}" ]; then
      : "${DEVELOPMENT_TEAM:?IOS_BUILD_ONLY=1 needs DEVELOPMENT_TEAM, your Apple team id}"
      (cd ios && xcodebuild -workspace listtest.xcworkspace -scheme listtest -configuration Release \
        -destination generic/platform=iOS -derivedDataPath DerivedData -allowProvisioningUpdates \
        DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic build)
      echo "App ($APP_NAME, $APP_ID): $PWD/ios/DerivedData/Build/Products/Release-iphoneos/listtest.app"
    else
      npx expo run:ios --configuration Release --device
    fi
    ;;
  *) echo "$USAGE"; exit 1 ;;
esac

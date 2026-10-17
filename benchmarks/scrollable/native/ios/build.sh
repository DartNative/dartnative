#!/bin/bash
# Builds the UIKit app in release and installs it on a connected iPhone.
#
#   DEVELOPMENT_TEAM=<team id> ./build.sh <device-udid> [cards|chat|empty]
set -euo pipefail
UDID=${1:?device udid}; SCREEN=${2:-cards}
: "${DEVELOPMENT_TEAM:?set DEVELOPMENT_TEAM to your Apple team id}"
cd "$(dirname "$0")"
xcodegen generate --quiet
# Each screen is its own app ("ChatList (Swift)"), picked by BENCH_SCREEN.
BENCH_SCREEN=$SCREEN
xcodebuild -project Cards.xcodeproj -scheme Cards -configuration Release \
  -destination "id=$UDID" -allowProvisioningUpdates -derivedDataPath build \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" BENCH_SCREEN="$BENCH_SCREEN" build | grep -E "error:|BUILD"
xcrun devicectl device install app --device "$UDID" build/Build/Products/Release-iphoneos/Cards.app

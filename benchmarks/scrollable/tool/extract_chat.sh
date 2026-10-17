#!/bin/bash
# Writes assets/chat.json for the DartNative, Kotlin and UIKit apps: the
# messages of the Chat screen, made by Legend List's own generator
# (buildChatMessages in examples-shared/chat.ts, by Legend List's authors,
# MIT licence) in the checkout that react_native/setup.sh makes, so every
# app shows the same thread the React Native app builds at run time. The
# number of messages is the React Native screen's MESSAGE_COUNT.
#
# Usage:
#   tool/extract_chat.sh [react_native/.work/legend-list]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CHECKOUT="$(cd "${1:-$HERE/../react_native/.work/legend-list}" && pwd)"
COUNT=$(sed -nE 's/^export const MESSAGE_COUNT = ([0-9]+);/\1/p' "$HERE/../react_native/advanced/components/ChatStickers.tsx")
cd "$CHECKOUT"
npx -y bun@1 -e "import { buildChatMessages } from './examples-shared/chat.ts';
console.log(JSON.stringify(buildChatMessages($COUNT)));" > "$HERE/../assets/chat.json"
echo "$COUNT messages: $(wc -c < "$HERE/../assets/chat.json") bytes"

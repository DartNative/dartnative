#!/usr/bin/env bash
#
# Fetch the SuperTonic-3 model files to BUNDLE into the example app, so the
# first-launch download is only the ~78 MB vector_estimator instead of ~144 MB.
#
# Downloads everything EXCEPT vector_estimator.onnx into assets/supertonic/.
# These files are git-ignored (see assets/supertonic/.gitignore) — re-run after
# a clean checkout. After running, `dn run` (or flutter build) bundles them and
# the in-app download drops to just the vector_estimator.
#
# Usage:  cd example && ./scripts/fetch_bundled_models.sh
#
set -euo pipefail

DST="$(cd "$(dirname "$0")/.." && pwd)/assets/supertonic"
SHERPA="https://huggingface.co/csukuangfj2/sherpa-onnx-supertonic-3-tts-int8-2026-05-11/resolve/main"
OFFICIAL="https://huggingface.co/Supertone/supertonic-3/resolve/main"

mkdir -p "$DST/voice_styles"

get() { # url  dest
  echo "↓ $(basename "$2")"
  curl -fSL --retry 3 "$1" -o "$2"
}

# 3 of the 4 ONNX models (the VE is intentionally left to download at runtime),
# saved under canonical names (no .int8 suffix) to match ModelManager.
get "$SHERPA/duration_predictor.int8.onnx" "$DST/duration_predictor.onnx"
get "$SHERPA/text_encoder.int8.onnx"       "$DST/text_encoder.onnx"
get "$SHERPA/vocoder.int8.onnx"            "$DST/vocoder.onnx"

# JSON sidecars (quantization-independent — from the official repo).
get "$OFFICIAL/onnx/tts.json"             "$DST/tts.json"
get "$OFFICIAL/onnx/unicode_indexer.json" "$DST/unicode_indexer.json"
for v in F1 F2 F3 F4 F5 M1 M2 M3 M4 M5; do
  get "$OFFICIAL/voice_styles/$v.json" "$DST/voice_styles/$v.json"
done

echo
echo "✓ Bundled $(du -sh "$DST" | cut -f1) into assets/supertonic/."
echo "  vector_estimator (~78 MB) is NOT bundled — it downloads on first launch."
echo "  Rebuild the app (dn run) to pick up the bundled files."

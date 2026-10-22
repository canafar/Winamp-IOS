#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! xcrun --find xcodebuild >/dev/null 2>&1; then
  echo "Xcode ve iOS Simulator SDK gereklidir. Xcode'u açıp ilk kurulumu tamamlayın." >&2
  exit 1
fi
mkdir -p build
xcodebuild -project WinampClassic.xcodeproj \
  -scheme WinampClassic -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO build 2>&1 | tee build/simulator-build.log

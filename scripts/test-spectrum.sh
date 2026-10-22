#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
(
  xcrun swiftc -swift-version 5 \
    WinampClassic/EqualizerSettings.swift WinampClassic/PlaybackPresentation.swift \
    WinampClassic/SpectrumAnalyzer.swift tests/SpectrumTests.swift \
    -o build/spectrum-tests
  build/spectrum-tests
) 2>&1 | tee build/spectrum-test.log

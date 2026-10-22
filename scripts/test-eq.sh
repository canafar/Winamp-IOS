#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
(
xcrun swiftc -swift-version 5 \
  WinampClassic/EqualizerSettings.swift WinampClassic/EqualizerDSP.swift \
  WinampClassic/SpectrumAnalyzer.swift WinampClassic/EnginePlayer.swift tests/EQOfflineTests.swift \
  -o build/eq-offline-tests
build/eq-offline-tests
) 2>&1 | tee build/eq-test.log

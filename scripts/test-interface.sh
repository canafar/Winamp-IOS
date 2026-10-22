#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
(
  xcrun swiftc -swift-version 5 \
    WinampClassic/EqualizerSettings.swift WinampClassic/PlayerLayout.swift \
    tests/InterfaceLogicTests.swift -o build/interface-tests
  build/interface-tests
) 2>&1 | tee build/interface-test.log

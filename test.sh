#!/bin/bash
set -euo pipefail

TEST_BIN="/tmp/QuickPadTestsRunner"
echo "▸ Compiling QuickPad test suite…"

# Collect all sources except application entry point (main.swift)
SOURCES=$(find Sources/QuickPad -name "*.swift" ! -name "main.swift")
TEST_SOURCES=$(find Tests/QuickPadTests -name "main.swift")

swiftc -g -Onone -target arm64-apple-macos13.0 -sdk $(xcrun --show-sdk-path) \
    -framework AppKit -framework WebKit \
    ${SOURCES} ${TEST_SOURCES} -o "${TEST_BIN}"

echo "▸ Executing test suite…"
"${TEST_BIN}"

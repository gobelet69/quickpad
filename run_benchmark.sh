#!/usr/bin/env bash
set -euo pipefail

STAGE="/tmp/QuickPadBenchStage"
rm -rf "$STAGE"
mkdir -p "$STAGE"

cp -R Sources "$STAGE/"
cp benchmark.swift "$STAGE/"

cd "$STAGE"
SWIFT_FILES=$(find Sources/QuickPad -name "*.swift" ! -name "main.swift")

echo "==> Compiling QuickPad benchmark in /tmp..."
swiftc -O -target arm64-apple-macos13.0 \
       -sdk $(xcrun --show-sdk-path) \
       -framework AppKit \
       -framework WebKit \
       $SWIFT_FILES benchmark.swift \
       -o /tmp/QuickPadBench

echo "==> Running QuickPad benchmark..."
/tmp/QuickPadBench

#!/bin/bash
set -euo pipefail

APP="QuickPad"
BUNDLE="${APP}.app"
BUILD_CONFIG="${1:-release}"
UNIVERSAL="${UNIVERSAL:-0}"
OUTPUT_BIN="/tmp/${APP}Bin"

echo "▸ Staging source files in /tmp to prevent iCloud coordination locks…"
BUILD_STAGE="/tmp/QuickPadBuildStage"
rm -rf "${BUILD_STAGE}"
mkdir -p "${BUILD_STAGE}"
cp -R Sources "${BUILD_STAGE}/"

echo "▸ Compiling ${APP} (${BUILD_CONFIG}, Universal=${UNIVERSAL})…"
cd "${BUILD_STAGE}"
SWIFT_FILES=$(find Sources/QuickPad -name "*.swift")

SDK_PATH=$(xcrun --show-sdk-path)

if [ "$UNIVERSAL" = "1" ]; then
    echo "  • Compiling Apple Silicon (arm64)..."
    swiftc -O -target arm64-apple-macos13.0 -sdk "${SDK_PATH}" -framework AppKit -framework WebKit ${SWIFT_FILES} -o "${OUTPUT_BIN}_arm64"
    echo "  • Compiling Intel (x86_64)..."
    swiftc -O -target x86_64-apple-macos13.0 -sdk "${SDK_PATH}" -framework AppKit -framework WebKit ${SWIFT_FILES} -o "${OUTPUT_BIN}_x86_64"
    echo "  • Merging Universal 2 binary with lipo..."
    lipo -create "${OUTPUT_BIN}_arm64" "${OUTPUT_BIN}_x86_64" -output "${OUTPUT_BIN}"
    file "${OUTPUT_BIN}"
elif [ "$BUILD_CONFIG" = "release" ]; then
    swiftc -O -target arm64-apple-macos13.0 -sdk "${SDK_PATH}" -framework AppKit -framework WebKit ${SWIFT_FILES} -o "${OUTPUT_BIN}"
else
    swiftc -g -Onone -target arm64-apple-macos13.0 -sdk "${SDK_PATH}" -framework AppKit -framework WebKit ${SWIFT_FILES} -o "${OUTPUT_BIN}"
fi

cd - >/dev/null
rm -rf "${BUILD_STAGE}"

echo "▸ Packaging ${BUNDLE}…"
rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp "${OUTPUT_BIN}" "${BUNDLE}/Contents/MacOS/${APP}"
chmod +x "${BUNDLE}/Contents/MacOS/${APP}"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${BUNDLE}/Contents/Resources/AppIcon.icns"
fi

cat > "${BUNDLE}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>QuickPad</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>org.111iridescence.quickpad</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>QuickPad</string>
    <key>CFBundleDisplayName</key>
    <string>QuickPad</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Plain Text</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.text</string>
                <string>public.plain-text</string>
                <string>public.data</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "▸ Stripping extended attributes and signing ${BUNDLE}…"
xattr -cr "${BUNDLE}"
codesign --force --deep --sign - "${BUNDLE}"
codesign --verify --deep --strict --verbose=1 "${BUNDLE}"

echo "✓ Successfully built and signed ${BUNDLE}!"

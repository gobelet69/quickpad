#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Packaging QuickPad for macOS (.dmg) "
echo " 111iridescence Atelier "
echo "============================================================"

APP_NAME="QuickPad"
BUNDLE_ID="org.111iridescence.quickpad"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
SRC_APP="${APP_NAME}.app"
STAGING_DIR="/tmp/QuickPad_DMG_Staging"

if [ ! -d "${SRC_APP}" ]; then
    echo "Error: ${SRC_APP} not found. Running build.sh first..."
    ./build.sh
fi

echo "==> Preparing DMG staging directory..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

echo "==> Copying ${SRC_APP} to staging..."
cp -R "${SRC_APP}" "${STAGING_DIR}/"

echo "==> Sanitizing extended attributes and code signing in staging..."
xattr -cr "${STAGING_DIR}/${SRC_APP}"
codesign --force --deep --sign - "${STAGING_DIR}/${SRC_APP}"
codesign --verify --deep --strict --verbose=2 "${STAGING_DIR}/${SRC_APP}"

echo "==> Creating /Applications symlink..."
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Building read-only compressed DMG: ${DMG_NAME}..."
rm -f "${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${STAGING_DIR}" \
               -ov \
               -format UDZO \
               "${DMG_NAME}"

rm -rf "${STAGING_DIR}"

DMG_SIZE=$(du -h "${DMG_NAME}" | awk '{print $1}')
echo ""
echo "============================================================"
echo " Successfully packaged: ${DMG_NAME} (${DMG_SIZE})"
echo " SHA-256: $(shasum -a 256 "${DMG_NAME}" | awk '{print $1}')"
echo "============================================================"

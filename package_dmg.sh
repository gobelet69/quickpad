#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

APP_NAME="QuickPad"
BUNDLE_ID="org.111iridescence.quickpad"
VERSION="1.0.1"
UNIVERSAL="${UNIVERSAL:-0}"

if [ "$UNIVERSAL" = "1" ]; then
    DMG_NAME="${APP_NAME}-${VERSION}-universal.dmg"
else
    DMG_NAME="${APP_NAME}-${VERSION}-arm64.dmg"
fi

SRC_APP="${APP_NAME}.app"
STAGING_DIR="/tmp/QuickPad_DMG_Staging"
DIST_DIR="${SCRIPT_DIR}/dist"

echo "============================================================"
echo " Packaging QuickPad for macOS (${DMG_NAME}) "
echo " 111iridescence Atelier "
echo "============================================================"

UNIVERSAL="${UNIVERSAL}" ./build.sh release

echo "==> Preparing DMG staging directory..."
rm -rf "${STAGING_DIR}" "${DIST_DIR}"
mkdir -p "${STAGING_DIR}" "${DIST_DIR}"

echo "==> Copying ${SRC_APP} to staging..."
cp -R "${SRC_APP}" "${STAGING_DIR}/"

echo "==> Sanitizing extended attributes and code signing in staging..."
xattr -cr "${STAGING_DIR}/${SRC_APP}"
codesign --force --deep --sign - "${STAGING_DIR}/${SRC_APP}"
codesign --verify --deep --strict --verbose=2 "${STAGING_DIR}/${SRC_APP}"

echo "==> Creating /Applications symlink..."
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Building read-only compressed DMG: ${DIST_DIR}/${DMG_NAME}..."
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${STAGING_DIR}" \
               -ov \
               -format UDZO \
               "${DIST_DIR}/${DMG_NAME}"

rm -rf "${STAGING_DIR}"

(cd "${DIST_DIR}" && shasum -a 256 "${DMG_NAME}" > SHA256SUMS.txt && cat SHA256SUMS.txt)

echo "============================================================"
echo " ✓ Successfully packaged: ${DIST_DIR}/${DMG_NAME}"
echo "============================================================"

#!/usr/bin/env bash
#
# Builds NoStart as a native macOS .app bundle using only Swift CLI
# (no Xcode required). Output: ./build/NoStart.app
#
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="NoStart"
BUILD_DIR="build"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_PATH}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RES_DIR="${CONTENTS}/Resources"

# Detect arch: build a universal binary if possible, otherwise native.
ARCH="$(uname -m)"

echo "==> [1/5] Compiling Swift sources (release, ${ARCH})"
swift build -c release --arch "${ARCH}"

BIN_PATH="$(swift build -c release --arch "${ARCH}" --show-bin-path)"
if [ ! -x "${BIN_PATH}/${APP_NAME}" ]; then
    echo "ERROR: Compiled binary not found at ${BIN_PATH}/${APP_NAME}" >&2
    exit 1
fi

echo "==> [2/5] Creating .app bundle at ${APP_PATH}"
rm -rf "${APP_PATH}"
mkdir -p "${MACOS_DIR}" "${RES_DIR}"

cp "${BIN_PATH}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "==> [3/5] Writing Info.plist"
cp "AppBundle/Info.plist" "${CONTENTS}/Info.plist"

# --- App icon ----------------------------------------------------------------
# Priority:
#   1. AppBundle/AppIcon.icns (pre-built) — used as-is.
#   2. AppBundle/AppIcon.png  (any size, ideally 1024x1024) — auto-converted.
ICON_PNG="AppBundle/AppIcon.png"
ICON_ICNS="AppBundle/AppIcon.icns"
GENERATED_ICNS=""

if [ -f "${ICON_PNG}" ]; then
    echo "    Generating AppIcon.icns from ${ICON_PNG}"
    ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "${ICONSET_DIR}"
    # Apple-recommended sizes for an iconset
    for spec in \
        "16:icon_16x16.png" \
        "32:icon_16x16@2x.png" \
        "32:icon_32x32.png" \
        "64:icon_32x32@2x.png" \
        "128:icon_128x128.png" \
        "256:icon_128x128@2x.png" \
        "256:icon_256x256.png" \
        "512:icon_256x256@2x.png" \
        "512:icon_512x512.png" \
        "1024:icon_512x512@2x.png"
    do
        size="${spec%%:*}"
        name="${spec##*:}"
        sips -z "${size}" "${size}" "${ICON_PNG}" --out "${ICONSET_DIR}/${name}" >/dev/null
    done
    GENERATED_ICNS="${BUILD_DIR}/AppIcon.icns"
    iconutil -c icns "${ICONSET_DIR}" -o "${GENERATED_ICNS}"
    cp "${GENERATED_ICNS}" "${RES_DIR}/AppIcon.icns"
    rm -rf "$(dirname "${ICONSET_DIR}")"
elif [ -f "${ICON_ICNS}" ]; then
    cp "${ICON_ICNS}" "${RES_DIR}/AppIcon.icns"
fi

if [ -f "${RES_DIR}/AppIcon.icns" ]; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "${CONTENTS}/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "${CONTENTS}/Info.plist"
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "${CONTENTS}/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon" "${CONTENTS}/Info.plist"
fi
# -----------------------------------------------------------------------------

echo "==> [4/5] Ad-hoc code signing"
codesign --force --deep --options runtime --sign - "${APP_PATH}"

echo "==> [5/5] Done."
echo ""
echo "Built:    $(pwd)/${APP_PATH}"
echo "Run:      open ${APP_PATH}"
echo "Install:  ./install.sh     (copies to /Applications and launches)"

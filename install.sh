#!/usr/bin/env bash
#
# Installs NoStart.app into /Applications and starts it.
# Run build.sh first if the app isn't built yet.
#
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="NoStart"
SRC="build/${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

if [ ! -d "$SRC" ]; then
    echo "App not built yet. Running ./build.sh ..."
    ./build.sh
fi

# Quit any running instance so we can replace it.
if pgrep -x "${APP_NAME}" >/dev/null 2>&1; then
    echo "==> Quitting running ${APP_NAME} ..."
    osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || true
    sleep 1
    pkill -x "${APP_NAME}" 2>/dev/null || true
fi

echo "==> Installing to ${DEST}"
rm -rf "${DEST}"
cp -R "${SRC}" "${DEST}"

# Remove any quarantine attributes that macOS may have added.
xattr -dr com.apple.quarantine "${DEST}" 2>/dev/null || true

# Nudge macOS to refresh the cached icon.
touch "${DEST}"
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
    -f "${DEST}" >/dev/null 2>&1 || true

echo "==> Launching NoStart"
open "${DEST}"

echo ""
echo "Installed at: ${DEST}"
echo "Look for the NoStart icon in your menu bar (top right)."
echo "Click it, then choose 'Settings…' to manage your blocklist."

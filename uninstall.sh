#!/usr/bin/env bash
#
# Removes NoStart from the system:
#   - quits running instance
#   - unregisters launch-at-login item
#   - deletes /Applications/NoStart.app
#   - deletes saved blocklist and preferences
#
set -euo pipefail

APP_NAME="NoStart"
BUNDLE_ID="dev.nostart.NoStart"
APP_PATH="/Applications/${APP_NAME}.app"
SUPPORT_DIR="${HOME}/Library/Application Support/NoStart"

echo "==> Quitting ${APP_NAME}"
osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || true
pkill -x "${APP_NAME}" 2>/dev/null || true

echo "==> Removing launch-at-login registration"
# Best-effort; ignores errors if not registered.
/bin/launchctl bootout "gui/$(id -u)/${BUNDLE_ID}" 2>/dev/null || true

echo "==> Deleting ${APP_PATH}"
rm -rf "${APP_PATH}"

echo "==> Deleting saved preferences and blocklist"
defaults delete "${BUNDLE_ID}" 2>/dev/null || true
rm -rf "${SUPPORT_DIR}"

echo "Done. NoStart has been removed from this Mac."

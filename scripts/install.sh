#!/bin/zsh
set -euo pipefail

APP_NAME="Login Link Fixer"
BUILD_DIR="build/Release"
APP_PATH="/Applications/${APP_NAME}.app"
BUILT_APP_PATH="${BUILD_DIR}/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
xcodebuild -project LoginLinkFixer.xcodeproj \
    -scheme LoginLinkFixer \
    -configuration Release \
    CONFIGURATION_BUILD_DIR="$(pwd)/${BUILD_DIR}" \
    clean build -quiet

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    pkill -x "$APP_NAME"
fi

echo "Installing to /Applications..."
ditto "$BUILT_APP_PATH" "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH"
open "$APP_PATH"

echo "Installed and launched ${APP_NAME}."

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

BUNDLE_ID="$(defaults read "$(pwd)/${BUILT_APP_PATH}/Contents/Info" CFBundleIdentifier)"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

# macOS launches whichever copy Launch Services prefers, so a stale install
# elsewhere silently shadows the new one. Keep exactly one installed copy.
for dir in /Applications "$HOME/Applications"; do
    [[ -d "$dir" ]] || continue
    mdfind -onlyin "$dir" "kMDItemCFBundleIdentifier == '${BUNDLE_ID}'" | while IFS= read -r stale; do
        [[ "$stale" == "$APP_PATH" ]] && continue
        echo "Moving duplicate install to Trash: ${stale}"
        "$LSREGISTER" -u "$stale" 2>/dev/null || true
        # Finder handles admin auth for root-owned folders and keeps "Put Back".
        osascript -e 'on run argv' -e 'tell application "Finder" to delete (POSIX file (item 1 of argv) as alias)' -e 'end run' "$stale" >/dev/null
    done
done

echo "Installing to /Applications..."
ditto "$BUILT_APP_PATH" "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH"
"$LSREGISTER" -f "$APP_PATH"
echo "Installed $(defaults read "${APP_PATH}/Contents/Info" CFBundleShortVersionString) ($(defaults read "${APP_PATH}/Contents/Info" CFBundleVersion)) at ${APP_PATH}"
open "$APP_PATH"

echo "Installed and launched ${APP_NAME}."

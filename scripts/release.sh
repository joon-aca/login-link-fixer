#!/bin/zsh
set -euo pipefail

cd "${0:A:h}/.."

app_name="Login Link Fixer"
app_path="${PWD}/build/Release/${app_name}.app"
staging_dir="${PWD}/build/dmg-staging"
dist_dir="${PWD}/dist"
notary_profile="${NOTARY_PROFILE:-aca-notary}"
sign_identity="${SIGN_IDENTITY:-Developer ID Application: Africa Code Academy Inc. (99Q9DDS92L)}"
team_id="99Q9DDS92L"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Config/Info.plist)
artifact_base="Login-Link-Fixer-${version}"
app_zip="${dist_dir}/${artifact_base}-app.zip"
dmg_path="${dist_dir}/${artifact_base}.dmg"

fail() { print -u2 "Error: $*"; exit 1; }

command -v xcodebuild >/dev/null || fail "Xcode is required"
command -v xcodegen >/dev/null || fail "xcodegen is required"
security find-identity -v -p codesigning | grep -Fq "\"${sign_identity}\"" || fail "Developer ID signing identity is unavailable: ${sign_identity}"
xcrun notarytool history --keychain-profile "$notary_profile" >/dev/null 2>&1 || fail "Notary profile '${notary_profile}' is unavailable. Save credentials with xcrun notarytool store-credentials."

print "Building ${app_name} ${version} for Apple silicon and Intel…"
xcodebuild -project LoginLinkFixer.xcodeproj \
    -scheme LoginLinkFixer \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "${PWD}/DerivedData" \
    -quiet \
    clean build \
    ARCHS='arm64 x86_64' \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$sign_identity" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    DEVELOPMENT_TEAM="$team_id" \
    CONFIGURATION_BUILD_DIR="${PWD}/build/Release"

[[ -d "$app_path" ]] || fail "App bundle was not built"
[[ "$(lipo -archs "${app_path}/Contents/MacOS/Login Link Fixer")" == 'x86_64 arm64' ]] || fail "App executable is not universal"
codesign --verify --deep --strict --verbose=2 "$app_path"

mkdir -p "$dist_dir"
rm -f "$app_zip" "$dmg_path" "${dmg_path}.sha256"
print "Notarizing the app…"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$app_zip"
xcrun notarytool submit "$app_zip" --keychain-profile "$notary_profile" --wait
xcrun stapler staple "$app_path"
xcrun stapler validate "$app_path"
rm "$app_zip"

print "Creating the drag-to-Applications disk image…"
rm -rf "$staging_dir"
mkdir -p "$staging_dir"
ditto "$app_path" "${staging_dir}/${app_name}.app"
ln -s /Applications "${staging_dir}/Applications"
hdiutil create -volname "$app_name" -srcfolder "$staging_dir" -format UDZO "$dmg_path"
rm -rf "$staging_dir"
codesign --sign "$sign_identity" --timestamp "$dmg_path"
codesign --verify --verbose=2 "$dmg_path"

print "Notarizing the disk image…"
xcrun notarytool submit "$dmg_path" --keychain-profile "$notary_profile" --wait
xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"
hdiutil verify "$dmg_path"
spctl --assess --type execute --verbose=2 "$app_path"
spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg_path"

(cd "$dist_dir" && shasum -a 256 "${artifact_base}.dmg" > "${artifact_base}.dmg.sha256")
print "Ready: ${dmg_path}"
print "Checksum: ${dmg_path}.sha256"

#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Usage: ./scripts/build.sh [arm64|x86_64|universal]
ARCH="${1:-$(uname -m)}"
case "$ARCH" in arm64|x86_64|universal) ;; *) echo 'Choose arm64, x86_64 or universal.' >&2; exit 2 ;; esac
VERSION="${AIRDIAL_VERSION:-0.1.0-beta}"
if [[ ! "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
    echo 'Version must look like 0.1.0 or v0.1.0-beta.' >&2; exit 2
fi
BUILD_ROOT="${AIRDIAL_BUILD_ROOT:-$PWD/.build}"
DIST_ROOT="${AIRDIAL_DIST_ROOT:-$PWD/dist}"
mkdir -p "$BUILD_ROOT" "$DIST_ROOT"
STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/airdial-package.XXXXXX")"
trap 'rm -rf "$STAGING_ROOT"' EXIT
APP="$STAGING_ROOT/AirDial.app"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$BUILD_ROOT/ModuleCache}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$BUILD_ROOT/ModuleCache}"

build_arch() {
    local arch="$1"
    local args=(-c release --product AirDial --scratch-path "$BUILD_ROOT/$arch" --arch "$arch"
        --cache-path "$BUILD_ROOT/cache" --config-path "$BUILD_ROOT/config" --security-path "$BUILD_ROOT/security")
    if [[ -n "${AIRDIAL_SDK:-}" ]]; then args+=(--sdk "$AIRDIAL_SDK"); fi
    if [[ -n "${AIRDIAL_BUILD_SYSTEM:-}" ]]; then args+=(--build-system "$AIRDIAL_BUILD_SYSTEM"); fi
    if [[ "${AIRDIAL_SWIFTPM_DISABLE_SANDBOX:-0}" == 1 ]]; then args+=(--disable-sandbox); fi
    swift build "${args[@]}"
}

if [[ "$ARCH" == universal ]]; then
    build_arch arm64
    build_arch x86_64
else
    build_arch "$ARCH"
fi

# Sign in a temporary staging directory. Cloud-backed folders can reattach Finder metadata.
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [[ "$ARCH" == universal ]]; then
    lipo -create "$BUILD_ROOT/arm64/arm64-apple-macosx/release/AirDial" \
        "$BUILD_ROOT/x86_64/x86_64-apple-macosx/release/AirDial" -output "$APP/Contents/MacOS/AirDial"
else
    cp "$BUILD_ROOT/$ARCH/$ARCH-apple-macosx/release/AirDial" "$APP/Contents/MacOS/AirDial"
fi
cp Resources/Info.plist "$APP/Contents/Info.plist"
APP_VERSION="${VERSION#v}"
APP_VERSION="${APP_VERSION%%-*}"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$APP/Contents/Info.plist"
cp -R Resources/en.lproj Resources/zh-Hans.lproj "$APP/Contents/Resources/"
chmod +x "$APP/Contents/MacOS/AirDial"
# Remove Finder / file-provider metadata from this generated bundle before signing.
xattr -cr "$APP"

if [[ -n "${AIRDIAL_SIGN_IDENTITY:-}" ]]; then
    codesign --force --options runtime --timestamp --sign "$AIRDIAL_SIGN_IDENTITY" \
        --entitlements Resources/AirDial.entitlements "$APP"
else
    codesign --force --sign - --entitlements Resources/AirDial.entitlements "$APP"
fi
codesign --verify --strict "$APP"
ARCHIVE="$DIST_ROOT/AirDial-$VERSION-$ARCH.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
(
    cd "$DIST_ROOT"
    shasum -a 256 "$(basename "$ARCHIVE")" > "$(basename "$ARCHIVE").sha256"
)
if [[ -e "$DIST_ROOT/AirDial.app" ]]; then rm -rf "$DIST_ROOT/AirDial.app"; fi
ditto --noextattr --norsrc "$APP" "$DIST_ROOT/AirDial.app"
echo "Built: $DIST_ROOT/AirDial.app"
echo "Archive: $ARCHIVE"

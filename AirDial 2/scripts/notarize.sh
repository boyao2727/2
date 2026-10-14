#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Store Developer ID + notary credentials in Keychain first; no secrets belong in the repo.
: "${AIRDIAL_SIGN_IDENTITY:?Set AIRDIAL_SIGN_IDENTITY to your Developer ID Application identity.}"
: "${AIRDIAL_NOTARY_PROFILE:?Set AIRDIAL_NOTARY_PROFILE to a notarytool Keychain profile.}"
ARCH="${1:-universal}"
VERSION="${AIRDIAL_VERSION:-0.1.0-beta}"
DIST_ROOT="${AIRDIAL_DIST_ROOT:-$PWD/dist}"
bash scripts/build.sh "$ARCH"
ZIP="$DIST_ROOT/AirDial-$VERSION-$ARCH.zip"
xcrun notarytool submit "$ZIP" --keychain-profile "$AIRDIAL_NOTARY_PROFILE" --wait
STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/airdial-notarize.XXXXXX")"
trap 'rm -rf "$STAGING_ROOT"' EXIT
ditto -x -k "$ZIP" "$STAGING_ROOT"
codesign --verify --strict "$STAGING_ROOT/AirDial.app"
xcrun stapler staple "$STAGING_ROOT/AirDial.app"
xcrun stapler validate "$STAGING_ROOT/AirDial.app"
ditto -c -k --sequesterRsrc --keepParent "$STAGING_ROOT/AirDial.app" "$ZIP"
(
    cd "$DIST_ROOT"
    shasum -a 256 "$(basename "$ZIP")" > "$(basename "$ZIP").sha256"
)
rm -rf "$DIST_ROOT/AirDial.app"
ditto --noextattr --norsrc "$STAGING_ROOT/AirDial.app" "$DIST_ROOT/AirDial.app"
echo "Notarized: $ZIP"

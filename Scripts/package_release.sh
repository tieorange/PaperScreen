#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PaperScreen"
SCHEME="PaperScreen"
PROJECT="PaperScreen.xcodeproj"
CONFIGURATION="Release"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/release"
DIST_DIR="$ROOT_DIR/dist"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
STAGING_DIR="$BUILD_DIR/staging"
STAGED_APP="$STAGING_DIR/$APP_NAME.app"

RELEASE_VERSION="${RELEASE_VERSION:-}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARIZE="${NOTARIZE:-0}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD:-}"

if [[ -z "$RELEASE_VERSION" ]]; then
  RELEASE_VERSION="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings -configuration "$CONFIGURATION" 2>/dev/null | awk -F '= ' '/MARKETING_VERSION/ {print $2; exit}')"
fi

if [[ -z "$RELEASE_VERSION" ]]; then
  RELEASE_VERSION="1.0"
fi

ZIP_PATH="$DIST_DIR/$APP_NAME-$RELEASE_VERSION-macOS.zip"
DMG_RW_PATH="$BUILD_DIR/$APP_NAME-$RELEASE_VERSION-rw.dmg"
DMG_PATH="$DIST_DIR/$APP_NAME-$RELEASE_VERSION-macOS.dmg"
DMG_VOLUME="$APP_NAME $RELEASE_VERSION"

echo "==> Cleaning release folders"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$STAGING_DIR"

echo "==> Archiving $APP_NAME $RELEASE_VERSION"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  SKIP_INSTALL=NO

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: archive did not produce $APP_PATH" >&2
  exit 1
fi

echo "==> Staging app"
ditto "$APP_PATH" "$STAGED_APP"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "==> Signing app with identity: $SIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$STAGED_APP"
fi

echo "==> Verifying code signature"
codesign --verify --deep --strict --verbose=2 "$STAGED_APP"

echo "==> Creating zip"
ditto -c -k --keepParent "$STAGED_APP" "$ZIP_PATH"

echo "==> Creating DMG"
rm -f "$DMG_RW_PATH" "$DMG_PATH"
hdiutil create \
  -volname "$DMG_VOLUME" \
  -srcfolder "$STAGING_DIR" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  "$DMG_RW_PATH"

MOUNT_DIR="$(mktemp -d "$BUILD_DIR/dmg-mount.XXXXXX")"
DEVICE=""
cleanup() {
  if [[ -n "$DEVICE" ]]; then
    hdiutil detach "$DEVICE" -quiet || hdiutil detach "$DEVICE" -force -quiet || true
  fi
  rm -rf "$MOUNT_DIR" || true
}
trap cleanup EXIT

DEVICE="$(hdiutil attach "$DMG_RW_PATH" -mountpoint "$MOUNT_DIR" -nobrowse | awk '$1 ~ /^\/dev\/disk/ {device=$1} END {print device}')"
if [[ -z "$DEVICE" ]]; then
  echo "error: failed to attach DMG or parse mounted device" >&2
  exit 1
fi
ln -s /Applications "$MOUNT_DIR/Applications"
sync
for attempt in 1 2 3 4 5; do
  if hdiutil detach "$DEVICE" -quiet; then
    break
  fi
  sleep 1
  if [[ "$attempt" == "5" ]]; then
    hdiutil detach "$DEVICE" -force -quiet
  fi
done
DEVICE=""

hdiutil convert "$DMG_RW_PATH" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" -quiet

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "==> Signing DMG"
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
fi

if [[ "$NOTARIZE" == "1" ]]; then
  echo "==> Notarizing DMG"
  if [[ -n "$NOTARY_PROFILE" ]]; then
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  else
    if [[ -z "$APPLE_ID" || -z "$APPLE_TEAM_ID" || -z "$APPLE_APP_PASSWORD" ]]; then
      echo "error: notarization needs NOTARY_PROFILE or APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD" >&2
      exit 1
    fi
    xcrun notarytool submit "$DMG_PATH" \
      --apple-id "$APPLE_ID" \
      --team-id "$APPLE_TEAM_ID" \
      --password "$APPLE_APP_PASSWORD" \
      --wait
  fi

  echo "==> Stapling notarization ticket"
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

echo "==> Release artifacts"
ls -lh "$DIST_DIR"
echo ""
echo "Upload these files to a GitHub Release:"
echo "  $DMG_PATH"
echo "  $ZIP_PATH"

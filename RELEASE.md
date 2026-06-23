# Releasing PaperScreen on GitHub

Use this guide to produce installable release files for GitHub Releases.

## Quick Local Release

Run from the repository root:

```sh
./Scripts/package_release.sh
```

Artifacts are written to `dist/`:

- `PaperScreen-<version>-macOS.dmg` — recommended download for users
- `PaperScreen-<version>-macOS.zip` — fallback archive

Upload both files to a GitHub Release.

## User Installation Flow

Users should download the `.dmg`, open it, drag `PaperScreen.app` to `Applications`, then launch it from Applications.

If the app is not notarized, macOS Gatekeeper may show a warning. For the smoothest install experience, sign and notarize the DMG.

## Optional Signing

Set `SIGN_IDENTITY` to a Developer ID Application certificate name:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./Scripts/package_release.sh
```

To see available identities:

```sh
security find-identity -v -p codesigning
```

## Optional Notarization

Recommended setup: create a notarytool keychain profile once:

```sh
xcrun notarytool store-credentials "paperscreen-notary" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

Then package, sign, notarize, and staple:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARIZE=1 \
NOTARY_PROFILE="paperscreen-notary" \
./Scripts/package_release.sh
```

Alternative without a saved profile:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARIZE=1 \
APPLE_ID="you@example.com" \
APPLE_TEAM_ID="TEAMID" \
APPLE_APP_PASSWORD="app-specific-password" \
./Scripts/package_release.sh
```

## Versioning

The script reads `MARKETING_VERSION` from the Xcode project. Override it for a specific release:

```sh
RELEASE_VERSION="1.0.1" ./Scripts/package_release.sh
```

For a real release, update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in Xcode before packaging.

## GitHub Release Checklist

1. Update version/build number.
2. Run `./Scripts/package_release.sh`.
3. Test the generated `.dmg` locally.
4. Create a Git tag, for example `v1.0.0`.
5. Create a GitHub Release from that tag.
6. Upload the `.dmg` and `.zip` from `dist/`.
7. Add install instructions to the release notes.

Suggested release note snippet:

```md
## Install

Download `PaperScreen-<version>-macOS.dmg`, open it, drag PaperScreen to Applications, then launch it from Applications.

PaperScreen is a menu bar app. Look for the paper icon in the macOS menu bar after launch.
```

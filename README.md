# PaperScreen

Make your Mac screen feel softer and more paper-like.

PaperScreen is a lightweight macOS menu bar utility that places a subtle, click-through paper overlay on every display. It is designed for bright apps like VS Code, Safari, Notes, PDFs, and documentation.

![PaperScreen popover UI showing paper style presets](PaperScreen/preview.png)

## Download

Download the latest `.dmg` from GitHub Releases.

Install:

1. Open `PaperScreen-<version>-macOS.dmg`.
2. Drag `PaperScreen.app` to `Applications`.
3. Launch PaperScreen from Applications.
4. Use the menu bar paper icon to choose a style and intensity.

## Features

- Whole-screen paper overlay for all displays.
- Paper styles including Writing Paper, Cotton Paper, Xuan Paper, Rice Paper, Parchment, Frosted, Cardstock, and Newsprint.
- One simple `Intensity` control from `0%` to `200%`.
- Pause for color-sensitive work.
- Compare against the original display.
- Optional fullscreen Spaces coverage.
- Launch at Login.
- No Screen Recording permission.
- No Accessibility permission.
- No network requests.

## Privacy

PaperScreen does not capture, record, read, sample, or upload your screen. It only draws transparent overlay windows above your displays. Settings are stored locally with `UserDefaults`.

## Build From Source

Requirements:

- macOS with Xcode installed.
- No external dependencies.

Build:

```sh
xcodebuild -project PaperScreen.xcodeproj -scheme PaperScreen -configuration Release build
```

Create GitHub Release artifacts:

```sh
./Scripts/package_release.sh
```

See `RELEASE.md` for signing and notarization instructions.

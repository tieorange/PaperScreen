# PaperScreen Implementation Plan

This plan is written as an implementation playbook for a coding agent. Follow it in order. Keep the first version minimal, native, reliable, and buildable.

## 0. Product Goal

Build a macOS menu bar utility that makes the whole screen feel softer and more paper-like by placing a transparent, click-through overlay above each display.

The app should help bright apps such as VS Code, Safari, Finder, Notes, PDFs, and documentation feel less harsh at night.

The app should copy the useful parts of PaperDisplay's preset concept, but with a better native UI and clearer controls.

## 1. MVP Scope

Implement this first:

- Menu bar only app.
- No Dock icon and no default app window.
- One click-through overlay panel per display.
- Six presets: Original, Writing Paper, Xuan Paper, Parchment, Frosted, Newsprint.
- Preset switching from a SwiftUI popover.
- Controls for enabled, intensity, texture, warmth, vignette, dark-mode reduction, launch at login.
- Settings persist through relaunch.
- Generated procedural paper textures. Do not depend on external image assets for MVP.
- Build succeeds with `xcodebuild`.

Do not implement in MVP:

- Screen recording.
- ScreenCaptureKit.
- Accessibility permissions.
- Pixel analysis.
- Network features.
- Per-app or per-window filtering.
- Per-display settings.
- Scheduling.
- Global keyboard shortcuts.
- App Store onboarding.

## 2. Important Technical Truth

A normal transparent overlay cannot know whether the pixels underneath are bright or dark. It cannot selectively soften only white backgrounds unless it records or samples the screen.

For MVP, approximate a color-aware effect by using:

- Low-opacity warm/neutral tints.
- Subtle generated texture.
- Lower strength in dark mode.
- Conservative defaults.

Do not claim that MVP preserves colors by analyzing screen content. It only visually overlays paper tone and texture.

## 3. Current Project Assumptions

Expected current files:

- `PaperScreen/PaperScreenApp.swift`
- `PaperScreen/ContentView.swift`
- `PaperScreen/Assets.xcassets`
- `PaperScreen/Plan.md`
- `PaperScreen.xcodeproj/project.pbxproj`

The project uses an Xcode file-system synchronized root group. New Swift files placed under `PaperScreen/` should be included automatically. Avoid manual `.pbxproj` edits unless build proves the files are not included.

## 4. Recommended Implementation Order

Implement in this exact order:

1. Add model and state files.
2. Add a simple menu bar app shell with popover.
3. Add overlay panels with a plain tint only.
4. Connect state changes to overlay updates.
5. Add generated textures and preset-specific rendering.
6. Replace simple popover with polished UI components.
7. Add launch-at-login support.
8. Add `LSUIElement` after the app works from the menu bar.
9. Build and manually QA.

Do not start with the polished UI. First prove the overlay works.

## 5. Final File Layout

Create these files:

```text
PaperScreen/
├── PaperScreenApp.swift
├── AppDelegate.swift
├── AppState.swift
├── Models/
│   ├── PaperPreset.swift
│   └── PaperSettings.swift
├── Overlay/
│   ├── PaperOverlayPanel.swift
│   ├── OverlayWindowManager.swift
│   ├── OverlayView.swift
│   └── PaperTextureFactory.swift
├── UI/
│   ├── SettingsPopoverView.swift
│   ├── PresetCard.swift
│   ├── PaperSlider.swift
│   ├── MiniPaperPreview.swift
│   └── VisualEffectView.swift
└── Plan.md
```

`ContentView.swift` can be deleted or left unused. Prefer deleting it if no references remain.

## 6. Data Model

### 6.1 `PaperSettings.swift`

Purpose: central constants for UserDefaults keys and value ranges.

Implement:

- `enum PaperSettings`
- Nested `enum Keys`
- Static defaults and clamp helpers.

Keys:

- `isEnabled`
- `selectedPresetID`
- `intensity`
- `textureStrength`
- `warmth`
- `vignetteStrength`
- `reduceEffectInDarkMode`
- `launchAtLogin`

Default values:

- `isEnabled = true`
- `selectedPresetID = "writingPaper"`
- `intensity = 0.55`
- `textureStrength = 0.45`
- `warmth = 0.35`
- `vignetteStrength = 0.5`
- `reduceEffectInDarkMode = true`
- `launchAtLogin = false`

Ranges:

- Intensity: `0...1`
- Texture strength: `0...1`
- Warmth: `0...1`
- Vignette strength: `0...1`

### 6.2 `PaperPreset.swift`

Purpose: define the six paper styles and all rendering parameters.

Implement:

```swift
enum PaperTextureStyle: String, Codable, CaseIterable {
    case none
    case fineGrain
    case longFibers
    case parchment
    case frosted
    case newsprint
}

struct PaperPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let tint: NSColor
    let lightOpacity: Double
    let darkOpacity: Double
    let textureStyle: PaperTextureStyle
    let textureOpacity: Double
    let vignetteOpacity: Double
    let previewA: NSColor
    let previewB: NSColor
}
```

Add:

- `static let all: [PaperPreset]`
- `static let original`
- `static let writingPaper`
- `static let xuanPaper`
- `static let parchment`
- `static let frosted`
- `static let newsprint`
- `static func preset(id: String) -> PaperPreset`

Preset IDs:

- `original`
- `writingPaper`
- `xuanPaper`
- `parchment`
- `frosted`
- `newsprint`

Preset starting values:

| ID | Name | Tint | Light Opacity | Dark Opacity | Texture | Texture Opacity | Vignette |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `original` | Original | clear | 0.00 | 0.00 | none | 0.00 | 0.00 |
| `writingPaper` | Writing Paper | `#FFFBEA` | 0.075 | 0.025 | fineGrain | 0.055 | 0.00 |
| `xuanPaper` | Xuan Paper | `#FFFEF8` | 0.060 | 0.020 | longFibers | 0.070 | 0.00 |
| `parchment` | Parchment | `#F3DCA5` | 0.115 | 0.035 | parchment | 0.075 | 0.28 |
| `frosted` | Frosted | `#FFFFFF` | 0.085 | 0.025 | frosted | 0.035 | 0.00 |
| `newsprint` | Newsprint | `#E9E2D5` | 0.095 | 0.030 | newsprint | 0.105 | 0.18 |

Add an `NSColor` helper initializer from hex in this file or a small extension near the bottom.

Keep all preset values in this file so tuning is easy.

## 7. App State

### 7.1 `AppState.swift`

Purpose: observable, persisted app state.

Implement as `@MainActor final class AppState: ObservableObject`.

Use `@Published` properties and write persisted settings to `UserDefaults` in `didSet`.

Properties:

- `isEnabled: Bool`
- `selectedPresetID: String`
- `intensity: Double`
- `textureStrength: Double`
- `warmth: Double`
- `vignetteStrength: Double`
- `reduceEffectInDarkMode: Bool`
- `launchAtLogin: Bool`
- `isComparingOriginal: Bool`

Persistence rule:

- Persist every property above except `isComparingOriginal`.
- `isComparingOriginal` is transient UI state only and must reset to `false` on launch.
- Do not call `SMAppService` directly from the plain `launchAtLogin` `didSet`; use a method so initialization from UserDefaults does not accidentally register or unregister login items.

Computed properties:

- `selectedPreset: PaperPreset`
- `effectivePreset: PaperPreset`

`effectivePreset` should return `.original` when:

- `isEnabled == false`
- `isComparingOriginal == true`
- `selectedPresetID == "original"`

Methods:

- `resetCurrentPresetControls()`
- `applyNightComfort()`
- `selectPreset(_ preset: PaperPreset)`
- `setLaunchAtLogin(_ enabled: Bool)`

Implementation notes:

- When reading persisted values, handle missing keys explicitly. `UserDefaults.bool(forKey:)` returns `false` for missing keys, which would break defaults like `isEnabled = true` and `reduceEffectInDarkMode = true`. Use `object(forKey:) as? Bool ?? defaultValue`.
- Clamp slider values safely. Avoid assigning to the same property unconditionally inside its own `didSet`, because that can recurse. Use `let clamped = PaperSettings.clamp(value)` and only assign back if `clamped != value`, or clamp before assigning in explicit setter methods.
- Do not use Combine-heavy code unless needed.
- Keep this file simple and predictable.

## 8. App Lifecycle And Menu Bar

### 8.1 `PaperScreenApp.swift`

Replace the default `WindowGroup` with an app delegate adaptor.

Target shape:

```swift
import SwiftUI

@main
struct PaperScreenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

If `Settings { EmptyView() }` causes build trouble, use a minimal settings scene with `Text("PaperScreen")`. Do not show a main window.

### 8.2 `AppDelegate.swift`

Purpose: own the status item, popover, shared state, and overlay manager.

Implement:

- `final class AppDelegate: NSObject, NSApplicationDelegate`
- `let appState = AppState()`
- `var statusItem: NSStatusItem?`
- `var popover: NSPopover?`
- `var overlayManager: OverlayWindowManager?`

In `applicationDidFinishLaunching`:

- Set activation policy to `.accessory`.
- Create `OverlayWindowManager(appState: appState)`.
- Call `overlayManager?.start()`.
- Create status item using `NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)`.
- Use SF Symbol `doc.text` or `doc.plaintext` if available.
- Set button action to `togglePopover(_:)`.
- Create `NSPopover` with SwiftUI root `SettingsPopoverView(appState: appState, onQuit: { [weak self] in self?.quit() })`.

Popover behavior:

- `.behavior = .transient`
- Content size around `420x620`.
- Show relative to status item button bounds.
- Close if already shown.

Add a `quit()` method:

- Close popover.
- Stop overlay manager.
- `NSApp.terminate(nil)`.

Pass quit action to UI as a closure if convenient.

## 9. Overlay Window System

### 9.1 `PaperOverlayPanel.swift`

Purpose: non-interactive transparent panel.

Implement subclass:

```swift
final class PaperOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
```

Add initializer:

- Accept `screen: NSScreen` and `contentView: NSView`.
- Use `screen.frame`.
- Style mask: `[.borderless, .nonactivatingPanel]`.
- Backing: `.buffered`.
- Defer: `false`.

Configure:

- `level = .statusBar` initially.
- `backgroundColor = .clear`.
- `isOpaque = false`.
- `hasShadow = false`.
- `ignoresMouseEvents = true`.
- `hidesOnDeactivate = false`.
- `isReleasedWhenClosed = false`.
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`.
- `self.contentView = contentView`.
- `orderFrontRegardless()` when showing.

If overlay does not appear over fullscreen apps, test `NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))` later. Do not start there.

### 9.2 `OverlayWindowManager.swift`

Purpose: create and maintain overlay panels for every screen.

Implement as `@MainActor final class OverlayWindowManager`.

Properties:

- `private let appState: AppState`
- `private var panels: [String: PaperOverlayPanel] = [:]`
- `private var observers: [NSObjectProtocol] = []`

Required imports:

- `AppKit`
- `SwiftUI`

Methods:

- `init(appState: AppState)`
- `start()`
- `stop()`
- `syncScreens()`
- `screenID(for screen: NSScreen) -> String`
- `makePanel(for screen: NSScreen) -> PaperOverlayPanel`
- `updatePanelFrames()`

In `start()`:

- Call `syncScreens()`.
- Observe screen parameter changes.
- Observe active Space changes.
- Do not subscribe to setting changes in the manager. Each panel hosts `OverlayView(appState: appState)`, and SwiftUI updates automatically when `AppState` changes.

Use notifications:

- `NSApplication.didChangeScreenParametersNotification`
- `NSWorkspace.activeSpaceDidChangeNotification`

In `syncScreens()`:

- Get current `NSScreen.screens`.
- Build current screen IDs with `screenID(for:)`.
- Remove panels whose screen ID no longer exists.
- Create panels for new screen IDs.
- Update frames for existing panels.

In `updatePanelFrames()`:

- Loop through `NSScreen.screens`.
- Find the matching panel by `screenID(for:)`.
- Set the panel frame to `screen.frame`.
- Ensure the panel remains ordered front.

Panel content:

```swift
let rootView = OverlayView(appState: appState)
let hostingView = NSHostingView(rootView: rootView)
hostingView.frame = screen.frame
hostingView.autoresizingMask = [.width, .height]
```

Potential issue:

- Use string keys rather than `NSScreen` keys. A simple MVP key can be `"\(screen.localizedName)-\(screen.frame.origin.x)-\(screen.frame.origin.y)-\(screen.frame.width)-\(screen.frame.height)"`.
- This key changes when the display layout changes, which is acceptable because `syncScreens()` can recreate affected panels.

## 10. Overlay Rendering

### 10.1 `OverlayView.swift`

Purpose: draw tint, texture, and vignette.

Implement:

```swift
struct OverlayView: View {
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View { ... }
}
```

Behavior:

- If `effectivePreset.id == "original"`, render `Color.clear`.
- Otherwise render full-screen `ZStack`.
- Always ignore safe areas.
- Do not animate by default.

Opacity calculation:

- Base opacity = preset light or dark opacity.
- If dark mode and `reduceEffectInDarkMode`, multiply base by `0.65`.
- Multiply by user `intensity` mapped to a useful range: `0.25 + intensity * 1.25`.
- Texture opacity = preset texture opacity * textureStrength.
- If dark mode and reduction enabled, multiply texture by `0.55`.
- Vignette opacity = preset vignette opacity * vignetteStrength * intensity.

Warmth calculation:

- Mix the preset tint toward a warmer paper color as `warmth` increases.
- Keep this simple. Use a helper that blends `NSColor` components.

Layer order:

1. `Color(nsColor: adjustedTint).opacity(baseOpacity)`
2. `Image(nsImage: texture).resizable(resizingMode: .tile).opacity(textureOpacity)`
3. Vignette gradient if opacity > 0

SwiftUI image tiling:

- Use `Image(nsImage: texture).resizable(resizingMode: .tile)`.
- If tiling gives compile issues, use a `GeometryReader` and draw repeated images later. Do not overcomplicate on first pass.

Vignette:

```swift
RadialGradient(
    colors: [.clear, .black.opacity(vignetteOpacity)],
    center: .center,
    startRadius: 200,
    endRadius: 1200
)
.blendMode(.multiply)
```

Do not rely on SwiftUI blend modes to blend with underlying app pixels. A transparent overlay is composited by the window server; blend modes only reliably affect layers inside the overlay view.

### 10.2 `PaperTextureFactory.swift`

Purpose: generate deterministic paper textures.

Implement as:

```swift
enum PaperTextureFactory {
    static func texture(for style: PaperTextureStyle) -> NSImage?
}
```

Add in-memory cache:

- `private static var cache: [PaperTextureStyle: NSImage] = [:]`

Texture size:

- Start with `512x512`.
- Use `NSImage(size:)` and `lockFocus()` for simplicity, or CoreGraphics bitmap context.
- CoreGraphics is better, but simple AppKit drawing is acceptable for MVP.

Generated styles:

- `.none`: return nil.
- `.fineGrain`: tiny gray/brown dots with low alpha.
- `.longFibers`: sparse vertical and diagonal thin lines.
- `.parchment`: warm mottled circles/clouds and light fibers.
- `.frosted`: very soft white/gray noise.
- `.newsprint`: more visible speckles, short fibers, tiny imperfect marks.

Use deterministic pseudo-randomness:

- Add a small seeded generator type inside this file.
- Do not use `Double.random` without a seed, or textures will change every launch.

Keep alpha subtle. The overlay should never look dirty by default.

## 11. Popover UI

### 11.1 `SettingsPopoverView.swift`

Purpose: main settings UI.

Implement:

```swift
struct SettingsPopoverView: View {
    @ObservedObject var appState: AppState
    let onQuit: () -> Void
}
```

If passing `onQuit` is inconvenient, call `NSApp.terminate(nil)` directly from the button.

Layout:

- Width: about 420.
- Use `VStack(spacing: 18)`.
- Add warm paper-like background.
- Use `.padding(20)`.

Sections:

1. Header.
2. Preset grid.
3. Sliders.
4. Quick actions.
5. Footer.

Header:

- Title: `PaperScreen`.
- Subtitle: current preset description.
- Toggle: enabled.

Preset grid:

- `LazyVGrid` with two flexible columns.
- Render `PaperPreset.all` using `PresetCard`.
- Clicking card calls `appState.selectPreset(preset)`.

Controls:

- `PaperSlider(title: "Intensity", value: $appState.intensity, systemImage: "sun.max")`
- `PaperSlider(title: "Texture", value: $appState.textureStrength, systemImage: "circle.grid.cross")`
- `PaperSlider(title: "Warmth", value: $appState.warmth, systemImage: "thermometer.sun")`
- `PaperSlider(title: "Edges", value: $appState.vignetteStrength, systemImage: "rectangle.dashed")`

Quick actions:

- Button: `Night Comfort`, calls `applyNightComfort()`.
- Button: `Reset`, calls `resetCurrentPresetControls()`.
- Press-and-hold Original compare:
  - On press down set `isComparingOriginal = true`.
  - On release set `isComparingOriginal = false`.
  - If gesture complexity causes delay, implement a normal toggle named `Compare Original` for MVP.

Footer:

- Toggle: `Reduce in Dark Mode`.
- Toggle: `Launch at Login`.
- Button: `Quit`.
- Small privacy text: `No screen recording. Local settings only.`

### 11.2 `PresetCard.swift`

Purpose: clickable preset card.

Inputs:

- `preset: PaperPreset`
- `isSelected: Bool`
- `action: () -> Void`

UI:

- Button with plain style.
- `MiniPaperPreview` on top.
- Preset name.
- One-line description.
- Selected border in warm brown.
- Hover background change.

Use `@State private var isHovering = false`.

### 11.3 `MiniPaperPreview.swift`

Purpose: small visual preview for cards.

Inputs:

- `preset: PaperPreset`

UI:

- Rounded rectangle.
- Linear gradient from `previewA` to `previewB`.
- Optional texture-like overlay using simple `Canvas` or repeated lines.
- No dependency on generated NSImage required.

Keep it simple and fast.

### 11.4 `PaperSlider.swift`

Purpose: consistent slider row.

Inputs:

- `title: String`
- `value: Binding<Double>`
- `systemImage: String`

UI:

- HStack label with SF Symbol.
- Slider range `0...1`.
- Percentage label.

### 11.5 `VisualEffectView.swift`

Purpose: optional `NSVisualEffectView` bridge.

Implement only if needed for nicer popover background.

If it causes complexity, skip and use SwiftUI materials like `.background(.regularMaterial)`.

## 12. Launch At Login

Use `ServiceManagement`.

Add launch-at-login helper in either `AppState` or a small private method in `SettingsPopoverView`.

Preferred simple implementation:

- Add `setLaunchAtLogin(_ enabled: Bool)` to `AppState`.
- In that method, call `SMAppService.mainApp.register()` or `SMAppService.mainApp.unregister()`.
- Only update the persisted `launchAtLogin` value after the ServiceManagement call succeeds.
- If the call fails, keep the previous value and print the error for MVP.
- Wire the UI Toggle through a custom `Binding` that calls `setLaunchAtLogin(_:)` instead of binding directly to `$appState.launchAtLogin`.

APIs:

```swift
try SMAppService.mainApp.register()
try SMAppService.mainApp.unregister()
```

Implementation notes:

- Import `ServiceManagement`.
- Catch errors and print them for MVP.
- Do not crash if registration fails.
- Keep `launchAtLogin` setting in sync as best as possible.

If this API causes build issues, postpone launch-at-login and leave a clearly marked TODO in `Plan.md` or code. Do not block the overlay MVP on it.

## 13. Generated Info.plist / Build Settings

The app should eventually be menu-bar only.

Set in the target build settings:

- `INFOPLIST_KEY_LSUIElement = YES`

Because the project uses generated Info.plist, this is done in `project.pbxproj` under both Debug and Release target build settings.

Only edit `.pbxproj` after the menu bar app works. If editing `.pbxproj`, make the smallest possible change.

Current target build settings already include:

- `GENERATE_INFOPLIST_FILE = YES`
- `ENABLE_APP_SANDBOX = YES`
- `ENABLE_HARDENED_RUNTIME = YES`

Keep sandbox enabled.

## 14. Build And Verification

Run this after major phases:

```sh
xcodebuild -project PaperScreen.xcodeproj -scheme PaperScreen -configuration Debug build
```

Manual QA checklist:

- App launches.
- App appears in menu bar.
- No normal app window opens after `LSUIElement` is enabled.
- Popover opens and closes from status item.
- Enabled toggle shows/hides effect immediately.
- Presets visibly change the whole display.
- Original disables the overlay visually.
- Mouse clicks pass through the overlay.
- Keyboard focus remains in underlying apps.
- Overlay follows all connected displays.
- Unplugging/replugging a display does not leave stale panels.
- Dark mode effect is restrained and not muddy.
- Settings persist after relaunch.
- Idle CPU stays near zero.
- App does not request Screen Recording permission.
- App does not request Accessibility permission.

## 15. Common Pitfalls And Fixes

### Overlay blocks clicks

Check:

- `ignoresMouseEvents = true`
- `canBecomeKey == false`
- `canBecomeMain == false`
- Panel style includes `.nonactivatingPanel`

### Overlay does not cover fullscreen apps

First verify:

- `.canJoinAllSpaces`
- `.fullScreenAuxiliary`
- `.stationary`

Then test higher window level only if required.

### App shows a Dock icon

Check:

- `NSApp.setActivationPolicy(.accessory)` in `applicationDidFinishLaunching`
- `INFOPLIST_KEY_LSUIElement = YES` in Debug and Release build settings

### New Swift files are not building

The project should auto-include files via synchronized groups. If not, inspect `.pbxproj` and add files manually as a last resort.

### Texture looks too dirty

Reduce:

- Preset `textureOpacity`
- User default `textureStrength`
- Alpha values inside generated texture drawing

### Dark mode loses contrast

Reduce:

- Dark opacity values in `PaperPreset`
- Dark-mode multiplier in `OverlayView`
- Parchment and Newsprint texture opacity

## 16. Acceptance Criteria

The MVP is accepted when:

- The code builds cleanly.
- The app runs as a menu bar utility.
- The overlay covers every display.
- The overlay is click-through.
- All six presets work.
- The UI is polished enough to use daily.
- Settings persist.
- Launch at login works or is explicitly marked as postponed due to API/build constraints.
- No Screen Recording or Accessibility permissions are required.

## 17. Final Notes For The Implementing Agent

- Make the smallest correct implementation for each phase.
- Keep files focused and short.
- Do not introduce a complex dependency or package manager.
- Do not add ScreenCaptureKit for MVP.
- Do not implement real pixel-aware rendering.
- Prefer native AppKit plus SwiftUI.
- Build often.
- Tune visuals conservatively.
- If a feature becomes risky, finish the overlay MVP first and leave the risky feature for later.

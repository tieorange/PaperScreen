# PaperScreen — Agent Guide

## Product Summary

PaperScreen is a macOS menu bar utility that places a transparent, click-through overlay window on every display, making screens feel softer and more paper-like. It targets apps like VS Code, Safari, Notes, and PDFs that are harsh in dark environments.

Key characteristics:
- Menu bar only — no Dock icon, no main window
- One `NSPanel` per display; automatically tracks display changes
- Six built-in presets (Original, Writing Paper, Xuan Paper, Parchment, Frosted, Newsprint)
- All settings persist via `UserDefaults`
- Procedurally generated textures — zero external image assets
- Sandboxed — no Screen Recording, no Accessibility permissions ever required

---

## File Map

```
PaperScreen/
├── PaperScreenApp.swift          # @main — wires NSApplicationDelegateAdaptor
├── AppDelegate.swift             # Owns status item, popover, AppState, OverlayWindowManager
├── AppState.swift                # @MainActor ObservableObject — every persisted/transient state field
├── Models/
│   ├── PaperSettings.swift       # UserDefaults keys, default values, value ranges, clamp helper
│   └── PaperPreset.swift         # Six preset structs + PaperTextureStyle enum + NSColor(hex:) extension
├── Overlay/
│   ├── PaperOverlayPanel.swift   # NSPanel subclass — borderless, click-through, covers all spaces
│   ├── OverlayWindowManager.swift # Creates/syncs/destroys one PaperOverlayPanel per NSScreen
│   ├── OverlayView.swift         # SwiftUI view: tint layer + tiled texture + vignette radial gradient
│   └── PaperTextureFactory.swift # CoreGraphics texture generator (512×512, seeded RNG, in-memory cache)
└── UI/
    ├── SettingsPopoverView.swift  # Root of the 460×680 popover — all sections composed here
    ├── PresetCard.swift           # Tappable card: MiniPaperPreview + name + description + selection ring
    ├── MiniPaperPreview.swift     # 50pt-tall gradient rectangle with inline Canvas texture hint
    └── PaperSlider.swift          # Row: icon badge + title + Slider(0…1) + percentage badge
```

---

## Architecture

### Entry Point

`PaperScreenApp` uses `@NSApplicationDelegateAdaptor(AppDelegate.self)` so `AppDelegate` owns all lifecycle. The `body` is `Settings { EmptyView() }` — this satisfies the SwiftUI `App` protocol without opening any window.

### AppDelegate Responsibilities

- Sets `NSApp.activationPolicy(.accessory)` (hides Dock icon before `LSUIElement` takes effect at relaunch).
- Creates the single `AppState` instance.
- Creates `OverlayWindowManager(appState:)` and calls `.start()`.
- Creates the `NSStatusItem` with SF Symbol `doc.text` / `doc.text.fill` / `pause.circle`.
- Creates the `NSPopover` (`.behavior = .transient`, size 460×680) hosting `SettingsPopoverView`.
- Subscribes to `appState.objectWillChange` to update the status item icon and tooltip.
- `quit()` closes the popover, stops the overlay manager, calls `NSApp.terminate(nil)`.

### AppState

`@MainActor final class AppState: ObservableObject`

All `@Published` properties write back to `UserDefaults` in their `didSet`. Numeric properties (intensity, textureStrength, warmth, vignetteStrength) also clamp in `didSet` using the guard pattern below to avoid recursion:

```swift
let clamped = PaperSettings.clamp(value, in: range)
if clamped != value { self.property = clamped; return }
UserDefaults.standard.set(value, forKey: key)
```

**Persisted properties**

| Property | Type | Default | UserDefaults key |
|---|---|---|---|
| `isEnabled` | `Bool` | `true` | `"isEnabled"` |
| `selectedPresetID` | `String` | `"writingPaper"` | `"selectedPresetID"` |
| `intensity` | `Double` | `0.55` | `"intensity"` |
| `textureStrength` | `Double` | `0.45` | `"textureStrength"` |
| `warmth` | `Double` | `0.35` | `"warmth"` |
| `vignetteStrength` | `Double` | `0.5` | `"vignetteStrength"` |
| `reduceEffectInDarkMode` | `Bool` | `true` | `"reduceEffectInDarkMode"` |
| `useHighCoverageLevel` | `Bool` | `false` | `"useHighCoverageLevel"` |
| `launchAtLogin` | `Bool` | SMAppService query | `"launchAtLogin"` |

**Transient properties** (never persisted, reset on launch)

| Property | Purpose |
|---|---|
| `isComparingOriginal` | Temporarily bypasses the effect while Compare toggle is on |
| `pauseUntil: Date?` | Set when the user pauses; drives `isPaused` and `pauseRemainingText` |

**Computed properties**

- `selectedPreset` — looks up `PaperPreset.preset(id: selectedPresetID)`.
- `effectivePreset` — the preset actually rendered; returns `.original` when `isEnabled == false`, `isPaused == true`, `isComparingOriginal == true`, or `selectedPresetID == "original"`. Overlays only read this.
- `isPaused` — `pauseUntil != nil && pauseUntil! > Date()`.
- `pauseRemainingText` — `"Xm left"` / `"Xs left"` string for UI and tooltip.

**Key methods**

| Method | Effect |
|---|---|
| `selectPreset(_:)` | Sets `selectedPresetID` |
| `resetCurrentPresetControls()` | Resets intensity/texture/warmth/vignette to defaults; sets texture to 0 if preset has no texture |
| `applyNightComfort()` | Switches to writingPaper, intensity 0.75, warmth 0.65, texture 0.35, vignette 0.4, reduceInDark true |
| `setLaunchAtLogin(_:)` | Calls `SMAppService.mainApp.register/unregister`, then updates `launchAtLogin` only on success |
| `pause(for:)` | Sets `pauseUntil` and starts a one-shot `Timer` to call `resumeNow()` |
| `resumeNow()` | Clears `pauseUntil` and invalidates the timer |

> **UserDefaults bool pitfall** — `UserDefaults.bool(forKey:)` returns `false` for missing keys, which would break defaults of `true`. Always use `ud.object(forKey:) as? Bool ?? defaultValue`.

---

### PaperPreset

`struct PaperPreset: Identifiable, Equatable` — identity is `id: String`.

**Six presets** defined as static `let` in an extension:

| ID | Name | Tint hex | Light opacity | Dark opacity | Texture style | Texture opacity | Vignette opacity |
|---|---|---|---|---|---|---|---|
| `original` | Original | clear | 0.00 | 0.00 | none | 0.00 | 0.00 |
| `writingPaper` | Writing Paper | `#FFFBEA` | 0.075 | 0.025 | fineGrain | 0.055 | 0.00 |
| `xuanPaper` | Xuan Paper | `#FFFEF8` | 0.060 | 0.020 | longFibers | 0.070 | 0.00 |
| `parchment` | Parchment | `#F3DCA5` | 0.115 | 0.035 | parchment | 0.075 | 0.28 |
| `frosted` | Frosted | `#FFFFFF` | 0.085 | 0.025 | frosted | 0.035 | 0.00 |
| `newsprint` | Newsprint | `#E9E2D5` | 0.095 | 0.030 | newsprint | 0.105 | 0.18 |

`previewA` / `previewB` are used by `MiniPaperPreview` for the gradient; they are not the overlay tint.

`PaperPreset.all` is `[.original, .writingPaper, .xuanPaper, .parchment, .frosted, .newsprint]`.

`PaperPreset.preset(id:)` returns the matching preset or `.original` as fallback.

`NSColor(hex:)` convenience initializer is defined in this file (sRGB color space).

---

### Overlay System

#### PaperOverlayPanel

`final class PaperOverlayPanel: NSPanel`

Critical configuration:
- `canBecomeKey` / `canBecomeMain` → `false`
- `styleMask`: `[.borderless, .nonactivatingPanel]`
- `ignoresMouseEvents = true`
- `hidesOnDeactivate = false`
- `isReleasedWhenClosed = false`
- `collectionBehavior`: `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`

Two window levels controlled by `setHighCoverageLevel(_:)`:
- Normal: `.statusBar`
- High (covers fullscreen Spaces): `NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))`

#### OverlayWindowManager

`@MainActor final class OverlayWindowManager`

Maintains `panels: [String: PaperOverlayPanel]` keyed by screen identity string:
```
"\(screen.localizedName)-\(frame.origin.x)-\(frame.origin.y)-\(frame.width)-\(frame.height)"
```

This key changes when display layout changes, so `syncScreens()` naturally recreates affected panels.

**Lifecycle**

`start()`:
1. Calls `syncScreens()`.
2. Observes `NSApplication.didChangeScreenParametersNotification` → `syncScreens()`.
3. Observes `NSWorkspace.activeSpaceDidChangeNotification` → `updatePanelFrames()`.
4. Subscribes to `appState.$useHighCoverageLevel` (Combine) → `updatePanelLevels(_:)`.

`stop()`: removes all observers, removes all Combine subscriptions, closes all panels.

`syncScreens()`: closes panels for removed screens, creates panels for new screens, calls `updatePanelFrames()`.

`makePanel(for:)`: wraps `OverlayView(appState:)` in `NSHostingView`, sets `.autoresizingMask = [.width, .height]`.

`updatePanelFrames()`: sets each panel's frame to `screen.frame`, calls `orderFrontRegardless()`.

`updatePanelLevels(_:)`: calls `setHighCoverageLevel(_:)` on every panel, then `orderFrontRegardless()`.

> `OverlayWindowManager` does NOT observe settings changes directly. Because each panel hosts a SwiftUI `OverlayView(@ObservedObject appState)`, SwiftUI re-renders automatically whenever `AppState` publishes. Only structural changes (screen add/remove, window level) need explicit handling in the manager.

#### OverlayView

`struct OverlayView: View` — renders `Color.clear` when `effectivePreset.id == "original"`, otherwise a `ZStack` of three layers:

**Layer 1 — tint**
```
Color(nsColor: adjustedTint).opacity(baseOpacity)
```
`adjustedTint` blends the preset tint toward `NSColor(srgbRed:1.0, green:0.93, blue:0.78)` by `warmth * 0.4`.

`baseOpacity` calculation:
1. Choose `preset.lightOpacity` or `preset.darkOpacity` based on `colorScheme`.
2. If dark mode and `reduceEffectInDarkMode`, multiply by `0.65`.
3. Multiply by `0.25 + intensity * 1.25`.

**Layer 2 — texture** (skipped if `PaperTextureFactory.texture(for:)` returns `nil`)
```
Image(nsImage: texture).resizable(resizingMode: .tile).opacity(textureOpacity)
```
`textureOpacity = preset.textureOpacity * textureStrength * (darkModeReduction ? 0.55 : 1)`.

**Layer 3 — vignette** (skipped when opacity ≤ 0.001)
```swift
RadialGradient(
    colors: [.clear, .black.opacity(vignetteOpacity)],
    center: .center, startRadius: 200, endRadius: 1200
).blendMode(.multiply)
```
`vignetteOpacity = preset.vignetteOpacity * vignetteStrength * intensity`.

The entire `ZStack` has `.compositingGroup()`, `.allowsHitTesting(false)`, `.accessibilityHidden(true)`.

> Blend modes in `OverlayView` only affect layers inside the overlay. They do not blend with pixels beneath the window — that requires screen recording, which this app intentionally avoids.

---

### Texture System

#### PaperTextureFactory

`enum PaperTextureFactory` — static methods only.

In-memory cache: `private static var cache: [PaperTextureStyle: NSImage] = [:]`.

`texture(for:)` returns `nil` for `.none`, checks cache, calls `generate(style:)` on miss.

`generate(style:)`:
- Creates a 512×512 `CGContext` (premultiplied RGBA, sRGB).
- Initialises `SeededRNG` with a hardcoded seed per style.
- Dispatches to a `draw*` function.
- Returns `NSImage(cgImage:size:)`.

| Style | Draw technique | Approximate element count |
|---|---|---|
| `fineGrain` | 6,000 tiny warm-toned ellipses, radius 0.2–1.0, alpha 0.01–0.07 | dots |
| `longFibers` | 200 near-vertical strokes length 40–120px + 80 short random strokes | lines |
| `parchment` | 60 warm mottled ellipses + 120 short fiber strokes + 3,000 fine dots | mixed |
| `frosted` | 8,000 gray-white ellipses radius 0.3–1.5, very low alpha | dots |
| `newsprint` | 5,000 gray dots + 150 short strokes + 200 small elongated marks | mixed |

`SeededRNG` (private struct, xorshift64) produces deterministic sequences so textures are identical across launches.

`MiniRNG` (identical algorithm, defined in `MiniPaperPreview.swift`) drives the preview canvas with different seeds.

---

### UI Layer

#### SettingsPopoverView (460×680)

Root `ZStack`: paper-toned `LinearGradient` + `RadialGradient` highlight + `Canvas` grain dots, then a `ScrollView` with sections:

| Section | Content |
|---|---|
| **Header** | App icon badge, title, preset description, enabled toggle in a frosted card |
| **Comfort Status** | `effectivePreset` name, status detail text, "Fullscreen" badge when `useHighCoverageLevel` |
| **Preset Grid** | `LazyVGrid` 2-column of `PresetCard`; disabled + dimmed when `!isEnabled` |
| **Surface Tuning** | Four `PaperSlider`s (Intensity, Texture, Warmth, Edges); disabled when off or Original selected |
| **Quick Actions** | 2-column grid: Night / Pause-20m / Reset / Compare — all `PaperActionButtonStyle` |
| **Footer** | Three `Toggle`s (Reduce in Dark, Launch at Login, Cover Fullscreen Spaces); privacy label; Quit button |

Private helpers defined at the bottom of the file:
- `PaperCardModifier` — white semi-transparent fill + white stroke border + drop shadow; applied via `.paperCard(cornerRadius:)` extension.
- `PaperActionButtonStyle` — `.primary` (warm brown gradient, white text) or `.secondary` (white fill, brown text); 0.98 scale on press.

**Launch at Login binding** — uses a manual `Binding` to route through `setLaunchAtLogin(_:)` rather than binding directly to `$appState.launchAtLogin`, to prevent `SMAppService` being called during state init:
```swift
Binding(
    get: { appState.launchAtLogin },
    set: { appState.setLaunchAtLogin($0) }
)
```

#### PresetCard

- `@State private var isHovering` drives 1.012 scale, brighter card fill, brighter border.
- Selected state: `#FFF8EA` fill, `#7A572F` 2pt border, checkmark badge top-right.
- `.animation(.easeOut(duration: 0.14))` on both hover and selection.

#### PaperSlider

- Icon in a circular tinted badge (14% opacity fill, full-opacity icon).
- Percentage display in monospaced font inside a white capsule.
- `Slider(value:in:)` tinted to `tint: NSColor`.

#### MiniPaperPreview

- 50pt-tall `RoundedRectangle` with `previewA → previewB` gradient.
- `Canvas` overlay draws a lightweight version of the texture style (32–64 elements max) using `MiniRNG`.
- White 65%-opacity stroke border overlay.

---

## Build

```sh
xcodebuild -project PaperScreen.xcodeproj -scheme PaperScreen -configuration Debug build
```

No Swift Package Manager, no CocoaPods, no Carthage. No external assets. Project uses Xcode file-system synchronized groups — new `.swift` files under `PaperScreen/` are included automatically.

Build settings of note:
- `GENERATE_INFOPLIST_FILE = YES` — no manual Info.plist
- `INFOPLIST_KEY_LSUIElement = YES` — hides Dock icon permanently (takes effect at next cold launch)
- `ENABLE_APP_SANDBOX = YES` — keep enabled; do not remove
- `ENABLE_HARDENED_RUNTIME = YES`

---

## Hard Constraints

| Constraint | Reason |
|---|---|
| No `ScreenCaptureKit` | App must never request Screen Recording permission |
| No `AXUIElement` / Accessibility | App must never request Accessibility permission |
| Sandbox stays on | Required; do not remove `ENABLE_APP_SANDBOX` |
| No pixel-aware rendering | Transparent overlay cannot read underlying pixels without screen capture |
| `setLaunchAtLogin(_:)` must not be called from init | Would register/unregister the login item when loading persisted settings |
| `UserDefaults.bool(forKey:)` must not be used for Bool defaults of `true` | Returns `false` for missing key — use `object(forKey:) as? Bool ?? default` |
| Clamp guard pattern in `didSet` | Direct recursive assignment in `didSet` causes infinite recursion — compare before re-assigning |

---

## Common Pitfalls and Fixes

**Overlay blocks mouse clicks**
- Check `ignoresMouseEvents = true` on the panel.
- Check `canBecomeKey` and `canBecomeMain` return `false`.
- Verify style mask includes `.nonactivatingPanel`.

**Overlay does not cover fullscreen Spaces**
- Toggle `useHighCoverageLevel = true` in AppState; this switches to `CGWindowLevelForKey(.screenSaverWindow)`.
- Verify `collectionBehavior` includes `.canJoinAllSpaces` and `.fullScreenAuxiliary`.

**App shows Dock icon**
- `NSApp.setActivationPolicy(.accessory)` must be called in `applicationDidFinishLaunching`.
- `INFOPLIST_KEY_LSUIElement = YES` hides it on cold launch; the activation policy call covers the current run.

**Textures change appearance across launches**
- `PaperTextureFactory` and `MiniRNG` both use fixed hardcoded seeds; never pass `0` as a seed (protected by `seed == 0 ? 1 : seed`).

**New Swift files not compiling**
- The project uses synchronized group references. If Xcode doesn't pick up a new file automatically, inspect `.pbxproj` and add a minimal file reference entry.

---

## Manual QA Checklist

- App appears in menu bar; no Dock icon (requires cold relaunch after `LSUIElement` is set).
- Popover opens and closes from the status item.
- Enabled toggle immediately shows/hides the overlay.
- All six presets visibly change every display.
- Original preset removes all tint and texture.
- Mouse clicks pass through the overlay to apps underneath.
- Keyboard focus stays in underlying apps.
- Overlay covers all connected displays.
- Unplugging/replugging a display removes stale panels and creates new ones.
- Pause 20m button hides the effect; Resume restores it.
- Compare toggle temporarily shows original while held.
- Night Comfort applies the correct warm preset values.
- Reset restores default slider values for the current preset.
- Launch at Login registers correctly (verify in System Settings → General → Login Items).
- Cover Fullscreen Spaces toggle makes the overlay visible inside fullscreen Mission Control spaces.
- Settings persist after Force Quit and relaunch.
- Idle CPU usage near zero.
- No Screen Recording or Accessibility permission dialogs ever appear.

import SwiftUI
import AppKit

struct OverlayView: View {
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    private var preset: PaperPreset { appState.effectivePreset }

    private var baseOpacity: Double {
        let raw = isDark ? preset.darkOpacity : preset.lightOpacity
        let reduced = (isDark && appState.reduceEffectInDarkMode) ? raw * 0.55 : raw
        let maximum = isDark ? 0.08 : 0.22
        return min(reduced * appState.intensity, maximum)
    }

    private var textureOpacity: Double {
        let raw = preset.textureOpacity * appState.intensity
        let reduced = (isDark && appState.reduceEffectInDarkMode) ? raw * 0.55 : raw
        return min(reduced, isDark ? 0.10 : 0.20)
    }

    private var vignetteOpacity: Double {
        min(preset.vignetteOpacity * appState.intensity, 0.35)
    }

    private var adjustedTint: NSColor {
        blendedTint(base: preset.tint, warmth: preset.warmthBlend)
    }

    var body: some View {
        if preset.id == "original" {
            Color.clear.ignoresSafeArea()
        } else {
            ZStack {
                Color(nsColor: adjustedTint)
                    .opacity(baseOpacity)
                    .ignoresSafeArea()

                if let texture = PaperTextureFactory.texture(for: preset.textureStyle) {
                    Image(nsImage: texture)
                        .resizable(resizingMode: .tile)
                        .opacity(textureOpacity)
                        .ignoresSafeArea()
                }

                if vignetteOpacity > 0.001 {
                    RadialGradient(
                        colors: [.clear, .black.opacity(vignetteOpacity)],
                        center: .center,
                        startRadius: 200,
                        endRadius: 1200
                    )
                    .blendMode(.multiply)
                    .ignoresSafeArea()
                }
            }
            .compositingGroup()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func blendedTint(base: NSColor, warmth: Double) -> NSColor {
        guard warmth > 0 else { return base }
        let warm = NSColor(srgbRed: 1.0, green: 0.93, blue: 0.78, alpha: 1.0)
        guard
            let baseConverted = base.usingColorSpace(.sRGB),
            let warmConverted = warm.usingColorSpace(.sRGB)
        else { return base }
        let t = warmth * 0.4
        return NSColor(
            srgbRed: baseConverted.redComponent + (warmConverted.redComponent - baseConverted.redComponent) * t,
            green: baseConverted.greenComponent + (warmConverted.greenComponent - baseConverted.greenComponent) * t,
            blue: baseConverted.blueComponent + (warmConverted.blueComponent - baseConverted.blueComponent) * t,
            alpha: 1.0
        )
    }
}

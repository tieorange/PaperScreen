import SwiftUI
import AppKit

struct SettingsPopoverView: View {
    @ObservedObject var appState: AppState
    let onQuit: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let actionColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            background

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    comfortStatus
                    presetSection
                    controlsSection
                    quickActions
                    footer
                }
                .padding(18)
            }
        }
        .frame(width: 460, height: 680)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: NSColor(hex: "#FFF9EA")),
                    Color(nsColor: NSColor(hex: "#F4EAD8")),
                    Color(nsColor: NSColor(hex: "#EEE3D0"))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.white.opacity(0.75), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 360
            )

            Canvas { context, size in
                var rng = MiniRNG(seed: 98_172)
                for _ in 0..<180 {
                    let x = rng.nextDouble() * size.width
                    let y = rng.nextDouble() * size.height
                    let r = rng.nextDouble() * 0.9 + 0.2
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                        with: .color(.black.opacity(0.025))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(nsColor: NSColor(hex: "#8B6A3E")), Color(nsColor: NSColor(hex: "#C7A46A"))],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
                .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 6)

                VStack(alignment: .leading, spacing: 3) {
                    Text("PaperScreen")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(nsColor: NSColor(hex: "#2F271E")))
                    Text(appState.selectedPreset.name == "Original" ? "Display untouched" : appState.selectedPreset.description)
                        .font(.callout)
                        .foregroundStyle(Color(nsColor: NSColor(hex: "#756756")))
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Label(statusText, systemImage: statusSymbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)

                Spacer()

                Toggle("", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(12)
            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.72), lineWidth: 1)
            )
        }
        .padding(16)
        .paperCard(cornerRadius: 26)
    }

    private var comfortStatus: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.effectivePreset.id == "original" ? "Original Display" : appState.effectivePreset.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#33281E")))
                Text(statusDetail)
                    .font(.caption)
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#806F5E")))
            }

            Spacer()

            if appState.useHighCoverageLevel {
                Label("Fullscreen", systemImage: "rectangle.inset.filled")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#6E5636")))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: NSColor(hex: "#F1DFC0")), in: Capsule())
            }
        }
        .padding(14)
        .paperCard(cornerRadius: 20)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Paper Styles", subtitle: "Choose the surface that fits this moment.")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(PaperPreset.all) { preset in
                    PresetCard(
                        preset: preset,
                        isSelected: appState.selectedPresetID == preset.id
                    ) {
                        appState.selectPreset(preset)
                    }
                }
            }
            .disabled(!appState.isEnabled)
            .opacity(appState.isEnabled ? 1 : 0.58)
        }
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Surface Tuning", subtitle: "Small adjustments keep the effect comfortable.")

            VStack(spacing: 12) {
                PaperSlider(title: "Intensity", value: $appState.intensity, systemImage: "sun.max.fill", tint: NSColor(hex: "#B47A32"))
                PaperSlider(title: "Texture", value: $appState.textureStrength, systemImage: "circle.grid.cross.fill", tint: NSColor(hex: "#7B6B4B"))
                PaperSlider(title: "Warmth", value: $appState.warmth, systemImage: "thermometer.sun.fill", tint: NSColor(hex: "#C06A36"))
                PaperSlider(title: "Edges", value: $appState.vignetteStrength, systemImage: "rectangle.dashed", tint: NSColor(hex: "#6F604A"))
            }
            .padding(14)
            .paperCard(cornerRadius: 22)
            .disabled(!appState.isEnabled || appState.selectedPresetID == "original")
            .opacity((appState.isEnabled && appState.selectedPresetID != "original") ? 1 : 0.52)
        }
    }

    private var quickActions: some View {
        LazyVGrid(columns: actionColumns, spacing: 10) {
            Button {
                appState.applyNightComfort()
            } label: {
                Label("Night", systemImage: "moon.stars.fill")
            }
            .buttonStyle(PaperActionButtonStyle(kind: .primary))

            Button {
                if appState.isPaused {
                    appState.resumeNow()
                } else {
                    appState.pause(for: 20)
                }
            } label: {
                Label(appState.isPaused ? "Resume" : "Pause 20m", systemImage: appState.isPaused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(PaperActionButtonStyle(kind: appState.isPaused ? .primary : .secondary))

            Button {
                appState.resetCurrentPresetControls()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(PaperActionButtonStyle(kind: .secondary))

            Toggle(isOn: $appState.isComparingOriginal) {
                Label("Compare", systemImage: "rectangle.on.rectangle")
            }
            .toggleStyle(.button)
            .buttonStyle(PaperActionButtonStyle(kind: appState.isComparingOriginal ? .primary : .secondary))
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                Toggle(isOn: $appState.reduceEffectInDarkMode) {
                    Label("Reduce effect in Dark Mode", systemImage: "circle.lefthalf.filled")
                }

                Toggle(isOn: Binding(
                    get: { appState.launchAtLogin },
                    set: { appState.setLaunchAtLogin($0) }
                )) {
                    Label("Launch at Login", systemImage: "power")
                }

                Toggle(isOn: $appState.useHighCoverageLevel) {
                    Label("Cover fullscreen Spaces", systemImage: "rectangle.inset.filled")
                }
            }
            .toggleStyle(.switch)
            .font(.subheadline)
            .padding(14)
            .paperCard(cornerRadius: 20)

            HStack {
                Label("No screen recording. Local settings only.", systemImage: "lock.shield.fill")
                    .font(.caption2)
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#827363")))
                Spacer()
                Button("Quit", action: onQuit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#7D5A33")))
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(nsColor: NSColor(hex: "#352B20")))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color(nsColor: NSColor(hex: "#847363")))
        }
        .padding(.horizontal, 2)
    }

    private var statusText: String {
        if !appState.isEnabled { return "Effect paused" }
        if appState.isPaused { return "Temporarily paused" }
        if appState.selectedPresetID == "original" { return "Original display" }
        return "Paper effect active"
    }

    private var statusDetail: String {
        if !appState.isEnabled { return "Turn the switch back on when you want a softer screen." }
        if appState.isPaused {
            return "Paused for color checks\(appState.pauseRemainingText.map { ", \($0)" } ?? "")."
        }
        if appState.selectedPresetID == "original" { return "No tint or texture is currently applied." }
        return "Tone, texture, and edges are being applied across your displays."
    }

    private var statusSymbol: String {
        if !appState.isEnabled || appState.selectedPresetID == "original" { return "eye.slash.fill" }
        if appState.isPaused { return "pause.circle.fill" }
        return "eye.fill"
    }

    private var statusColor: Color {
        if !appState.isEnabled || appState.selectedPresetID == "original" { return .secondary }
        if appState.isPaused { return Color(nsColor: NSColor(hex: "#8C6538")) }
        return Color(nsColor: NSColor(hex: "#4F6933"))
    }
}

private struct PaperCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white.opacity(0.58))
                    .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.72), lineWidth: 1)
            )
    }
}

private extension View {
    func paperCard(cornerRadius: CGFloat) -> some View {
        modifier(PaperCardModifier(cornerRadius: cornerRadius))
    }
}

private struct PaperActionButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(kind == .primary ? .white : Color(nsColor: NSColor(hex: "#594633")))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(kind == .primary ? .clear : Color(nsColor: NSColor(hex: "#D8C9B2")), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(nsColor: NSColor(hex: "#7B5A35")), Color(nsColor: NSColor(hex: "#B7894F"))],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(Color.white.opacity(0.58))
        }
    }
}

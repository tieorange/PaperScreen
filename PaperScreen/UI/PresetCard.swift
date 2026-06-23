import SwiftUI

struct PresetCard: View {
    let preset: PaperPreset
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                ZStack(alignment: .topTrailing) {
                    MiniPaperPreview(preset: preset)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(nsColor: NSColor(hex: "#7A572F")))
                            .background(Circle().fill(.white.opacity(0.86)))
                            .padding(7)
                    }
                }

                Text(preset.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#34291F")))

                Text(preset.description)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#766959")))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 136)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardFill)
                    .shadow(color: isSelected ? Color(nsColor: NSColor(hex: "#7A572F")).opacity(0.22) : .black.opacity(0.05), radius: isSelected ? 12 : 8, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color(nsColor: NSColor(hex: "#7A572F")) : Color.white.opacity(isHovering ? 0.95 : 0.58),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .scaleEffect(isHovering ? 1.012 : 1)
        .animation(.easeOut(duration: 0.14), value: isHovering)
        .animation(.easeOut(duration: 0.14), value: isSelected)
    }

    private var cardFill: Color {
        if isSelected {
            return Color(nsColor: NSColor(hex: "#FFF8EA"))
        }
        if isHovering {
            return Color.white.opacity(0.72)
        }
        return Color.white.opacity(0.48)
    }
}

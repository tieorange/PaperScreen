import SwiftUI
import AppKit

struct PaperSlider: View {
    let title: String
    @Binding var value: Double
    let systemImage: String
    let tint: NSColor

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(Color(nsColor: tint).opacity(0.14))
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(nsColor: tint))
                }
                .frame(width: 24, height: 24)

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#3C3126")))

                Spacer()

                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(nsColor: NSColor(hex: "#7A6A58")))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.54), in: Capsule())
            }

            Slider(value: $value, in: 0...1)
                .tint(Color(nsColor: tint))
        }
    }
}

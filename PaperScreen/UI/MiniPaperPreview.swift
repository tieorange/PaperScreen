import SwiftUI
import AppKit

struct MiniPaperPreview: View {
    let preset: PaperPreset

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [Color(nsColor: preset.previewA), Color(nsColor: preset.previewB)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Canvas { context, size in
                    guard preset.textureStyle != .none else { return }
                    var rng = MiniRNG(seed: seed(for: preset.textureStyle))
                    drawTexture(style: preset.textureStyle, context: context, size: size, rng: &rng)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.white.opacity(0.65), lineWidth: 1)
            )
            .frame(height: 50)
    }

    private func seed(for style: PaperTextureStyle) -> UInt64 {
        switch style {
        case .none: return 1
        case .fineGrain: return 12_347
        case .longFibers: return 23_451
        case .parchment: return 34_567
        case .frosted: return 45_671
        case .newsprint: return 56_789
        case .cotton: return 67_890
        case .riceFibers: return 78_901
        case .mattePulp: return 89_012
        }
    }

    private func drawTexture(style: PaperTextureStyle, context: GraphicsContext, size: CGSize, rng: inout MiniRNG) {
        let count: Int
        switch style {
        case .none: count = 0
        case .fineGrain: count = 46
        case .longFibers: count = 24
        case .parchment: count = 38
        case .frosted: count = 32
        case .newsprint: count = 64
        case .cotton: count = 44
        case .riceFibers: count = 48
        case .mattePulp: count = 50
        }

        for index in 0..<count {
            let x = rng.nextDouble() * size.width
            let y = rng.nextDouble() * size.height

            if style == .longFibers || style == .riceFibers || (style == .parchment && index % 3 == 0) || (style == .cotton && index % 5 == 0) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                let length = style == .riceFibers ? 38.0 : 28.0
                path.addLine(to: CGPoint(x: x + rng.nextDouble() * length - 8, y: y + rng.nextDouble() * 12 - 6))
                context.stroke(path, with: .color(.black.opacity(style == .riceFibers ? 0.07 : 0.052)), lineWidth: 0.45)
            } else {
                let r = rng.nextDouble() * ((style == .newsprint || style == .mattePulp) ? 1.4 : 1.0) + 0.25
                context.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .color(.black.opacity((style == .newsprint || style == .mattePulp) ? 0.07 : 0.045))
                )
            }
        }
    }
}

struct MiniRNG {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
    }
    mutating func nextDouble() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

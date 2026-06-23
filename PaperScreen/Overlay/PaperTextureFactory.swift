import AppKit

enum PaperTextureFactory {
    private static var cache: [PaperTextureStyle: NSImage] = [:]

    static func texture(for style: PaperTextureStyle) -> NSImage? {
        if style == .none { return nil }
        if let cached = cache[style] { return cached }
        guard let image = generate(style: style) else { return nil }
        cache[style] = image
        return image
    }

    private static func generate(style: PaperTextureStyle) -> NSImage? {
        let size = 512
        let bytesPerRow = size * 4
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.clear(CGRect(x: 0, y: 0, width: size, height: size))

        var rng = SeededRNG(seed: seedValue(for: style))

        switch style {
        case .none:
            return nil
        case .fineGrain:
            drawFineGrain(in: context, size: size, rng: &rng)
        case .longFibers:
            drawLongFibers(in: context, size: size, rng: &rng)
        case .parchment:
            drawParchment(in: context, size: size, rng: &rng)
        case .frosted:
            drawFrosted(in: context, size: size, rng: &rng)
        case .newsprint:
            drawNewsprint(in: context, size: size, rng: &rng)
        }

        guard let cgImage = context.makeImage() else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }

    private static func seedValue(for style: PaperTextureStyle) -> UInt64 {
        switch style {
        case .none: return 0
        case .fineGrain: return 1_234_567
        case .longFibers: return 2_345_678
        case .parchment: return 3_456_789
        case .frosted: return 4_567_890
        case .newsprint: return 5_678_901
        }
    }

    private static func drawFineGrain(in ctx: CGContext, size: Int, rng: inout SeededRNG) {
        for _ in 0..<6000 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let radius = rng.nextDouble() * 0.8 + 0.2
            let alpha = rng.nextDouble() * 0.06 + 0.01
            let warm = rng.nextDouble() * 0.1
            ctx.setFillColor(NSColor(srgbRed: 0.5 + warm, green: 0.4 + warm * 0.5, blue: 0.3, alpha: alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
    }

    private static func drawLongFibers(in ctx: CGContext, size: Int, rng: inout SeededRNG) {
        ctx.setLineWidth(0.4)
        for _ in 0..<200 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let angle = (rng.nextDouble() - 0.5) * 0.3 + .pi / 2
            let length = rng.nextDouble() * 80 + 40
            let alpha = rng.nextDouble() * 0.05 + 0.01
            ctx.setStrokeColor(NSColor(srgbRed: 0.55, green: 0.48, blue: 0.38, alpha: alpha).cgColor)
            ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(
                x: x + cos(angle) * length,
                y: y + sin(angle) * length
            ))
            ctx.strokePath()
        }
        for _ in 0..<80 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let angle = rng.nextDouble() * .pi
            let length = rng.nextDouble() * 20 + 5
            let alpha = rng.nextDouble() * 0.04 + 0.01
            ctx.setLineWidth(0.3)
            ctx.setStrokeColor(NSColor(srgbRed: 0.5, green: 0.44, blue: 0.35, alpha: alpha).cgColor)
            ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x + cos(angle) * length, y: y + sin(angle) * length))
            ctx.strokePath()
        }
    }

    private static func drawParchment(in ctx: CGContext, size: Int, rng: inout SeededRNG) {
        for _ in 0..<60 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let rx = rng.nextDouble() * 30 + 10
            let ry = rng.nextDouble() * 20 + 8
            let alpha = rng.nextDouble() * 0.04 + 0.005
            let warm = rng.nextDouble() * 0.15
            ctx.setFillColor(NSColor(srgbRed: 0.72 + warm, green: 0.58 + warm * 0.5, blue: 0.38, alpha: alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
        }
        ctx.setLineWidth(0.35)
        for _ in 0..<120 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let angle = rng.nextDouble() * .pi
            let length = rng.nextDouble() * 25 + 5
            let alpha = rng.nextDouble() * 0.035 + 0.005
            ctx.setStrokeColor(NSColor(srgbRed: 0.6, green: 0.45, blue: 0.28, alpha: alpha).cgColor)
            ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x + cos(angle) * length, y: y + sin(angle) * length))
            ctx.strokePath()
        }
        for _ in 0..<3000 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let r = rng.nextDouble() * 0.6 + 0.2
            let alpha = rng.nextDouble() * 0.03 + 0.005
            ctx.setFillColor(NSColor(srgbRed: 0.65, green: 0.52, blue: 0.35, alpha: alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
    }

    private static func drawFrosted(in ctx: CGContext, size: Int, rng: inout SeededRNG) {
        for _ in 0..<8000 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let r = rng.nextDouble() * 1.2 + 0.3
            let alpha = rng.nextDouble() * 0.03 + 0.005
            let brightness = rng.nextDouble() * 0.2 + 0.8
            ctx.setFillColor(NSColor(srgbRed: brightness, green: brightness, blue: brightness + 0.02, alpha: alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
    }

    private static func drawNewsprint(in ctx: CGContext, size: Int, rng: inout SeededRNG) {
        for _ in 0..<5000 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let r = rng.nextDouble() * 0.9 + 0.2
            let alpha = rng.nextDouble() * 0.07 + 0.01
            let gray = rng.nextDouble() * 0.3 + 0.3
            ctx.setFillColor(NSColor(srgbRed: gray, green: gray, blue: gray, alpha: alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        ctx.setLineWidth(0.4)
        for _ in 0..<150 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let angle = rng.nextDouble() * .pi
            let length = rng.nextDouble() * 12 + 3
            let alpha = rng.nextDouble() * 0.06 + 0.01
            ctx.setStrokeColor(NSColor(srgbRed: 0.3, green: 0.3, blue: 0.3, alpha: alpha).cgColor)
            ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x + cos(angle) * length, y: y + sin(angle) * length))
            ctx.strokePath()
        }
        for _ in 0..<200 {
            let x = rng.nextDouble() * Double(size)
            let y = rng.nextDouble() * Double(size)
            let w = rng.nextDouble() * 3 + 1
            let h = rng.nextDouble() * 1.5 + 0.5
            let alpha = rng.nextDouble() * 0.05 + 0.005
            ctx.setFillColor(NSColor(srgbRed: 0.25, green: 0.25, blue: 0.25, alpha: alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: w, height: h))
        }
    }
}

private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}

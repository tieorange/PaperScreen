import AppKit

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

    static func == (lhs: PaperPreset, rhs: PaperPreset) -> Bool {
        lhs.id == rhs.id
    }
}

extension PaperPreset {
    static let original = PaperPreset(
        id: "original",
        name: "Original",
        description: "No overlay. Full display as-is.",
        tint: .clear,
        lightOpacity: 0.00,
        darkOpacity: 0.00,
        textureStyle: .none,
        textureOpacity: 0.00,
        vignetteOpacity: 0.00,
        previewA: NSColor(hex: "#FFFFFF"),
        previewB: NSColor(hex: "#F0F0F0")
    )

    static let writingPaper = PaperPreset(
        id: "writingPaper",
        name: "Writing Paper",
        description: "Warm cream tone with fine grain. Easy on the eyes.",
        tint: NSColor(hex: "#FFFBEA"),
        lightOpacity: 0.075,
        darkOpacity: 0.025,
        textureStyle: .fineGrain,
        textureOpacity: 0.055,
        vignetteOpacity: 0.00,
        previewA: NSColor(hex: "#FFFBEA"),
        previewB: NSColor(hex: "#FFF3C4")
    )

    static let xuanPaper = PaperPreset(
        id: "xuanPaper",
        name: "Xuan Paper",
        description: "Nearly white with subtle long fiber texture.",
        tint: NSColor(hex: "#FFFEF8"),
        lightOpacity: 0.060,
        darkOpacity: 0.020,
        textureStyle: .longFibers,
        textureOpacity: 0.070,
        vignetteOpacity: 0.00,
        previewA: NSColor(hex: "#FFFEF8"),
        previewB: NSColor(hex: "#F8F5E8")
    )

    static let parchment = PaperPreset(
        id: "parchment",
        name: "Parchment",
        description: "Aged amber tint with warm mottled texture and soft edges.",
        tint: NSColor(hex: "#F3DCA5"),
        lightOpacity: 0.115,
        darkOpacity: 0.035,
        textureStyle: .parchment,
        textureOpacity: 0.075,
        vignetteOpacity: 0.28,
        previewA: NSColor(hex: "#F3DCA5"),
        previewB: NSColor(hex: "#E8C87A")
    )

    static let frosted = PaperPreset(
        id: "frosted",
        name: "Frosted",
        description: "Cool white with soft frosted noise. Clean and bright.",
        tint: NSColor(hex: "#FFFFFF"),
        lightOpacity: 0.085,
        darkOpacity: 0.025,
        textureStyle: .frosted,
        textureOpacity: 0.035,
        vignetteOpacity: 0.00,
        previewA: NSColor(hex: "#FFFFFF"),
        previewB: NSColor(hex: "#F2F4F7")
    )

    static let newsprint = PaperPreset(
        id: "newsprint",
        name: "Newsprint",
        description: "Gray-toned with visible texture. Low-contrast reading feel.",
        tint: NSColor(hex: "#E9E2D5"),
        lightOpacity: 0.095,
        darkOpacity: 0.030,
        textureStyle: .newsprint,
        textureOpacity: 0.105,
        vignetteOpacity: 0.18,
        previewA: NSColor(hex: "#E9E2D5"),
        previewB: NSColor(hex: "#D8CFC0")
    )

    static let all: [PaperPreset] = [
        .original, .writingPaper, .xuanPaper, .parchment, .frosted, .newsprint
    ]

    static func preset(id: String) -> PaperPreset {
        all.first { $0.id == id } ?? .original
    }
}

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }
}

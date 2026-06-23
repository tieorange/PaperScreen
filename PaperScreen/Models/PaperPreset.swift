import AppKit

enum PaperTextureStyle: String, Codable, CaseIterable {
    case none
    case fineGrain
    case longFibers
    case parchment
    case frosted
    case newsprint
    case cotton
    case riceFibers
    case mattePulp
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
    let warmthBlend: Double
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
        warmthBlend: 0.00,
        previewA: NSColor(hex: "#FFFFFF"),
        previewB: NSColor(hex: "#F0F0F0")
    )

    static let writingPaper = PaperPreset(
        id: "writingPaper",
        name: "Writing Paper",
        description: "Clean cream paper for everyday reading and writing.",
        tint: NSColor(hex: "#FFF6DA"),
        lightOpacity: 0.095,
        darkOpacity: 0.030,
        textureStyle: .fineGrain,
        textureOpacity: 0.070,
        vignetteOpacity: 0.00,
        warmthBlend: 0.20,
        previewA: NSColor(hex: "#FFF6DA"),
        previewB: NSColor(hex: "#FFEAB7")
    )

    static let xuanPaper = PaperPreset(
        id: "xuanPaper",
        name: "Xuan Paper",
        description: "Airy handmade fibers with a light natural surface.",
        tint: NSColor(hex: "#FFFDF3"),
        lightOpacity: 0.075,
        darkOpacity: 0.024,
        textureStyle: .longFibers,
        textureOpacity: 0.090,
        vignetteOpacity: 0.00,
        warmthBlend: 0.10,
        previewA: NSColor(hex: "#FFFDF3"),
        previewB: NSColor(hex: "#F5EFD9")
    )

    static let parchment = PaperPreset(
        id: "parchment",
        name: "Parchment",
        description: "Aged amber tint with warm mottled texture and soft edges.",
        tint: NSColor(hex: "#F0D28A"),
        lightOpacity: 0.135,
        darkOpacity: 0.040,
        textureStyle: .parchment,
        textureOpacity: 0.090,
        vignetteOpacity: 0.220,
        warmthBlend: 0.35,
        previewA: NSColor(hex: "#F0D28A"),
        previewB: NSColor(hex: "#DBAC55")
    )

    static let frosted = PaperPreset(
        id: "frosted",
        name: "Frosted",
        description: "Soft matte diffusion for a calmer bright screen.",
        tint: NSColor(hex: "#FFFFFF"),
        lightOpacity: 0.105,
        darkOpacity: 0.030,
        textureStyle: .frosted,
        textureOpacity: 0.045,
        vignetteOpacity: 0.00,
        warmthBlend: 0.00,
        previewA: NSColor(hex: "#FFFFFF"),
        previewB: NSColor(hex: "#F2F4F7")
    )

    static let newsprint = PaperPreset(
        id: "newsprint",
        name: "Newsprint",
        description: "Gray pulp and printed-paper texture for low-glare reading.",
        tint: NSColor(hex: "#E5DDCE"),
        lightOpacity: 0.115,
        darkOpacity: 0.035,
        textureStyle: .newsprint,
        textureOpacity: 0.125,
        vignetteOpacity: 0.140,
        warmthBlend: 0.15,
        previewA: NSColor(hex: "#E5DDCE"),
        previewB: NSColor(hex: "#CFC4B3")
    )

    static let cottonPaper = PaperPreset(
        id: "cottonPaper",
        name: "Cotton Paper",
        description: "Premium soft white stationery with a calm cotton surface.",
        tint: NSColor(hex: "#FFFAEE"),
        lightOpacity: 0.085,
        darkOpacity: 0.026,
        textureStyle: .cotton,
        textureOpacity: 0.080,
        vignetteOpacity: 0.035,
        warmthBlend: 0.14,
        previewA: NSColor(hex: "#FFFAEE"),
        previewB: NSColor(hex: "#F4E6C8")
    )

    static let ricePaper = PaperPreset(
        id: "ricePaper",
        name: "Rice Paper",
        description: "Thin translucent paper with visible natural fibers.",
        tint: NSColor(hex: "#FFFCEF"),
        lightOpacity: 0.080,
        darkOpacity: 0.024,
        textureStyle: .riceFibers,
        textureOpacity: 0.105,
        vignetteOpacity: 0.000,
        warmthBlend: 0.12,
        previewA: NSColor(hex: "#FFFCEF"),
        previewB: NSColor(hex: "#EFE6C8")
    )

    static let cardstock = PaperPreset(
        id: "cardstock",
        name: "Cardstock",
        description: "Thick matte cream paper with a grounded low-glare feel.",
        tint: NSColor(hex: "#F7E9C8"),
        lightOpacity: 0.120,
        darkOpacity: 0.036,
        textureStyle: .mattePulp,
        textureOpacity: 0.060,
        vignetteOpacity: 0.080,
        warmthBlend: 0.28,
        previewA: NSColor(hex: "#F7E9C8"),
        previewB: NSColor(hex: "#E2C892")
    )

    static let all: [PaperPreset] = [
        .original, .writingPaper, .cottonPaper, .xuanPaper, .ricePaper, .parchment, .frosted, .cardstock, .newsprint
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

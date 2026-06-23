import Foundation

enum PaperSettings {
    enum Keys {
        static let isEnabled = "isEnabled"
        static let selectedPresetID = "selectedPresetID"
        static let intensity = "intensity"
        static let reduceEffectInDarkMode = "reduceEffectInDarkMode"
        static let useHighCoverageLevel = "useHighCoverageLevel"
        static let launchAtLogin = "launchAtLogin"
    }

    enum Defaults {
        static let isEnabled = true
        static let selectedPresetID = "writingPaper"
        static let intensity = 1.0
        static let reduceEffectInDarkMode = true
        static let useHighCoverageLevel = false
        static let launchAtLogin = false
    }

    enum Ranges {
        static let intensity: ClosedRange<Double> = 0...2
    }

    static func clamp(_ value: Double, in range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

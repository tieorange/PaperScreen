import Foundation
import Combine
import ServiceManagement

@MainActor
final class AppState: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: PaperSettings.Keys.isEnabled) }
    }

    @Published var selectedPresetID: String {
        didSet { UserDefaults.standard.set(selectedPresetID, forKey: PaperSettings.Keys.selectedPresetID) }
    }

    @Published var intensity: Double {
        didSet {
            let clamped = PaperSettings.clamp(intensity, in: PaperSettings.Ranges.intensity)
            if clamped != intensity { intensity = clamped; return }
            UserDefaults.standard.set(intensity, forKey: PaperSettings.Keys.intensity)
        }
    }

    @Published var reduceEffectInDarkMode: Bool {
        didSet { UserDefaults.standard.set(reduceEffectInDarkMode, forKey: PaperSettings.Keys.reduceEffectInDarkMode) }
    }

    @Published var useHighCoverageLevel: Bool {
        didSet { UserDefaults.standard.set(useHighCoverageLevel, forKey: PaperSettings.Keys.useHighCoverageLevel) }
    }

    @Published var launchAtLogin: Bool

    @Published var isComparingOriginal: Bool = false

    @Published var pauseUntil: Date?

    private var pauseTimer: Timer?

    var isPaused: Bool {
        guard let pauseUntil else { return false }
        return pauseUntil > Date()
    }

    var pauseRemainingText: String? {
        guard isPaused, let pauseUntil else { return nil }
        let remaining = max(0, Int(pauseUntil.timeIntervalSinceNow.rounded(.up)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        if minutes > 0 {
            return "\(minutes)m left"
        }
        return "\(seconds)s left"
    }

    var selectedPreset: PaperPreset {
        PaperPreset.preset(id: selectedPresetID)
    }

    var effectivePreset: PaperPreset {
        guard isEnabled, !isPaused, !isComparingOriginal, selectedPresetID != "original" else {
            return .original
        }
        return selectedPreset
    }

    init() {
        let ud = UserDefaults.standard
        isEnabled = ud.object(forKey: PaperSettings.Keys.isEnabled) as? Bool ?? PaperSettings.Defaults.isEnabled
        selectedPresetID = ud.string(forKey: PaperSettings.Keys.selectedPresetID) ?? PaperSettings.Defaults.selectedPresetID
        intensity = ud.object(forKey: PaperSettings.Keys.intensity) as? Double ?? PaperSettings.Defaults.intensity
        reduceEffectInDarkMode = ud.object(forKey: PaperSettings.Keys.reduceEffectInDarkMode) as? Bool ?? PaperSettings.Defaults.reduceEffectInDarkMode
        useHighCoverageLevel = ud.object(forKey: PaperSettings.Keys.useHighCoverageLevel) as? Bool ?? PaperSettings.Defaults.useHighCoverageLevel
        launchAtLogin = SMAppService.mainApp.status == .enabled
        pauseUntil = nil
        ud.set(launchAtLogin, forKey: PaperSettings.Keys.launchAtLogin)
    }

    deinit {
        pauseTimer?.invalidate()
    }

    func selectPreset(_ preset: PaperPreset) {
        selectedPresetID = preset.id
    }

    func resetIntensity() {
        intensity = PaperSettings.Defaults.intensity
    }

    func applyNightComfort() {
        selectedPresetID = "cottonPaper"
        isEnabled = true
        pauseUntil = nil
        pauseTimer?.invalidate()
        intensity = 1.15
        reduceEffectInDarkMode = true
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            UserDefaults.standard.set(enabled, forKey: PaperSettings.Keys.launchAtLogin)
        } catch {
            print("Launch at login error: \(error)")
        }
    }

    func pause(for minutes: TimeInterval) {
        pauseUntil = Date().addingTimeInterval(minutes * 60)
        schedulePauseTimer()
    }

    func resumeNow() {
        pauseTimer?.invalidate()
        pauseTimer = nil
        pauseUntil = nil
    }

    private func schedulePauseTimer() {
        pauseTimer?.invalidate()
        guard let pauseUntil else { return }
        let interval = max(0.1, pauseUntil.timeIntervalSinceNow)
        pauseTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.resumeNow()
            }
        }
    }
}

import AppKit
import SwiftUI
import Combine

@MainActor
final class OverlayWindowManager {
    private let appState: AppState
    private var panels: [String: PaperOverlayPanel] = [:]
    private var defaultCenterObservers: [NSObjectProtocol] = []
    private var workspaceCenterObservers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
    }

    func start() {
        syncScreens()

        let screenObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.syncScreens() }
        }

        let spaceObs = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updatePanelFrames() }
        }

        defaultCenterObservers = [screenObs]
        workspaceCenterObservers = [spaceObs]

        appState.$useHighCoverageLevel
            .removeDuplicates()
            .sink { [weak self] enabled in
                Task { @MainActor [weak self] in
                    self?.updatePanelLevels(useHighCoverageLevel: enabled)
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        for observer in defaultCenterObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        for observer in workspaceCenterObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        defaultCenterObservers = []
        workspaceCenterObservers = []
        cancellables.removeAll()
        for panel in panels.values { panel.close() }
        panels = [:]
    }

    func syncScreens() {
        let currentScreens = NSScreen.screens
        let currentIDs = Set(currentScreens.map { screenID(for: $0) })

        for id in panels.keys where !currentIDs.contains(id) {
            panels[id]?.close()
            panels[id] = nil
        }

        for screen in currentScreens {
            let id = screenID(for: screen)
            if panels[id] == nil {
                panels[id] = makePanel(for: screen)
            }
        }

        updatePanelFrames()
    }

    func screenID(for screen: NSScreen) -> String {
        "\(screen.localizedName)-\(screen.frame.origin.x)-\(screen.frame.origin.y)-\(screen.frame.width)-\(screen.frame.height)"
    }

    func makePanel(for screen: NSScreen) -> PaperOverlayPanel {
        let rootView = OverlayView(appState: appState)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)
        hostingView.autoresizingMask = [.width, .height]
        return PaperOverlayPanel(screen: screen, contentView: hostingView, useHighCoverageLevel: appState.useHighCoverageLevel)
    }

    func updatePanelFrames() {
        for screen in NSScreen.screens {
            let id = screenID(for: screen)
            guard let panel = panels[id] else { continue }
            panel.setFrame(screen.frame, display: true)
            panel.contentView?.frame = NSRect(origin: .zero, size: screen.frame.size)
            panel.orderFrontRegardless()
        }
    }

    func updatePanelLevels(useHighCoverageLevel: Bool) {
        for panel in panels.values {
            panel.setHighCoverageLevel(useHighCoverageLevel)
            panel.orderFrontRegardless()
        }
    }
}

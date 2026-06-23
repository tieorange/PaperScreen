import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var overlayManager: OverlayWindowManager?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        overlayManager = OverlayWindowManager(appState: appState)
        overlayManager?.start()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        statusItem = item
        updateStatusItem()

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 460, height: 680)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(
            rootView: SettingsPopoverView(appState: appState, onQuit: { [weak self] in self?.quit() })
        )
        popover = pop

        appState.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    @objc func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let pop = popover else { return }
        if pop.isShown {
            pop.performClose(sender)
        } else {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    func quit() {
        popover?.performClose(nil)
        overlayManager?.stop()
        NSApp.terminate(nil)
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }

        let symbolName: String
        let tooltip: String
        if !appState.isEnabled || appState.selectedPresetID == "original" {
            symbolName = "doc.text"
            tooltip = "PaperScreen: off"
        } else if appState.isPaused {
            symbolName = "pause.circle"
            tooltip = "PaperScreen: paused\(appState.pauseRemainingText.map { " (\($0))" } ?? "")"
        } else {
            symbolName = "doc.text.fill"
            tooltip = "PaperScreen: \(appState.selectedPreset.name)"
        }

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: tooltip)
        image?.isTemplate = true
        button.image = image
        button.toolTip = tooltip
    }
}

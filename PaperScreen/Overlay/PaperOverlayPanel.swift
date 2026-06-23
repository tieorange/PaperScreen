import AppKit

final class PaperOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(screen: NSScreen, contentView: NSView, useHighCoverageLevel: Bool) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setHighCoverageLevel(useHighCoverageLevel)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.contentView = contentView
        orderFrontRegardless()
    }

    func setHighCoverageLevel(_ enabled: Bool) {
        if enabled {
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        } else {
            level = .statusBar
        }
    }
}

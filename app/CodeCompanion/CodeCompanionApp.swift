import SwiftUI
import AppKit

@main
struct CodeCompanionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var companionWindow: NSPanel!
    var stateManager: StateManager!
    var animationController: AnimationController!
    var menuBarController: MenuBarController?
    private var isDragging = false
    private var dragEndTimer: Timer?
    private var cursorTrackingTimer: Timer?
    private var lastWindowPosition: CGPoint = .zero
    private let dragThreshold: CGFloat = 5  // Must move 5+ pixels to count as drag

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        stateManager = StateManager.shared
        animationController = AnimationController.shared

        setupCompanionWindow()
        stateManager.startServer()
        animationController.setState(.sleeping)

        // Setup menu bar icon
        menuBarController = MenuBarController(
            animationController: animationController,
            settings: SettingsManager.shared
        )
    }

    func setupCompanionWindow() {
        guard let screen = NSScreen.main else { return }

        let windowWidth: CGFloat = 80
        let windowHeight: CGFloat = 110  // Extra height for tooltip
        let padding: CGFloat = 20
        let windowX = screen.visibleFrame.maxX - windowWidth - padding
        let windowY = screen.visibleFrame.maxY - windowHeight - padding

        companionWindow = NSPanel(
            contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        companionWindow.isFloatingPanel = true
        companionWindow.level = .floating
        companionWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        companionWindow.isOpaque = false
        companionWindow.backgroundColor = .clear
        companionWindow.hasShadow = true
        companionWindow.isMovableByWindowBackground = true
        companionWindow.contentView = NSHostingView(rootView: CompanionView())
        companionWindow.orderFrontRegardless()

        // Track window position for eye direction
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: companionWindow
        )

        // Track drag start
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillMove),
            name: NSWindow.willMoveNotification,
            object: companionWindow
        )

        // Initial eye offset calculation
        updateEyeOffset()

        // Start cursor tracking timer for eye following
        startCursorTracking()
    }

    private func startCursorTracking() {
        cursorTrackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  SettingsManager.shared.eyeTrackingMode == .followCursor else { return }
            self.animationController.updateEyeOffsetForCursor(windowFrame: self.companionWindow.frame)
        }
    }

    @objc private func windowWillMove(_ notification: Notification) {
        // Record position before move starts
        lastWindowPosition = companionWindow.frame.origin
    }

    @objc private func windowDidMove(_ notification: Notification) {
        updateEyeOffset()

        // Check if window actually moved significantly (not just a click)
        let currentPosition = companionWindow.frame.origin
        let dx = abs(currentPosition.x - lastWindowPosition.x)
        let dy = abs(currentPosition.y - lastWindowPosition.y)
        let distance = sqrt(dx * dx + dy * dy)

        if distance > dragThreshold && !isDragging {
            isDragging = true
            animationController.onDragStart()
        }

        // Update position for next check
        lastWindowPosition = currentPosition

        // End drag after movement stops
        dragEndTimer?.invalidate()
        dragEndTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            guard let self = self, self.isDragging else { return }
            self.isDragging = false
            self.animationController.onDragEnd()
        }
    }

    private func updateEyeOffset() {
        guard let screen = companionWindow.screen ?? NSScreen.main else { return }
        animationController.updateEyeOffset(
            windowFrame: companionWindow.frame,
            screenFrame: screen.frame
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        cursorTrackingTimer?.invalidate()
        stateManager.stopServer()
    }
}

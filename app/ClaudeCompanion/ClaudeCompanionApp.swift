import SwiftUI
import AppKit

@main
struct ClaudeCompanionApp: App {
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)

        // Initialize managers
        stateManager = StateManager.shared
        animationController = AnimationController.shared

        // Create the floating companion window
        setupCompanionWindow()

        // Start the HTTP server for MCP communication
        stateManager.startServer()

        // Start with sleeping state (Claude not running)
        animationController.setState(.sleeping)
    }

    func setupCompanionWindow() {
        // Get screen dimensions
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        // Window size
        let windowSize: CGFloat = 80
        let padding: CGFloat = 20

        // Position in top right
        let windowX = screenFrame.maxX - windowSize - padding
        let windowY = screenFrame.maxY - windowSize - padding

        // Create the panel (floating window)
        companionWindow = NSPanel(
            contentRect: NSRect(x: windowX, y: windowY, width: windowSize, height: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure window properties
        companionWindow.isFloatingPanel = true
        companionWindow.level = .floating
        companionWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        companionWindow.isOpaque = false
        companionWindow.backgroundColor = .clear
        companionWindow.hasShadow = true
        companionWindow.isMovableByWindowBackground = true

        // Create the companion view
        let companionView = CompanionView()
        companionWindow.contentView = NSHostingView(rootView: companionView)

        // Show the window
        companionWindow.orderFrontRegardless()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stateManager.stopServer()
    }
}

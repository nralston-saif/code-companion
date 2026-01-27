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
        NSApp.setActivationPolicy(.accessory)

        stateManager = StateManager.shared
        animationController = AnimationController.shared

        setupCompanionWindow()
        stateManager.startServer()
        animationController.setState(.sleeping)
    }

    func setupCompanionWindow() {
        guard let screen = NSScreen.main else { return }

        let windowSize: CGFloat = 80
        let padding: CGFloat = 20
        let windowX = screen.visibleFrame.maxX - windowSize - padding
        let windowY = screen.visibleFrame.maxY - windowSize - padding

        companionWindow = NSPanel(
            contentRect: NSRect(x: windowX, y: windowY, width: windowSize, height: windowSize),
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        stateManager.stopServer()
    }
}

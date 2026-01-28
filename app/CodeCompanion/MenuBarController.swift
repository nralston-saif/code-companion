import SwiftUI
import AppKit
import Combine

class MenuBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var animationController: AnimationController
    private var settings: SettingsManager
    private var stateObserver: Any?

    init(animationController: AnimationController, settings: SettingsManager) {
        self.animationController = animationController
        self.settings = settings
        super.init()

        if settings.showMenuBarIcon {
            setupStatusItem()
        }

        // Observe settings changes
        stateObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateVisibility()
        }
    }

    private func updateVisibility() {
        if settings.showMenuBarIcon {
            if statusItem == nil {
                setupStatusItem()
            }
        } else {
            removeStatusItem()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            updateIcon(for: animationController.currentState)
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }

        setupMenu()

        // Observe state changes to update icon
        animationController.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateIcon(for: state)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func updateIcon(for state: CompanionState) {
        guard let button = statusItem?.button else { return }

        let symbolName: String
        let color: NSColor

        switch state {
        case .sleeping:
            symbolName = "moon.zzz.fill"
            color = .gray
        case .idle:
            symbolName = "face.smiling"
            color = .systemGreen
        case .thinking:
            symbolName = "brain"
            color = .systemBlue
        case .working:
            symbolName = "gearshape.2.fill"
            color = .systemBlue
        case .attention:
            symbolName = "exclamationmark.circle.fill"
            color = .systemOrange
        case .success:
            symbolName = "checkmark.circle.fill"
            color = .systemGreen
        case .error:
            symbolName = "xmark.circle.fill"
            color = .systemRed
        case .listening:
            symbolName = "ear.fill"
            color = .systemPurple
        default:
            symbolName = "face.smiling"
            color = .systemGreen
        }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: state.rawValue)?
            .withSymbolConfiguration(config) {
            button.image = image
            button.contentTintColor = color
        }
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Stats
        let petStats = PetStats.shared
        let statsItem = NSMenuItem(title: "Tasks: \(petStats.totalTasks) | ✓ \(petStats.totalSuccesses) | ✗ \(petStats.totalErrors)", action: nil, keyEquivalent: "")
        statsItem.isEnabled = false
        menu.addItem(statsItem)

        // State indicator
        let stateItem = NSMenuItem(title: "State: \(animationController.currentState.rawValue)", action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(stateItem)

        menu.addItem(NSMenuItem.separator())

        // Quick actions
        menu.addItem(NSMenuItem(title: "Wake Up", action: #selector(wakeUp), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "Sleep", action: #selector(goToSleep), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Wave", action: #selector(wave), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Notifications submenu
        let notificationsMenu = NSMenu()
        let permissionItem = NSMenuItem(title: "Permission Requests", action: #selector(toggleNotifyPermission), keyEquivalent: "")
        permissionItem.state = settings.notifyOnPermission ? .on : .off
        notificationsMenu.addItem(permissionItem)
        let completionItem = NSMenuItem(title: "Task Completion", action: #selector(toggleNotifyCompletion), keyEquivalent: "")
        completionItem.state = settings.notifyOnCompletion ? .on : .off
        notificationsMenu.addItem(completionItem)
        let idleItem = NSMenuItem(title: "Waiting for Input", action: #selector(toggleNotifyIdle), keyEquivalent: "")
        idleItem.state = settings.notifyOnIdle ? .on : .off
        notificationsMenu.addItem(idleItem)
        let errorItem = NSMenuItem(title: "Errors", action: #selector(toggleNotifyError), keyEquivalent: "")
        errorItem.state = settings.notifyOnError ? .on : .off
        notificationsMenu.addItem(errorItem)
        let notificationsItem = NSMenuItem(title: "Notifications", action: nil, keyEquivalent: "")
        notificationsItem.submenu = notificationsMenu
        menu.addItem(notificationsItem)

        // Sounds submenu
        let soundsMenu = NSMenu()
        let notifSoundItem = NSMenuItem(title: "Notification Sounds", action: #selector(toggleSounds), keyEquivalent: "")
        notifSoundItem.state = settings.notificationSounds ? .on : .off
        soundsMenu.addItem(notifSoundItem)
        let ambientItem = NSMenuItem(title: "Ambient Sounds", action: #selector(toggleAmbientSounds), keyEquivalent: "")
        ambientItem.state = settings.ambientSounds ? .on : .off
        soundsMenu.addItem(ambientItem)
        let soundsItem = NSMenuItem(title: "Sounds", action: nil, keyEquivalent: "")
        soundsItem.submenu = soundsMenu
        menu.addItem(soundsItem)

        // Eye Tracking submenu
        let eyeMenu = NSMenu()
        for mode in EyeTrackingMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(setEyeTracking(_:)), keyEquivalent: "")
            item.state = settings.eyeTrackingMode == mode ? .on : .off
            item.representedObject = mode
            eyeMenu.addItem(item)
        }
        let eyeItem = NSMenuItem(title: "Eye Tracking", action: nil, keyEquivalent: "")
        eyeItem.submenu = eyeMenu
        menu.addItem(eyeItem)

        // Skin submenu
        let skinMenu = NSMenu()
        for skin in CompanionSkin.allSkins {
            let item = NSMenuItem(title: skin.name, action: #selector(setSkin(_:)), keyEquivalent: "")
            item.state = SkinManager.shared.currentSkin.id == skin.id ? .on : .off
            item.representedObject = skin.id
            skinMenu.addItem(item)
        }
        let skinItem = NSMenuItem(title: "Skin", action: nil, keyEquivalent: "")
        skinItem.submenu = skinMenu
        menu.addItem(skinItem)

        menu.addItem(NSMenuItem.separator())

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.state = settings.launchAtLogin ? .on : .off
        menu.addItem(launchItem)

        let menuBarItem = NSMenuItem(title: "Show Menu Bar Icon", action: #selector(toggleMenuBarIcon), keyEquivalent: "")
        menuBarItem.state = settings.showMenuBarIcon ? .on : .off
        menu.addItem(menuBarItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit Code Companion", action: #selector(quit), keyEquivalent: "q"))

        // Set targets for all items including submenus
        setTargets(for: menu)

        statusItem?.menu = menu
    }

    private func setTargets(for menu: NSMenu) {
        for item in menu.items {
            item.target = self
            if let submenu = item.submenu {
                setTargets(for: submenu)
            }
        }
    }

    @objc private func statusBarButtonClicked() {
        // Left click shows menu by default
    }

    @objc private func wakeUp() {
        animationController.setState(.idle)
    }

    @objc private func goToSleep() {
        animationController.setState(.sleeping)
    }

    @objc private func wave() {
        animationController.setState(.waving, duration: 2.0)
    }

    @objc private func toggleSounds() {
        settings.notificationSounds.toggle()
        setupMenu()
    }

    @objc private func toggleAmbientSounds() {
        settings.ambientSounds.toggle()
        setupMenu()
    }

    @objc private func toggleNotifyPermission() {
        settings.notifyOnPermission.toggle()
        setupMenu()
    }

    @objc private func toggleNotifyCompletion() {
        settings.notifyOnCompletion.toggle()
        setupMenu()
    }

    @objc private func toggleNotifyIdle() {
        settings.notifyOnIdle.toggle()
        setupMenu()
    }

    @objc private func toggleNotifyError() {
        settings.notifyOnError.toggle()
        setupMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        settings.launchAtLogin.toggle()
        setupMenu()
    }

    @objc private func toggleMenuBarIcon() {
        settings.showMenuBarIcon.toggle()
    }

    @objc private func setEyeTracking(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? EyeTrackingMode {
            settings.eyeTrackingMode = mode
            setupMenu()
        }
    }

    @objc private func setSkin(_ sender: NSMenuItem) {
        if let skinId = sender.representedObject as? String,
           let skin = CompanionSkin.allSkins.first(where: { $0.id == skinId }) {
            SkinManager.shared.selectSkin(skin)
            setupMenu()
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    deinit {
        if let observer = stateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        removeStatusItem()
    }
}

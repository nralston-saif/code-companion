import Foundation
import SwiftUI

enum EyeTrackingMode: String, CaseIterable {
    case screenCenter = "screenCenter"
    case followCursor = "followCursor"
    case disabled = "disabled"

    var displayName: String {
        switch self {
        case .screenCenter: return "Follow Screen Center"
        case .followCursor: return "Follow Cursor"
        case .disabled: return "Disabled"
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let notificationSounds = "notificationSounds"
        static let ambientSounds = "ambientSounds"
        static let notifyOnPermission = "notifyOnPermission"
        static let notifyOnCompletion = "notifyOnCompletion"
        static let notifyOnIdle = "notifyOnIdle"
        static let notifyOnError = "notifyOnError"
        static let launchAtLogin = "launchAtLogin"
        static let eyeTrackingMode = "eyeTrackingMode"
        static let showMenuBarIcon = "showMenuBarIcon"
    }

    @Published var notificationSounds: Bool {
        didSet { defaults.set(notificationSounds, forKey: Keys.notificationSounds) }
    }

    @Published var ambientSounds: Bool {
        didSet { defaults.set(ambientSounds, forKey: Keys.ambientSounds) }
    }

    @Published var notifyOnPermission: Bool {
        didSet { defaults.set(notifyOnPermission, forKey: Keys.notifyOnPermission) }
    }

    @Published var notifyOnCompletion: Bool {
        didSet { defaults.set(notifyOnCompletion, forKey: Keys.notifyOnCompletion) }
    }

    @Published var notifyOnIdle: Bool {
        didSet { defaults.set(notifyOnIdle, forKey: Keys.notifyOnIdle) }
    }

    @Published var notifyOnError: Bool {
        didSet { defaults.set(notifyOnError, forKey: Keys.notifyOnError) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLoginItem()
        }
    }

    @Published var eyeTrackingMode: EyeTrackingMode {
        didSet {
            defaults.set(eyeTrackingMode.rawValue, forKey: Keys.eyeTrackingMode)
        }
    }

    @Published var showMenuBarIcon: Bool {
        didSet { defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon) }
    }

    init() {
        defaults.register(defaults: [
            Keys.notificationSounds: true,
            Keys.ambientSounds: false,
            Keys.notifyOnPermission: true,
            Keys.notifyOnCompletion: true,
            Keys.notifyOnIdle: true,
            Keys.notifyOnError: true,
            Keys.launchAtLogin: false,
            Keys.eyeTrackingMode: EyeTrackingMode.followCursor.rawValue,
            Keys.showMenuBarIcon: true
        ])

        self.notificationSounds = defaults.bool(forKey: Keys.notificationSounds)
        self.ambientSounds = defaults.bool(forKey: Keys.ambientSounds)
        self.notifyOnPermission = defaults.bool(forKey: Keys.notifyOnPermission)
        self.notifyOnCompletion = defaults.bool(forKey: Keys.notifyOnCompletion)
        self.notifyOnIdle = defaults.bool(forKey: Keys.notifyOnIdle)
        self.notifyOnError = defaults.bool(forKey: Keys.notifyOnError)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)

        if let modeString = defaults.string(forKey: Keys.eyeTrackingMode),
           let mode = EyeTrackingMode(rawValue: modeString) {
            self.eyeTrackingMode = mode
        } else {
            self.eyeTrackingMode = .followCursor
        }

        self.showMenuBarIcon = defaults.bool(forKey: Keys.showMenuBarIcon)
    }

    private func updateLoginItem() {
        // SMAppService implementation for launch at login
    }

    func shouldNotify(for state: CompanionState) -> Bool {
        switch state {
        case .attention: return notifyOnPermission
        case .success: return notifyOnCompletion
        case .error: return notifyOnError
        case .listening: return notifyOnIdle
        default: return true
        }
    }
}

import Foundation
import SwiftUI

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

    init() {
        defaults.register(defaults: [
            Keys.notificationSounds: true,
            Keys.ambientSounds: false,
            Keys.notifyOnPermission: true,
            Keys.notifyOnCompletion: true,
            Keys.notifyOnIdle: true,
            Keys.notifyOnError: true,
            Keys.launchAtLogin: false
        ])

        self.notificationSounds = defaults.bool(forKey: Keys.notificationSounds)
        self.ambientSounds = defaults.bool(forKey: Keys.ambientSounds)
        self.notifyOnPermission = defaults.bool(forKey: Keys.notifyOnPermission)
        self.notifyOnCompletion = defaults.bool(forKey: Keys.notifyOnCompletion)
        self.notifyOnIdle = defaults.bool(forKey: Keys.notifyOnIdle)
        self.notifyOnError = defaults.bool(forKey: Keys.notifyOnError)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
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

import Foundation
import AppKit

enum SoundType {
    case notification  // Sounds for alerts that need user attention
    case ambient       // Clicks, wake-up, idle animations
}

class SoundManager {
    static let shared = SoundManager()

    init() {
        // Pre-warm the sound system
        _ = NSSound(named: "Pop")
    }

    func play(_ effect: SoundEffect) {
        let settings = SettingsManager.shared
        let soundType = effect.soundType

        // Check if this type of sound is enabled
        switch soundType {
        case .notification:
            guard settings.notificationSounds else { return }
        case .ambient:
            guard settings.ambientSounds else { return }
        }

        DispatchQueue.main.async {
            self.playSystemSound(for: effect)
        }
    }

    private func playSystemSound(for effect: SoundEffect) {
        let soundName: String
        switch effect {
        case .chime:
            soundName = "Glass"
        case .success:
            soundName = "Hero"
        case .concern:
            soundName = "Basso"
        case .hello, .wake:
            soundName = "Pop"
        case .click:
            soundName = "Tink"
        }

        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        }
    }
}

// Extend SoundEffect to categorize sounds
extension SoundEffect {
    var soundType: SoundType {
        switch self {
        case .chime, .concern:
            return .notification  // Alert sounds
        case .success:
            return .notification  // Task complete notification
        case .hello, .wake, .click:
            return .ambient       // Random/interaction sounds
        }
    }
}

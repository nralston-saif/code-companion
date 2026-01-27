import Foundation
import AppKit

enum SoundType {
    case notification
    case ambient
}

class SoundManager {
    static let shared = SoundManager()

    init() {
        _ = NSSound(named: "Pop")
    }

    func play(_ effect: SoundEffect) {
        let settings = SettingsManager.shared

        switch effect.soundType {
        case .notification:
            guard settings.notificationSounds else { return }
        case .ambient:
            guard settings.ambientSounds else { return }
        }

        DispatchQueue.main.async {
            NSSound(named: NSSound.Name(effect.systemSoundName))?.play()
        }
    }
}

extension SoundEffect {
    var soundType: SoundType {
        switch self {
        case .chime, .concern, .success:
            return .notification
        case .hello, .wake, .click:
            return .ambient
        }
    }

    var systemSoundName: String {
        switch self {
        case .chime: return "Glass"
        case .success: return "Hero"
        case .concern: return "Basso"
        case .hello, .wake: return "Pop"
        case .click: return "Tink"
        }
    }
}

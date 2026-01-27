import Foundation

enum CompanionState: String, Codable, CaseIterable {
    case sleeping      // Claude not running
    case idle          // Default awake state
    case thinking      // Processing/thinking
    case working       // Actively doing something
    case attention     // Needs user attention
    case success       // Task completed successfully
    case error         // Something went wrong
    case listening     // Waiting for user input
    case hovering      // Mouse is over the companion
    case clicked       // Just got clicked
    case curious       // Looking at something interesting
    case waving        // Saying hi!

    var soundEffect: SoundEffect? {
        switch self {
        case .attention:
            return .chime
        case .success:
            return .success
        case .error:
            return .concern
        case .waving:
            return .hello
        default:
            return nil
        }
    }

    var priority: Int {
        switch self {
        case .sleeping: return 0
        case .idle: return 1
        case .listening: return 2
        case .hovering: return 3
        case .curious: return 3
        case .working: return 4
        case .thinking: return 5
        case .clicked: return 6
        case .waving: return 7
        case .success: return 8
        case .error: return 8
        case .attention: return 9
        }
    }
}

enum SoundEffect: String, CaseIterable {
    case chime      // Friendly attention sound
    case success    // Happy completion
    case concern    // Something's not right
    case hello      // Greeting
    case wake       // Waking up
    case click      // Response to click
}

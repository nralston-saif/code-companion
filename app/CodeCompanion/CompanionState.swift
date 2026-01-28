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

    // Phase 1: Idle actions
    case yawning       // Droopy eyes, open mouth
    case stretching    // Elongated body
    case lookingAround // Eyes dart left/right
    case scratchingHead // Motion indicator near head

    // Phase 1: Drag states
    case dragging      // Wiggle during drag
    case settling      // Wobble after drop

    // Phase 2: Pet/poke states
    case petted        // Happy with blush
    case giggling      // Very happy, bouncing
    case dizzy         // Too many clicks, spiral eyes

    var soundEffect: SoundEffect? {
        switch self {
        case .attention:
            return .chime
        case .success, .petted:
            return .success
        case .error, .dizzy:
            return .concern
        case .waving, .giggling:
            return .hello
        default:
            return nil
        }
    }

    var priority: Int {
        switch self {
        case .sleeping: return 0
        case .idle: return 1
        case .yawning, .stretching, .lookingAround, .scratchingHead: return 1
        case .listening: return 2
        case .hovering: return 3
        case .curious: return 3
        case .working: return 4
        case .thinking: return 5
        case .dragging, .settling: return 5
        case .clicked: return 6
        case .petted, .giggling: return 6
        case .waving: return 7
        case .success: return 8
        case .error, .dizzy: return 8
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

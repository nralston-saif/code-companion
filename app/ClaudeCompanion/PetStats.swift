import SwiftUI
import Combine

class PetStats: ObservableObject {
    static let shared = PetStats()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let happiness = "petHappiness"
        static let lastInteraction = "petLastInteraction"
        static let totalTasks = "petTotalTasks"
        static let totalSuccesses = "petTotalSuccesses"
        static let totalErrors = "petTotalErrors"
    }

    @Published private(set) var happiness: Double = 50

    private func setHappiness(_ value: Double) {
        let clamped = max(0, min(100, value))
        happiness = clamped
        defaults.set(clamped, forKey: Keys.happiness)
    }

    @Published var lastInteraction: Date {
        didSet {
            defaults.set(lastInteraction, forKey: Keys.lastInteraction)
        }
    }

    @Published var totalTasks: Int {
        didSet { defaults.set(totalTasks, forKey: Keys.totalTasks) }
    }

    @Published var totalSuccesses: Int {
        didSet { defaults.set(totalSuccesses, forKey: Keys.totalSuccesses) }
    }

    @Published var totalErrors: Int {
        didSet { defaults.set(totalErrors, forKey: Keys.totalErrors) }
    }

    private var decayTimer: Timer?

    // Happiness thresholds
    static let happyThreshold: Double = 70
    static let sadThreshold: Double = 30

    var mood: PetMood {
        if happiness >= Self.happyThreshold {
            return .happy
        } else if happiness <= Self.sadThreshold {
            return .sad
        } else {
            return .neutral
        }
    }

    var moodEmoji: String {
        switch mood {
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😢"
        }
    }

    var happinessDescription: String {
        switch mood {
        case .happy: return "Very Happy!"
        case .neutral: return "Content"
        case .sad: return "Lonely..."
        }
    }

    init() {
        // Load saved stats
        let savedHappiness = defaults.double(forKey: Keys.happiness)
        if savedHappiness == 0 && defaults.object(forKey: Keys.happiness) == nil {
            self.happiness = 70 // Start happy
        } else {
            self.happiness = savedHappiness
        }

        self.lastInteraction = defaults.object(forKey: Keys.lastInteraction) as? Date ?? Date()
        self.totalTasks = defaults.integer(forKey: Keys.totalTasks)
        self.totalSuccesses = defaults.integer(forKey: Keys.totalSuccesses)
        self.totalErrors = defaults.integer(forKey: Keys.totalErrors)

        // Apply decay for time since last interaction
        applyOfflineDecay()

        // Start decay timer
        startDecayTimer()
    }

    private func applyOfflineDecay() {
        let hoursSinceLastInteraction = Date().timeIntervalSince(lastInteraction) / 3600
        if hoursSinceLastInteraction > 1 {
            // Lose 2 happiness per hour of absence (max 30 loss)
            let decay = min(30, hoursSinceLastInteraction * 2)
            setHappiness(happiness - decay)
        }
    }

    private func startDecayTimer() {
        // Decay happiness slowly over time (1 point per 10 minutes of inactivity)
        decayTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Only decay if not recently interacted
            let minutesSinceInteraction = Date().timeIntervalSince(self.lastInteraction) / 60
            if minutesSinceInteraction > 10 {
                self.setHappiness(self.happiness - 1)
            }
        }
    }

    // MARK: - Events

    func onTaskStarted() {
        lastInteraction = Date()
        totalTasks += 1
        setHappiness(happiness + 1) // Small boost for starting work
    }

    func onSuccess() {
        lastInteraction = Date()
        totalSuccesses += 1
        setHappiness(happiness + 5) // Good boost for success
    }

    func onError() {
        lastInteraction = Date()
        totalErrors += 1
        setHappiness(happiness - 2) // Small penalty for errors
    }

    func onInteraction() {
        lastInteraction = Date()
        setHappiness(happiness + 0.5) // Tiny boost for any interaction
    }

    func onPetted() {
        lastInteraction = Date()
        setHappiness(happiness + 3) // Nice boost for being petted
    }

    func onNeglected() {
        // Called when companion goes to sleep from timeout
        setHappiness(happiness - 5)
    }

    // MARK: - Stats Summary

    var statsSummary: String {
        """
        Happiness: \(Int(happiness))% \(moodEmoji)
        Tasks: \(totalTasks) | Success: \(totalSuccesses) | Errors: \(totalErrors)
        """
    }

    deinit {
        decayTimer?.invalidate()
    }
}

enum PetMood {
    case happy
    case neutral
    case sad
}

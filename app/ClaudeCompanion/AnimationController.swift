import SwiftUI
import Combine

class AnimationController: ObservableObject {
    static let shared = AnimationController()

    @Published var currentState: CompanionState = .sleeping
    @Published var currentFrame: Int = 0

    private var frameTimer: Timer?
    private var stateTimer: Timer?
    private var previousState: CompanionState = .sleeping
    private var temporaryStateEndTime: Date?
    private var baseState: CompanionState = .sleeping

    private let soundManager = SoundManager.shared

    // Rare idle animations
    private var lastIdleAnimation: Date = Date()
    private let rareAnimationChance: Double = 0.02 // 2% chance per check

    init() {
        startFrameTimer()
    }

    private func startFrameTimer() {
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentFrame += 1

            // Check for temporary state expiration
            if let endTime = self.temporaryStateEndTime, Date() > endTime {
                self.temporaryStateEndTime = nil
                self.transitionTo(self.baseState)
            }

            // Random idle animations when idle
            if self.currentState == .idle && Date().timeIntervalSince(self.lastIdleAnimation) > 10 {
                if Double.random(in: 0...1) < self.rareAnimationChance {
                    self.triggerRareIdleAnimation()
                }
            }
        }
    }

    // MARK: - Public Methods

    func setState(_ state: CompanionState, duration: TimeInterval? = nil) {
        let oldState = currentState

        // Update base state for non-temporary states
        if duration == nil {
            baseState = state
        } else {
            temporaryStateEndTime = Date().addingTimeInterval(duration!)
        }

        transitionTo(state)

        // Play sound if needed
        if let sound = state.soundEffect, state != oldState {
            soundManager.play(sound)
        }

        // Special handling for waking up
        if oldState == .sleeping && state != .sleeping {
            soundManager.play(.wake)
        }
    }

    func setTemporaryState(_ state: CompanionState, duration: TimeInterval) {
        setState(state, duration: duration)
    }

    private func transitionTo(_ state: CompanionState) {
        withAnimation(.easeInOut(duration: 0.2)) {
            previousState = currentState
            currentState = state
        }
    }

    // MARK: - Mouse Interactions

    func onHover() {
        if currentState == .sleeping {
            // Don't wake up on hover, just acknowledge slightly
            return
        }
        if currentState.priority < CompanionState.hovering.priority {
            setTemporaryState(.hovering, duration: 0.5)
        }
    }

    func onHoverEnd() {
        if currentState == .hovering {
            transitionTo(baseState)
        }
    }

    func onClick() {
        soundManager.play(.click)
        setTemporaryState(.clicked, duration: 0.3)

        // After click animation, show happy response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if self.currentState == .sleeping {
                // Wake up!
                self.setState(.idle)
                self.soundManager.play(.wake)
            } else {
                // Happy response
                self.setTemporaryState(.success, duration: 0.8)
            }
        }
    }

    func onDoubleClick() {
        // Wave animation
        setState(.waving, duration: 2.0)
    }

    // MARK: - Rare Animations

    private func triggerRareIdleAnimation() {
        lastIdleAnimation = Date()

        let animations: [() -> Void] = [
            // Look around curiously
            { [weak self] in
                self?.setTemporaryState(.curious, duration: 2.0)
            },
            // Quick blink sequence (handled in normal idle via frame)
            { },
            // Small wave
            { [weak self] in
                self?.setTemporaryState(.waving, duration: 1.5)
            }
        ]

        animations.randomElement()?()
    }

    // MARK: - Time-based Behaviors

    func checkTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())

        // Late night / early morning - look sleepy
        if hour >= 23 || hour < 6 {
            if currentState == .idle {
                // Add occasional yawn (could be a new state)
            }
        }
    }

    deinit {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
    }
}

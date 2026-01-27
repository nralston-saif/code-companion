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
    private var lastIdleAnimation = Date()
    private let rareAnimationChance: Double = 0.02

    init() {
        startFrameTimer()
    }

    private func startFrameTimer() {
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.onFrameTick()
        }
    }

    private func onFrameTick() {
        currentFrame += 1

        if let endTime = temporaryStateEndTime, Date() > endTime {
            temporaryStateEndTime = nil
            transitionTo(baseState)
        }

        if currentState == .idle && Date().timeIntervalSince(lastIdleAnimation) > 10 {
            if Double.random(in: 0...1) < rareAnimationChance {
                triggerRareIdleAnimation()
            }
        }
    }

    func setState(_ state: CompanionState, duration: TimeInterval? = nil) {
        let oldState = currentState

        if let duration = duration {
            temporaryStateEndTime = Date().addingTimeInterval(duration)
        } else {
            baseState = state
        }

        transitionTo(state)

        if let sound = state.soundEffect, state != oldState {
            soundManager.play(sound)
        }

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

    func onHover() {
        guard currentState != .sleeping else { return }
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if self.currentState == .sleeping {
                self.setState(.idle)
                self.soundManager.play(.wake)
            } else {
                self.setTemporaryState(.success, duration: 0.8)
            }
        }
    }

    func onDoubleClick() {
        setState(.waving, duration: 2.0)
    }

    private func triggerRareIdleAnimation() {
        lastIdleAnimation = Date()

        let animations: [() -> Void] = [
            { [weak self] in self?.setTemporaryState(.curious, duration: 2.0) },
            { },
            { [weak self] in self?.setTemporaryState(.waving, duration: 1.5) }
        ]

        animations.randomElement()?()
    }

    deinit {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
    }
}

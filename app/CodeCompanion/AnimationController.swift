import SwiftUI
import Combine

class AnimationController: ObservableObject {
    static let shared = AnimationController()

    @Published var currentState: CompanionState = .sleeping
    @Published var currentFrame: Int = 0
    @Published var eyeOffset: CGPoint = .zero
    @Published var breathingPhase: CGFloat = 0
    @Published var isDragging: Bool = false
    @Published var dragOffset: CGPoint = .zero
    @Published var currentBubble: BubbleContent? = nil
    @Published var currentParticleEffect: ParticleEffect? = nil
    @Published var statusMessage: String? = nil

    private var frameTimer: Timer?
    private var stateTimer: Timer?
    private var previousState: CompanionState = .sleeping
    private var temporaryStateEndTime: Date?
    private var baseState: CompanionState = .sleeping
    private let soundManager = SoundManager.shared
    private var lastIdleAnimation = Date()
    private let rareAnimationChance: Double = 0.02  // 2% chance

    // Click tracking for pet/poke
    private var recentClickCount: Int = 0
    private var lastClickTime = Date.distantPast
    private let clickTrackingWindow: TimeInterval = 2.0

    // Bubble and particle timers
    private var bubbleTimer: Timer?
    private var particleTimer: Timer?

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

        // Update breathing animation (subtle oscillation)
        breathingPhase = CGFloat(sin(Double(currentFrame) * 0.05))

        if let endTime = temporaryStateEndTime, Date() > endTime {
            temporaryStateEndTime = nil
            transitionTo(baseState)
        }

        // Trigger rare idle animations when idle
        if currentState == .idle && Date().timeIntervalSince(lastIdleAnimation) > 10 {
            if Double.random(in: 0...1) < rareAnimationChance {
                triggerRareIdleAnimation()
            }
        }

        // Reset click count if tracking window expired
        if Date().timeIntervalSince(lastClickTime) > clickTrackingWindow {
            recentClickCount = 0
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

    private var isProcessingClick = false

    func onClick() {
        // Prevent overlapping click processing
        guard !isProcessingClick else { return }
        isProcessingClick = true

        soundManager.play(.click)

        // Track clicks for pet/poke reactions
        let now = Date()
        if now.timeIntervalSince(lastClickTime) < clickTrackingWindow {
            recentClickCount += 1
        } else {
            recentClickCount = 1
        }
        lastClickTime = now

        // React based on click count
        if recentClickCount >= 8 {
            // Too many clicks - dizzy!
            setTemporaryState(.dizzy, duration: 1.5)
            recentClickCount = 0
        } else if recentClickCount >= 5 {
            // Many clicks - giggling
            setTemporaryState(.giggling, duration: 0.8)
        } else if recentClickCount >= 3 {
            // Few quick clicks - petted
            PetStats.shared.onPetted()
            setTemporaryState(.petted, duration: 0.5)
        } else {
            setTemporaryState(.clicked, duration: 0.2)

            if currentState == .sleeping {
                setState(.idle)
                soundManager.play(.wake)
            }
        }

        // Allow next click after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isProcessingClick = false
        }
    }

    func onDoubleClick() {
        setState(.waving, duration: 2.0)
    }

    // MARK: - Drag Handling

    func onDragStart() {
        isDragging = true
        transitionTo(.dragging)
    }

    func onDragChanged(translation: CGPoint) {
        dragOffset = translation
    }

    func onDragEnd() {
        isDragging = false
        dragOffset = .zero
        setTemporaryState(.settling, duration: 0.5)
    }

    /// Calculate wiggle effect during drag
    func calculateDragWiggle() -> CGFloat {
        guard isDragging else { return 0 }
        return sin(Double(currentFrame) * 0.8) * 3
    }

    /// Calculate breathing scale for idle states
    func calculateBreathingScale() -> CGFloat {
        let isBreathing = [.idle, .sleeping, .listening].contains(currentState)
        guard isBreathing else { return 1.0 }
        return 1.0 + breathingPhase * 0.015 // Very subtle 1.5% scale
    }

    private func triggerRareIdleAnimation() {
        lastIdleAnimation = Date()

        let animations: [() -> Void] = [
            { [weak self] in self?.setTemporaryState(.curious, duration: 2.0) },
            { [weak self] in self?.setTemporaryState(.waving, duration: 1.5) },
            { [weak self] in self?.setTemporaryState(.yawning, duration: 2.5) },
            { [weak self] in self?.setTemporaryState(.stretching, duration: 2.0) },
            { [weak self] in self?.setTemporaryState(.lookingAround, duration: 3.0) },
            { [weak self] in self?.setTemporaryState(.scratchingHead, duration: 2.0) },
            { } // Sometimes do nothing
        ]

        animations.randomElement()?()
    }

    func updateEyeOffset(windowFrame: CGRect, screenFrame: CGRect) {
        let settings = SettingsManager.shared

        switch settings.eyeTrackingMode {
        case .disabled:
            eyeOffset = .zero
        case .screenCenter:
            updateEyeOffsetForScreenCenter(windowFrame: windowFrame, screenFrame: screenFrame)
        case .followCursor:
            updateEyeOffsetForCursor(windowFrame: windowFrame)
        }
    }

    private func updateEyeOffsetForScreenCenter(windowFrame: CGRect, screenFrame: CGRect) {
        let windowCenter = CGPoint(
            x: windowFrame.midX,
            y: windowFrame.midY
        )
        let screenCenter = CGPoint(
            x: screenFrame.midX,
            y: screenFrame.midY
        )

        calculateEyeOffsetToward(target: screenCenter, from: windowCenter, maxDistance: screenFrame.width / 2)
    }

    func updateEyeOffsetForCursor(windowFrame: CGRect) {
        let cursorLocation = NSEvent.mouseLocation
        let windowCenter = CGPoint(
            x: windowFrame.midX,
            y: windowFrame.midY
        )

        calculateEyeOffsetToward(target: cursorLocation, from: windowCenter, maxDistance: 300)
    }

    private func calculateEyeOffsetToward(target: CGPoint, from: CGPoint, maxDistance: CGFloat) {
        // Calculate direction from window to target
        let dx = target.x - from.x
        let dy = target.y - from.y

        // Normalize and scale the offset (max ~2 pixels of eye movement)
        let maxOffset: CGFloat = 2.0
        let distance = sqrt(dx * dx + dy * dy)

        if distance > 0 {
            let scale = min(distance / maxDistance, 1.0) * maxOffset
            eyeOffset = CGPoint(
                x: (dx / distance) * scale,
                y: -(dy / distance) * scale  // Flip Y since screen coords are inverted
            )
        } else {
            eyeOffset = .zero
        }
    }

    // MARK: - Bubble Methods

    func showBubble(_ content: BubbleContent, duration: TimeInterval = 3.0) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentBubble = content
        }

        bubbleTimer?.invalidate()
        bubbleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            withAnimation(.easeOut(duration: 0.2)) {
                self?.currentBubble = nil
            }
        }
    }

    func showBubble(emoji: String, duration: TimeInterval = 2.0) {
        showBubble(BubbleContent(emoji: emoji, type: .speech), duration: duration)
    }

    func showBubble(text: String, type: BubbleType = .speech, duration: TimeInterval = 3.0) {
        showBubble(BubbleContent(text: text, type: type), duration: duration)
    }

    func hideBubble() {
        withAnimation(.easeOut(duration: 0.2)) {
            currentBubble = nil
        }
        bubbleTimer?.invalidate()
    }

    // MARK: - Particle Methods

    func showParticles(_ effect: ParticleEffect, duration: TimeInterval = 2.0) {
        currentParticleEffect = effect

        particleTimer?.invalidate()
        particleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.currentParticleEffect = nil
        }
    }

    func hideParticles() {
        currentParticleEffect = nil
        particleTimer?.invalidate()
    }

    // MARK: - Status Message

    func setStatus(_ message: String?) {
        statusMessage = message
    }

    deinit {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
        bubbleTimer?.invalidate()
        particleTimer?.invalidate()
    }
}

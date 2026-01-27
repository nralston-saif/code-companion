import SwiftUI

struct CompanionView: View {
    @ObservedObject var animationController = AnimationController.shared
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var skinManager = SkinManager.shared
    @ObservedObject var notificationQueue = NotificationQueue.shared
    @ObservedObject var petStats = PetStats.shared
    @State private var isHovering = false
    @State private var clickScale: CGFloat = 1.0
    @State private var isDragging = false
    @State private var showTooltip = false
    @State private var isClickAnimating = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.95, green: 0.93, blue: 0.9))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

            PixelCharacter(
                state: animationController.currentState,
                frame: animationController.currentFrame,
                isHovering: isHovering,
                eyeOffset: animationController.eyeOffset,
                breathingScale: animationController.calculateBreathingScale(),
                dragWiggle: animationController.calculateDragWiggle(),
                skin: skinManager.currentSkin,
                mood: petStats.mood
            )
            .scaleEffect(clickScale)

            FloatingElements(state: animationController.currentState, frame: animationController.currentFrame)

            // Bubble overlay
            BubbleOverlay(
                content: animationController.currentBubble,
                frame: animationController.currentFrame
            )

            // Particle effects
            ParticleSystem(
                effect: animationController.currentParticleEffect,
                frame: animationController.currentFrame
            )

            // Notification badge
            NotificationBadge(count: notificationQueue.badgeCount)

            // Status tooltip on hover (at top of window)
            if showTooltip {
                StatusTooltip(message: animationController.statusMessage)
            }
        }
        .frame(width: 80, height: 80)
        .offset(y: -15)  // Push companion up to make room for tooltip below
        .frame(width: 80, height: 110)  // Full window height
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
                // Show tooltip after hovering for a moment
                if hovering && animationController.statusMessage != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if isHovering {
                            withAnimation(.easeIn(duration: 0.2)) {
                                showTooltip = true
                            }
                        }
                    }
                } else {
                    showTooltip = false
                }
            }
            if hovering {
                animationController.onHover()
            } else {
                animationController.onHoverEnd()
            }
        }
        .onTapGesture {
            guard !isClickAnimating else { return }
            isClickAnimating = true

            clickScale = 0.9
            animationController.onClick()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                clickScale = 1.0
                isClickAnimating = false
            }
        }
        .gesture(
            TapGesture(count: 2).onEnded {
                animationController.onDoubleClick()
            }
        )
        .contextMenu {
            // Stats
            Text("Tasks: \(petStats.totalTasks) | ✓ \(petStats.totalSuccesses) | ✗ \(petStats.totalErrors)")

            Divider()

            // Settings submenus
            Menu("Notifications") {
                Toggle("Permission Requests", isOn: $settings.notifyOnPermission)
                Toggle("Task Completion", isOn: $settings.notifyOnCompletion)
                Toggle("Waiting for Input", isOn: $settings.notifyOnIdle)
                Toggle("Errors", isOn: $settings.notifyOnError)
            }

            Menu("Sounds") {
                Toggle("Notification Sounds", isOn: $settings.notificationSounds)
                Toggle("Ambient Sounds", isOn: $settings.ambientSounds)
            }

            Menu("Eye Tracking") {
                Picker("Mode", selection: $settings.eyeTrackingMode) {
                    ForEach(EyeTrackingMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            }

            Menu("Skin") {
                ForEach(CompanionSkin.allSkins) { skin in
                    Button(action: {
                        skinManager.selectSkin(skin)
                    }) {
                        HStack {
                            Text(skin.name)
                            if skinManager.currentSkin.id == skin.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Show Menu Bar Icon", isOn: $settings.showMenuBarIcon)

            Divider()

            Button("Quit Claude Companion") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

struct FloatingElements: View {
    let state: CompanionState
    let frame: Int

    var body: some View {
        ZStack {
            switch state {
            case .sleeping:
                sleepingZs
            case .thinking, .scratchingHead:
                thinkingDots
            case .success, .petted:
                sparkles
            case .attention:
                exclamationMark
            case .giggling:
                hearts
            case .dizzy:
                stars
            case .yawning:
                yawnBubble
            default:
                EmptyView()
            }
        }
    }

    private var sleepingZs: some View {
        ZStack {
            Text("z")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.gray.opacity(0.6))
                .offset(x: 20, y: -20 - CGFloat(frame % 20))
                .opacity(frame % 40 < 20 ? 1 : 0)

            Text("Z")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray.opacity(0.5))
                .offset(x: 25, y: -28 - CGFloat((frame + 10) % 20))
                .opacity((frame + 10) % 40 < 20 ? 1 : 0)

            Text("Z")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray.opacity(0.4))
                .offset(x: 28, y: -36 - CGFloat((frame + 5) % 20))
                .opacity((frame + 20) % 40 < 20 ? 1 : 0)
        }
    }

    private var thinkingDots: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(y: (frame / 8 + i) % 3 == 0 ? -3 : 0)
            }
        }
        .offset(x: 20, y: -15)
    }

    private var sparkles: some View {
        ForEach(0..<4) { i in
            Text("\u{2726}")
                .font(.system(size: 8))
                .foregroundColor(.yellow.opacity(0.8))
                .offset(
                    x: CGFloat([-15, 20, -20, 18][i]),
                    y: CGFloat([-18, -15, 10, 5][i]) - CGFloat(frame % 10)
                )
                .opacity(Double((frame + i * 5) % 30) / 30.0)
        }
    }

    private var exclamationMark: some View {
        Text("!")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.orange)
            .offset(x: 25, y: -20)
            .opacity(frame % 20 < 15 ? 1 : 0.3)
    }

    private var hearts: some View {
        ForEach(0..<3) { i in
            Text("❤")
                .font(.system(size: 8))
                .foregroundColor(.pink.opacity(0.8))
                .offset(
                    x: CGFloat([-12, 15, 0][i]),
                    y: CGFloat([-20, -18, -25][i]) - CGFloat((frame + i * 10) % 15)
                )
                .opacity(Double((frame + i * 8) % 24) / 24.0)
        }
    }

    private var stars: some View {
        ForEach(0..<3) { i in
            Text("★")
                .font(.system(size: 8))
                .foregroundColor(.yellow)
                .offset(
                    x: CGFloat([-15, 18, 0][i]) + sin(Double(frame) * 0.2 + Double(i)) * 3,
                    y: CGFloat([-22, -20, -26][i])
                )
                .opacity(Double((frame + i * 6) % 20) / 20.0)
        }
    }

    private var yawnBubble: some View {
        Text("...")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.gray.opacity(0.5))
            .offset(x: 22, y: -18)
    }
}

import SwiftUI

struct CompanionView: View {
    @ObservedObject var animationController = AnimationController.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var isHovering = false
    @State private var clickScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background with rounded corners
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.95, green: 0.93, blue: 0.9))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

            // The pixel character
            PixelCharacter(
                state: animationController.currentState,
                frame: animationController.currentFrame,
                isHovering: isHovering
            )
            .scaleEffect(clickScale)

            // Floating elements (Z's for sleeping, dots for thinking, etc.)
            FloatingElements(state: animationController.currentState, frame: animationController.currentFrame)
        }
        .frame(width: 80, height: 80)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
            if hovering {
                animationController.onHover()
            } else {
                animationController.onHoverEnd()
            }
        }
        .onTapGesture {
            // Click animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                clickScale = 0.85
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    clickScale = 1.0
                }
            }
            animationController.onClick()
        }
        .gesture(
            TapGesture(count: 2).onEnded {
                animationController.onDoubleClick()
            }
        )
        .contextMenu {
            // Notifications section
            Text("Notifications")
                .font(.headline)

            Toggle("Permission Requests", isOn: $settings.notifyOnPermission)
            Toggle("Task Completion", isOn: $settings.notifyOnCompletion)
            Toggle("Waiting for Input", isOn: $settings.notifyOnIdle)
            Toggle("Errors", isOn: $settings.notifyOnError)

            Divider()

            // Sounds
            Text("Sounds")
                .font(.headline)

            Toggle("Notification Sounds", isOn: $settings.notificationSounds)
            Toggle("Ambient Sounds", isOn: $settings.ambientSounds)

            Divider()

            // Launch at login
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)

            Divider()

            // Quit
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
                // Floating Z's
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

            case .thinking:
                // Thinking dots
                HStack(spacing: 3) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 4, height: 4)
                            .offset(y: (frame / 8 + i) % 3 == 0 ? -3 : 0)
                    }
                }
                .offset(x: 20, y: -15)

            case .success:
                // Sparkles
                ForEach(0..<4) { i in
                    Text("✦")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow.opacity(0.8))
                        .offset(
                            x: CGFloat([-15, 20, -20, 18][i]),
                            y: CGFloat([-18, -15, 10, 5][i]) - CGFloat(frame % 10)
                        )
                        .opacity(Double((frame + i * 5) % 30) / 30.0)
                }

            case .attention:
                // Exclamation
                Text("!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
                    .offset(x: 25, y: -20)
                    .opacity(frame % 20 < 15 ? 1 : 0.3)

            default:
                EmptyView()
            }
        }
    }
}

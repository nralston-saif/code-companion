import SwiftUI

enum ParticleEffect: Equatable {
    case confetti
    case rainCloud
    case hearts
    case sparkles
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var velocity: CGPoint
    var rotation: Double
    var scale: CGFloat
    var opacity: Double
    var color: Color
    var symbol: String
}

struct ParticleSystem: View {
    let effect: ParticleEffect?
    let frame: Int

    var body: some View {
        if let effect = effect {
            ZStack {
                switch effect {
                case .confetti:
                    ConfettiView(frame: frame)
                case .rainCloud:
                    RainCloudView(frame: frame)
                case .hearts:
                    HeartsView(frame: frame)
                case .sparkles:
                    SparklesView(frame: frame)
                }
            }
        }
    }
}

struct ConfettiView: View {
    let frame: Int

    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

    var body: some View {
        ForEach(0..<12) { i in
            confettiPiece(index: i)
        }
    }

    @ViewBuilder
    private func confettiPiece(index: Int) -> some View {
        let phase = Double(frame + index * 8) * 0.1
        let xOffset = CGFloat([-20, -10, 0, 10, 20, -15, 5, 15, -5, 25, -25, 12][index % 12])
        let yStart: CGFloat = -30
        let yOffset = CGFloat((frame + index * 5) % 60) - 10

        Rectangle()
            .fill(colors[index % colors.count])
            .frame(width: 4, height: 4)
            .rotationEffect(.degrees(Double(frame * 5 + index * 30)))
            .offset(
                x: xOffset + sin(phase) * 5,
                y: yStart + yOffset
            )
            .opacity(yOffset < 50 ? 1.0 : max(0.0, 1.0 - Double(yOffset - 50) / 10.0))
    }
}

struct RainCloudView: View {
    let frame: Int

    var body: some View {
        ZStack {
            // Cloud
            cloudShape
                .offset(x: 20, y: -25)

            // Rain drops
            ForEach(0..<5) { i in
                rainDrop(index: i)
            }
        }
    }

    private var cloudShape: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 12, height: 12)
                .offset(x: -5, y: 2)

            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 16, height: 16)
                .offset(x: 3, y: 0)

            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 10, height: 10)
                .offset(x: 10, y: 3)
        }
    }

    @ViewBuilder
    private func rainDrop(index: Int) -> some View {
        let xOffset = CGFloat([15, 20, 25, 18, 22][index])
        let yPhase = CGFloat((frame + index * 6) % 20)

        Text("💧")
            .font(.system(size: 6))
            .offset(x: xOffset, y: -12 + yPhase)
            .opacity(yPhase < 15 ? 0.8 : 0.8 - Double(yPhase - 15) / 5)
    }
}

struct HeartsView: View {
    let frame: Int

    var body: some View {
        ForEach(0..<5) { i in
            heart(index: i)
        }
    }

    @ViewBuilder
    private func heart(index: Int) -> some View {
        let xOffset = CGFloat([-12, 8, -5, 15, 0][index])
        let yPhase = CGFloat((frame + index * 8) % 30)
        let scale = 0.8 + sin(Double(frame + index * 10) * 0.2) * 0.2

        Text("❤️")
            .font(.system(size: 8))
            .scaleEffect(scale)
            .offset(
                x: xOffset + sin(Double(frame + index * 5) * 0.15) * 3,
                y: -20 - yPhase * 0.5
            )
            .opacity(1 - Double(yPhase) / 30)
    }
}

struct SparklesView: View {
    let frame: Int

    var body: some View {
        ForEach(0..<6) { i in
            sparkle(index: i)
        }
    }

    @ViewBuilder
    private func sparkle(index: Int) -> some View {
        let angle = Double(index) * .pi / 3 + Double(frame) * 0.05
        let radius: CGFloat = 25 + CGFloat(sin(Double(frame + index * 10) * 0.2)) * 5
        let xOffset = cos(angle) * radius
        let yOffset = sin(angle) * radius - 5

        Text("✨")
            .font(.system(size: 8))
            .offset(x: xOffset, y: yOffset)
            .opacity(0.5 + sin(Double(frame + index * 15) * 0.3) * 0.5)
    }
}

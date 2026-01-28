import SwiftUI

enum BubbleType {
    case speech
    case thought
}

struct BubbleContent: Equatable {
    let text: String
    let emoji: String?
    let type: BubbleType

    init(text: String = "", emoji: String? = nil, type: BubbleType = .speech) {
        self.text = text
        self.emoji = emoji
        self.type = type
    }
}

struct BubbleOverlay: View {
    let content: BubbleContent?
    let frame: Int

    private var opacity: Double {
        content != nil ? 1.0 : 0.0
    }

    var body: some View {
        if let content = content {
            ZStack {
                // Bubble background
                bubbleBackground(type: content.type)

                // Content
                Group {
                    if let emoji = content.emoji {
                        Text(emoji)
                            .font(.system(size: 14))
                    } else {
                        Text(content.text)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .frame(width: 40, height: 24)
            .offset(x: 30, y: -28)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func bubbleBackground(type: BubbleType) -> some View {
        Group {
            switch type {
            case .speech:
                SpeechBubbleShape()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            case .thought:
                ThoughtBubbleShape()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            }
        }
    }
}

struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 6
        let tailSize: CGFloat = 6

        // Main rounded rectangle
        let bubbleRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - tailSize
        )

        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        // Tail pointing down-left
        path.move(to: CGPoint(x: rect.minX + 8, y: rect.maxY - tailSize))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 14, y: rect.maxY - tailSize))

        return path
    }
}

struct ThoughtBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Main oval
        let bubbleRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - 8
        )
        path.addEllipse(in: bubbleRect)

        // Small thought dots
        path.addEllipse(in: CGRect(x: rect.minX + 4, y: rect.maxY - 8, width: 5, height: 5))
        path.addEllipse(in: CGRect(x: rect.minX + 1, y: rect.maxY - 4, width: 3, height: 3))

        return path
    }
}

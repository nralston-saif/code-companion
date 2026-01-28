import SwiftUI

struct CompanionNotification: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let emoji: String?
    let timestamp: Date
    let priority: NotificationPriority

    init(message: String, emoji: String? = nil, priority: NotificationPriority = .normal) {
        self.message = message
        self.emoji = emoji
        self.timestamp = Date()
        self.priority = priority
    }
}

enum NotificationPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2

    static func < (lhs: NotificationPriority, rhs: NotificationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

class NotificationQueue: ObservableObject {
    static let shared = NotificationQueue()

    @Published var notifications: [CompanionNotification] = []
    @Published var currentNotification: CompanionNotification? = nil

    private var displayTimer: Timer?
    private let maxQueueSize = 10
    private let displayDuration: TimeInterval = 3.0

    var badgeCount: Int {
        notifications.count
    }

    var hasNotifications: Bool {
        !notifications.isEmpty
    }

    func enqueue(_ notification: CompanionNotification) {
        // Add to queue
        notifications.append(notification)

        // Sort by priority (higher first), then by timestamp
        notifications.sort { ($0.priority, $0.timestamp) > ($1.priority, $1.timestamp) }

        // Trim if over max size
        if notifications.count > maxQueueSize {
            notifications = Array(notifications.prefix(maxQueueSize))
        }

        // Display if not currently showing one
        if currentNotification == nil {
            displayNext()
        }
    }

    func enqueue(message: String, emoji: String? = nil, priority: NotificationPriority = .normal) {
        enqueue(CompanionNotification(message: message, emoji: emoji, priority: priority))
    }

    func dismiss() {
        currentNotification = nil
        displayTimer?.invalidate()
        displayNext()
    }

    func dismissAll() {
        notifications.removeAll()
        currentNotification = nil
        displayTimer?.invalidate()
    }

    private func displayNext() {
        guard !notifications.isEmpty else {
            currentNotification = nil
            return
        }

        let next = notifications.removeFirst()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentNotification = next
        }

        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
            withAnimation(.easeOut(duration: 0.2)) {
                self?.currentNotification = nil
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.displayNext()
            }
        }
    }
}

// MARK: - Badge View

struct NotificationBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 16, height: 16)

                Text(count > 9 ? "9+" : "\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            }
            .offset(x: 32, y: -32)
        }
    }
}

// MARK: - Tooltip View

struct StatusTooltip: View {
    let message: String?

    var body: some View {
        if let message = message, !message.isEmpty {
            Text(message)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.8))
                )
                .offset(y: 50)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

import Foundation
import Network

class StateManager {
    static let shared = StateManager()

    private var listener: NWListener?
    private let port: UInt16 = 52532
    private let animationController = AnimationController.shared
    private let petStats = PetStats.shared
    private var lastHeartbeat = Date()
    private var heartbeatTimer: Timer?
    private let heartbeatTimeout: TimeInterval = 30

    init() {
        startHeartbeatMonitor()
    }

    func startServer() {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        guard let port = NWEndpoint.Port(rawValue: port),
              let newListener = try? NWListener(using: parameters, on: port) else {
            print("Failed to start server")
            return
        }

        listener = newListener
        listener?.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                print("Code Companion server listening on port \(self?.port ?? 0)")
            } else if case .failed(let error) = state {
                print("Server failed: \(error)")
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.start(queue: .main)
    }

    func stopServer() {
        listener?.cancel()
        heartbeatTimer?.invalidate()
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.processRequest(data: data, connection: connection)
            }

            if isComplete || error != nil {
                connection.cancel()
            }
        }
    }

    private func processRequest(data: Data, connection: NWConnection) {
        guard let requestString = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, status: 400, body: "Invalid request")
            return
        }

        let lines = requestString.split(separator: "\r\n")
        guard let firstLine = lines.first else {
            sendResponse(connection: connection, status: 400, body: "Invalid request")
            return
        }

        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2 else {
            sendResponse(connection: connection, status: 400, body: "Invalid request")
            return
        }

        let method = String(parts[0])
        let path = String(parts[1])

        var body: String?
        if let emptyLineIndex = lines.firstIndex(of: "") {
            body = lines.dropFirst(emptyLineIndex + 1).joined(separator: "\r\n")
        }

        if body == nil || body?.isEmpty == true,
           let jsonStart = requestString.firstIndex(of: "{") {
            body = String(requestString[jsonStart...])
        }

        handleRequest(method: method, path: path, body: body, connection: connection)
    }

    private func handleRequest(method: String, path: String, body: String?, connection: NWConnection) {
        lastHeartbeat = Date()

        if animationController.currentState == .sleeping {
            animationController.setState(.idle)
        }

        switch (method, path) {
        case ("POST", "/state"):
            handleStateChange(body: body, connection: connection)
        case ("POST", "/notify"):
            handleNotify(body: body, connection: connection)
        case ("POST", "/heartbeat"):
            handleHeartbeat(connection: connection)
        case ("GET", "/status"):
            handleStatus(connection: connection)
        case ("POST", "/sleep"):
            handleSleep(connection: connection)
        case ("POST", "/bubble"):
            handleBubble(body: body, connection: connection)
        case ("POST", "/particles"):
            handleParticles(body: body, connection: connection)
        case ("POST", "/status"):
            handleSetStatus(body: body, connection: connection)
        case ("POST", "/notification"):
            handleNotification(body: body, connection: connection)
        default:
            sendResponse(connection: connection, status: 404, body: "Not found")
        }
    }

    private func handleStateChange(body: String?, connection: NWConnection) {
        guard let body = body,
              let data = body.data(using: .utf8),
              let json = try? JSONDecoder().decode(StateRequest.self, from: data),
              let state = CompanionState(rawValue: json.state) else {
            sendResponse(connection: connection, status: 400, body: "Invalid JSON or state")
            return
        }

        DispatchQueue.main.async {
            // Track pet stats based on state
            switch state {
            case .working, .thinking:
                self.petStats.onTaskStarted()
            case .success:
                self.petStats.onSuccess()
            case .error:
                self.petStats.onError()
            default:
                self.petStats.onInteraction()
            }

            if let duration = json.duration {
                self.animationController.setTemporaryState(state, duration: duration)
            } else {
                self.animationController.setState(state)
            }
        }

        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    private func handleNotify(body: String?, connection: NWConnection) {
        guard let body = body,
              let data = body.data(using: .utf8),
              let json = try? JSONDecoder().decode(NotifyRequest.self, from: data) else {
            sendResponse(connection: connection, status: 400, body: "Invalid JSON")
            return
        }

        DispatchQueue.main.async {
            self.animationController.setState(.attention, duration: json.duration ?? 3.0)
        }

        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    private func handleHeartbeat(connection: NWConnection) {
        lastHeartbeat = Date()
        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    private func handleStatus(connection: NWConnection) {
        let status = StatusResponse(
            state: animationController.currentState.rawValue,
            awake: animationController.currentState != .sleeping
        )

        guard let jsonData = try? JSONEncoder().encode(status),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            sendResponse(connection: connection, status: 500, body: "Internal error")
            return
        }

        sendResponse(connection: connection, status: 200, body: jsonString)
    }

    private func handleSleep(connection: NWConnection) {
        DispatchQueue.main.async {
            self.animationController.setState(.sleeping)
        }
        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    private func handleBubble(body: String?, connection: NWConnection) {
        guard let body = body,
              let data = body.data(using: .utf8),
              let json = try? JSONDecoder().decode(BubbleRequest.self, from: data) else {
            sendResponse(connection: connection, status: 400, body: "Invalid JSON")
            return
        }

        DispatchQueue.main.async {
            if let emoji = json.emoji {
                self.animationController.showBubble(emoji: emoji, duration: json.duration ?? 2.0)
            } else if let text = json.text {
                let bubbleType: BubbleType = json.type == "thought" ? .thought : .speech
                self.animationController.showBubble(text: text, type: bubbleType, duration: json.duration ?? 3.0)
            } else {
                self.animationController.hideBubble()
            }
        }

        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    private func handleParticles(body: String?, connection: NWConnection) {
        guard let body = body,
              let data = body.data(using: .utf8),
              let json = try? JSONDecoder().decode(ParticleRequest.self, from: data) else {
            sendResponse(connection: connection, status: 400, body: "Invalid JSON")
            return
        }

        DispatchQueue.main.async {
            if let effectName = json.effect {
                let effect: ParticleEffect?
                switch effectName {
                case "confetti": effect = .confetti
                case "rain", "rainCloud": effect = .rainCloud
                case "hearts": effect = .hearts
                case "sparkles": effect = .sparkles
                default: effect = nil
                }

                if let effect = effect {
                    self.animationController.showParticles(effect, duration: json.duration ?? 2.0)
                }
            } else {
                self.animationController.hideParticles()
            }
        }

        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    private func handleSetStatus(body: String?, connection: NWConnection) {
        guard let body = body,
              let data = body.data(using: .utf8),
              let json = try? JSONDecoder().decode(SetStatusRequest.self, from: data) else {
            sendResponse(connection: connection, status: 400, body: "Invalid JSON")
            return
        }

        DispatchQueue.main.async {
            self.animationController.setStatus(json.message)
        }

        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    private func handleNotification(body: String?, connection: NWConnection) {
        guard let body = body,
              let data = body.data(using: .utf8),
              let json = try? JSONDecoder().decode(NotificationQueueRequest.self, from: data) else {
            sendResponse(connection: connection, status: 400, body: "Invalid JSON")
            return
        }

        DispatchQueue.main.async {
            let priority: NotificationPriority
            switch json.priority ?? "normal" {
            case "low": priority = .low
            case "high": priority = .high
            default: priority = .normal
            }

            NotificationQueue.shared.enqueue(
                message: json.message,
                emoji: json.emoji,
                priority: priority
            )
        }

        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    private func startHeartbeatMonitor() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let timeSinceHeartbeat = Date().timeIntervalSince(self.lastHeartbeat)

            if timeSinceHeartbeat > self.heartbeatTimeout && self.animationController.currentState != .sleeping {
                DispatchQueue.main.async {
                    self.animationController.setState(.sleeping)
                }
            }
        }
    }

    private func sendResponse(connection: NWConnection, status: Int, body: String) {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        case 500: statusText = "Internal Server Error"
        default: statusText = "Unknown"
        }

        let response = """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """

        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

struct StateRequest: Codable {
    let state: String
    let duration: TimeInterval?
}

struct NotifyRequest: Codable {
    let message: String?
    let duration: TimeInterval?
}

struct StatusResponse: Codable {
    let state: String
    let awake: Bool
}

struct BubbleRequest: Codable {
    let text: String?
    let emoji: String?
    let type: String?
    let duration: TimeInterval?
}

struct ParticleRequest: Codable {
    let effect: String?
    let duration: TimeInterval?
}

struct SetStatusRequest: Codable {
    let message: String?
}

struct NotificationQueueRequest: Codable {
    let message: String
    let emoji: String?
    let priority: String?
}

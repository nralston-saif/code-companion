import Foundation
import Network

class StateManager {
    static let shared = StateManager()

    private var listener: NWListener?
    private let port: UInt16 = 52532  // "CLAUD" on phone keypad :)
    private let animationController = AnimationController.shared

    private var lastHeartbeat: Date = Date()
    private var heartbeatTimer: Timer?
    private let heartbeatTimeout: TimeInterval = 30  // Go to sleep if no heartbeat for 30 seconds

    init() {
        startHeartbeatMonitor()
    }

    func startServer() {
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true

            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)

            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Claude Companion server listening on port \(self.port)")
                case .failed(let error):
                    print("Server failed: \(error)")
                default:
                    break
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener?.start(queue: .main)
        } catch {
            print("Failed to start server: \(error)")
        }
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

        // Parse HTTP request
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

        // Find body (after empty line)
        var body: String? = nil
        if let emptyLineIndex = lines.firstIndex(of: "") {
            let bodyLines = lines.dropFirst(emptyLineIndex + 1)
            body = bodyLines.joined(separator: "\r\n")
        }

        // Also check for body without proper HTTP headers separation
        if body == nil || body?.isEmpty == true {
            if let jsonStart = requestString.firstIndex(of: "{") {
                body = String(requestString[jsonStart...])
            }
        }

        handleRequest(method: method, path: path, body: body, connection: connection)
    }

    private func handleRequest(method: String, path: String, body: String?, connection: NWConnection) {
        // Update heartbeat on any request
        lastHeartbeat = Date()

        // Wake up if sleeping
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

        default:
            sendResponse(connection: connection, status: 404, body: "Not found")
        }
    }

    // MARK: - Request Handlers

    private func handleStateChange(body: String?, connection: NWConnection) {
        guard let body = body,
              let data = body.data(using: .utf8),
              let json = try? JSONDecoder().decode(StateRequest.self, from: data) else {
            sendResponse(connection: connection, status: 400, body: "Invalid JSON")
            return
        }

        guard let state = CompanionState(rawValue: json.state) else {
            sendResponse(connection: connection, status: 400, body: "Invalid state: \(json.state)")
            return
        }

        DispatchQueue.main.async {
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
            // Show attention state
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

        if let jsonData = try? JSONEncoder().encode(status),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            sendResponse(connection: connection, status: 200, body: jsonString)
        } else {
            sendResponse(connection: connection, status: 500, body: "Internal error")
        }
    }

    private func handleSleep(connection: NWConnection) {
        DispatchQueue.main.async {
            self.animationController.setState(.sleeping)
        }
        sendResponse(connection: connection, status: 200, body: "{\"success\": true}")
    }

    // MARK: - Heartbeat Monitor

    private func startHeartbeatMonitor() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let timeSinceHeartbeat = Date().timeIntervalSince(self.lastHeartbeat)

            if timeSinceHeartbeat > self.heartbeatTimeout {
                // No heartbeat - Claude not running, go to sleep
                if self.animationController.currentState != .sleeping {
                    DispatchQueue.main.async {
                        self.animationController.setState(.sleeping)
                    }
                }
            }
        }
    }

    // MARK: - HTTP Response

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

// MARK: - Request/Response Models

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

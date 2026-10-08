import Foundation

/// Represents the high-level user session lifecycle.
public enum SessionState: Sendable, Equatable {
    case unauthenticated
    case authenticating
    case authenticated(userId: String)
    case expired

    public var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
}

/// Interface for session state observation and control.
public protocol SessionManaging: Sendable {
    var currentState: SessionState { get async }
    func setAuthenticated(userId: String) async
    func setExpired() async
    func logout() async throws
    func addObserver(_ observer: @escaping @Sendable (SessionState) -> Void) async -> UUID
    func removeObserver(id: UUID) async
}

/// Actor managing active user session lifecycle and notifying observers.
public actor SessionManager: SessionManaging {
    public static let shared = SessionManager()

    private var state: SessionState = .unauthenticated
    private let tokenManager: any TokenManaging
    private var observers: [UUID: @Sendable (SessionState) -> Void] = [:]

    public init(tokenManager: any TokenManaging = TokenManager()) {
        self.tokenManager = tokenManager
    }

    public var currentState: SessionState {
        return state
    }

    public func setAuthenticated(userId: String) {
        self.state = .authenticated(userId: userId)
        notifyObservers()
    }

    public func setExpired() {
        self.state = .expired
        notifyObservers()
    }

    public func logout() async throws {
        try await tokenManager.clearTokens()
        self.state = .unauthenticated
        notifyObservers()
    }

    public func addObserver(_ observer: @escaping @Sendable (SessionState) -> Void) -> UUID {
        let id = UUID()
        observers[id] = observer
        observer(state)
        return id
    }

    public func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }

    private func notifyObservers() {
        let current = state
        for observer in observers.values {
            observer(current)
        }
    }
}

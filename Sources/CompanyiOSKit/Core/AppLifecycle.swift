import Foundation

/// Canonical application lifecycle states.
public enum AppLifecycleState: String, Sendable, CaseIterable {
    case active
    case inactive
    case background
    case terminated
}

/// Protocol defining observation and inquiry into app lifecycle state.
public protocol AppLifecycleObserving: Sendable {
    var currentState: AppLifecycleState { get async }
    func addObserver(_ observer: @escaping @Sendable (AppLifecycleState) -> Void) async -> UUID
    func removeObserver(id: UUID) async
}

/// Thread-safe coordinator for tracking application lifecycle transitions.
public actor AppLifecycleCoordinator: AppLifecycleObserving {
    public static let shared = AppLifecycleCoordinator()

    private var state: AppLifecycleState = .active
    private var observers: [UUID: @Sendable (AppLifecycleState) -> Void] = [:]

    public init(initialState: AppLifecycleState = .active) {
        self.state = initialState
    }

    public var currentState: AppLifecycleState {
        return state
    }

    public func transition(to newState: AppLifecycleState) {
        guard state != newState else { return }
        self.state = newState
        for observer in observers.values {
            observer(newState)
        }
    }

    public func addObserver(_ observer: @escaping @Sendable (AppLifecycleState) -> Void) -> UUID {
        let id = UUID()
        observers[id] = observer
        observer(state)
        return id
    }

    public func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }
}

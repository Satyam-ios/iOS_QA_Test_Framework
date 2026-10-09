import Foundation

/// Event representing a screen presentation recorded at runtime.
public struct ObservedScreenEvent: Codable, Sendable, Equatable {
    public let screenName: String
    public let route: String
    public let viewClassName: String?
    public let timestamp: Date

    public init(
        screenName: String,
        route: String,
        viewClassName: String? = nil,
        timestamp: Date = Date()
    ) {
        self.screenName = screenName
        self.route = route
        self.viewClassName = viewClassName
        self.timestamp = timestamp
    }
}

/// Passive runtime observer monitoring screen presentations and recording runtime navigation flows.
public final class RuntimeScreenObserver: @unchecked Sendable {
    public static let shared = RuntimeScreenObserver()

    private let lock = NSLock()
    private var isObserving: Bool = false
    private var presentationHistory: [ObservedScreenEvent] = []

    private init() {}

    /// Starts passive observation of runtime screen events.
    public func startObserving() {
        lock.lock()
        defer { lock.unlock() }
        isObserving = true
    }

    /// Stops runtime observation.
    public func stopObserving() {
        lock.lock()
        defer { lock.unlock() }
        isObserving = false
    }

    /// Called by host app navigation coordinator, UIKit viewDidAppear, or SwiftUI onAppear to notify presentation.
    public func notifyScreenPresented(
        name: String,
        route: String,
        viewClassName: String? = nil,
        elements: [UIElementDescriptor] = []
    ) {
        lock.lock()
        let event = ObservedScreenEvent(screenName: name, route: route, viewClassName: viewClassName)
        presentationHistory.append(event)
        let active = isObserving
        lock.unlock()

        if active {
            // Register or update screen in central ScreenRegistry
            ScreenRegistry.shared.recordRuntimeScreen(
                name: name,
                route: route,
                viewClass: viewClassName,
                elements: elements
            )
        }
    }

    /// Complete history of screen presentations captured during this session.
    public var observedHistory: [ObservedScreenEvent] {
        lock.lock()
        defer { lock.unlock() }
        return presentationHistory
    }

    /// Clears observed runtime history.
    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        presentationHistory.removeAll()
    }
}

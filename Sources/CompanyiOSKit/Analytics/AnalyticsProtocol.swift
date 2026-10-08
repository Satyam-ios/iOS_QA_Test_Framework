import Foundation

/// Canonical analytics event model.
public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: [String: String]
    public let timestamp: Date

    public init(name: String, parameters: [String: String] = [:], timestamp: Date = Date()) {
        self.name = name
        self.parameters = parameters
        self.timestamp = timestamp
    }
}

/// Interface for analytics event sinks.
public protocol AnalyticsServiceProtocol: Sendable {
    func track(event: AnalyticsEvent) async
    func setUserProperty(key: String, value: String?) async
}

/// Dispatcher supporting fan-out to multiple analytics backends.
public actor CompositeAnalyticsService: AnalyticsServiceProtocol {
    private var providers: [any AnalyticsServiceProtocol] = []

    public init(providers: [any AnalyticsServiceProtocol] = []) {
        self.providers = providers
    }

    public func addProvider(_ provider: any AnalyticsServiceProtocol) {
        providers.append(provider)
    }

    public func track(event: AnalyticsEvent) async {
        for provider in providers {
            await provider.track(event: event)
        }
    }

    public func setUserProperty(key: String, value: String?) async {
        for provider in providers {
            await provider.setUserProperty(key: key, value: value)
        }
    }
}

import Foundation

/// Defines a feature flag key.
public struct FeatureFlag: Hashable, Sendable, ExpressibleByStringLiteral {
    public let key: String
    public let defaultValue: Bool

    public init(key: String, defaultValue: Bool = false) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public init(stringLiteral value: String) {
        self.key = value
        self.defaultValue = false
    }
}

/// Protocol for querying and managing feature flags.
public protocol FeatureFlagManaging: Sendable {
    func isEnabled(_ flag: FeatureFlag) async -> Bool
    func setOverride(_ flag: FeatureFlag, isEnabled: Bool) async
    func clearOverride(_ flag: FeatureFlag) async
    func clearAllOverrides() async
}

/// Actor providing thread-safe storage for feature flag evaluation.
public actor FeatureFlagManager: FeatureFlagManaging {
    public static let shared = FeatureFlagManager()

    private var overrides: [String: Bool] = [:]
    private var remoteValues: [String: Bool] = [:]

    public init() {}

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        if let overridden = overrides[flag.key] {
            return overridden
        }
        if let remote = remoteValues[flag.key] {
            return remote
        }
        return flag.defaultValue
    }

    public func setOverride(_ flag: FeatureFlag, isEnabled: Bool) {
        overrides[flag.key] = isEnabled
    }

    public func clearOverride(_ flag: FeatureFlag) {
        overrides.removeValue(forKey: flag.key)
    }

    public func clearAllOverrides() {
        overrides.removeAll()
    }

    public func updateRemoteFlags(_ values: [String: Bool]) {
        self.remoteValues.merge(values) { _, new in new }
    }
}

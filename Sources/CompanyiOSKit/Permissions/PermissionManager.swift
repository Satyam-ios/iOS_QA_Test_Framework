import Foundation

/// Canonical system permissions requested by iOS applications.
public enum AppPermission: String, Sendable, CaseIterable {
    case camera
    case microphone
    case contacts
    case notifications
    case location
}

/// Authorization status for a permission.
public enum PermissionStatus: String, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

/// Protocol managing permission queries and status.
public protocol PermissionManaging: Sendable {
    func status(for permission: AppPermission) async -> PermissionStatus
    func requestPermission(_ permission: AppPermission) async -> PermissionStatus
}

/// Actor managing permission state and requests.
public actor PermissionManager: PermissionManaging {
    public static let shared = PermissionManager()

    private var simulatedStatuses: [AppPermission: PermissionStatus] = [:]

    public init() {}

    public func setSimulatedStatus(_ status: PermissionStatus, for permission: AppPermission) {
        simulatedStatuses[permission] = status
    }

    public func status(for permission: AppPermission) -> PermissionStatus {
        return simulatedStatuses[permission] ?? .notDetermined
    }

    public func requestPermission(_ permission: AppPermission) -> PermissionStatus {
        if let current = simulatedStatuses[permission], current != .notDetermined {
            return current
        }
        let granted = PermissionStatus.authorized
        simulatedStatuses[permission] = granted
        return granted
    }
}

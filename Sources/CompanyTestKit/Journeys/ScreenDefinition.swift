import Foundation

/// Types of UI controls identified in a screen.
public enum UIElementType: String, Codable, Sendable {
    case button
    case textField
    case secureField
    case label
    case image
    case toggle
    case list
    case navigationBar
    case loadingIndicator
    case emptyStateView
    case errorBanner
    case custom
}

/// Description of an individual UI control on a screen.
public struct UIElementDescriptor: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let type: UIElementType
    public let accessibilityIdentifier: String?
    public let accessibilityLabel: String?
    public var isEnabled: Bool
    public var isVisible: Bool
    public var textContent: String?

    public init(
        id: String,
        type: UIElementType,
        accessibilityIdentifier: String? = nil,
        accessibilityLabel: String? = nil,
        isEnabled: Bool = true,
        isVisible: Bool = true,
        textContent: String? = nil
    ) {
        self.id = id
        self.type = type
        self.accessibilityIdentifier = accessibilityIdentifier ?? id
        self.accessibilityLabel = accessibilityLabel
        self.isEnabled = isEnabled
        self.isVisible = isVisible
        self.textContent = textContent
    }
}

/// Screen presentation states.
public enum ScreenStateKind: Codable, Sendable, Equatable, Hashable {
    case normal
    case loading
    case empty
    case error(message: String)

    public var title: String {
        switch self {
        case .normal: return "Normal"
        case .loading: return "Loading"
        case .empty: return "Empty"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

/// Descriptor for a user action available on a screen.
public struct UserActionDescriptor: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let targetElementId: String
    public let targetRoute: String?

    public init(
        id: String,
        name: String,
        targetElementId: String,
        targetRoute: String? = nil
    ) {
        self.id = id
        self.name = name
        self.targetElementId = targetElementId
        self.targetRoute = targetRoute
    }
}

/// Origin of screen discovery.
public enum ScreenDiscoverySource: String, Codable, Sendable {
    case explicitRegistration = "Explicit Registration"
    case staticSourceAnalysis = "Static Source Analysis"
    case runtimeObservation = "Runtime Observation"
    case dynamicInferred = "Dynamic Inferred"
}

/// Aggregated test execution counts for an individual screen.
public struct ScreenTestMetrics: Codable, Sendable, Equatable, Hashable {
    public var generatedCount: Int
    public var executedCount: Int
    public var passedCount: Int
    public var failedCount: Int
    public var blockedCount: Int
    public var notExecutedCount: Int

    public init(
        generatedCount: Int = 0,
        executedCount: Int = 0,
        passedCount: Int = 0,
        failedCount: Int = 0,
        blockedCount: Int = 0,
        notExecutedCount: Int = 0
    ) {
        self.generatedCount = generatedCount
        self.executedCount = executedCount
        self.passedCount = passedCount
        self.failedCount = failedCount
        self.blockedCount = blockedCount
        self.notExecutedCount = notExecutedCount
    }
}

/// Complete structural model of an application screen.
public struct ScreenDefinition: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let route: String
    public var elements: [UIElementDescriptor]
    public var apiDependencies: [String]
    public var availableStates: [ScreenStateKind]
    public var supportedActions: [UserActionDescriptor]

    // Discovery and Architecture Metadata
    public var sourceFile: String?
    public var sourceLine: Int?
    public var featureModule: String?
    public var discoverySource: ScreenDiscoverySource
    public var linkedPermissions: [String]
    public var linkedDefectIds: [String]
    public var testMetrics: ScreenTestMetrics
    public var securityFindingsCount: Int
    public var runtimeIssuesCount: Int
    public var viewClassName: String?

    public init(
        id: String,
        name: String,
        route: String,
        elements: [UIElementDescriptor] = [],
        apiDependencies: [String] = [],
        availableStates: [ScreenStateKind] = [.normal],
        supportedActions: [UserActionDescriptor] = [],
        sourceFile: String? = nil,
        sourceLine: Int? = nil,
        featureModule: String? = nil,
        discoverySource: ScreenDiscoverySource = .explicitRegistration,
        linkedPermissions: [String] = [],
        linkedDefectIds: [String] = [],
        testMetrics: ScreenTestMetrics = ScreenTestMetrics(),
        securityFindingsCount: Int = 0,
        runtimeIssuesCount: Int = 0,
        viewClassName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.route = route
        self.elements = elements
        self.apiDependencies = apiDependencies
        self.availableStates = availableStates
        self.supportedActions = supportedActions
        self.sourceFile = sourceFile
        self.sourceLine = sourceLine
        self.featureModule = featureModule
        self.discoverySource = discoverySource
        self.linkedPermissions = linkedPermissions
        self.linkedDefectIds = linkedDefectIds
        self.testMetrics = testMetrics
        self.securityFindingsCount = securityFindingsCount
        self.runtimeIssuesCount = runtimeIssuesCount
        self.viewClassName = viewClassName
    }
}

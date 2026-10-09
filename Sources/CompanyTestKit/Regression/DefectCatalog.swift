import Foundation

/// Lifecycle states of a reported defect.
public enum DefectStatus: String, Codable, Sendable, CaseIterable {
    case new = "NEW"
    case triaged = "TRIAGED"
    case fixInProgress = "FIX_IN_PROGRESS"
    case fixedPendingVerification = "FIXED_PENDING_VERIFICATION"
    case verified = "VERIFIED"
    case reopened = "REOPENED"
    case acceptedRisk = "ACCEPTED_RISK"
}

/// Severity classification for defects.
public enum DefectSeverity: String, Codable, Sendable, CaseIterable, Comparable {
    case info = "INFO"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"

    private var rank: Int {
        switch self {
        case .info: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }

    public static func < (lhs: DefectSeverity, rhs: DefectSeverity) -> Bool {
        return lhs.rank < rhs.rank
    }
}

/// Category classification for defects.
public enum DefectCategory: String, Codable, Sendable, CaseIterable {
    case crash = "CRASH"
    case functional = "FUNCTIONAL"
    case ui = "UI"
    case network = "NETWORK"
    case security = "SECURITY"
    case performance = "PERFORMANCE"
    case dataLoss = "DATA_LOSS"
}

/// Comprehensive record of a defect preserving historical intelligence, evidence, and regression invariants.
public struct DefectRecord: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let affectedScreen: String
    public let rootCause: String
    public let regressionPattern: String
    public let riskLevel: AIRiskLevel
    public let reproductionSteps: [String]
    public var verifiedFixed: Bool
    
    // Enhanced Fields (Requirement 10)
    public var status: DefectStatus
    public var severity: DefectSeverity
    public var category: DefectCategory
    public var sourceFile: String?
    public var lineRange: String?
    public var expectedBehavior: String?
    public var actualBehavior: String?
    public var evidenceLogs: [String]
    public var isVerifiedRootCause: Bool
    public var recommendedCorrection: String?
    public var alternativeApproaches: [String]
    public var linkedRegressionTestId: String?
    public var timestamp: Date

    public init(
        id: String,
        title: String,
        affectedScreen: String,
        rootCause: String,
        regressionPattern: String,
        riskLevel: AIRiskLevel = .high,
        reproductionSteps: [String] = [],
        verifiedFixed: Bool = true,
        status: DefectStatus? = nil,
        severity: DefectSeverity? = nil,
        category: DefectCategory = .functional,
        sourceFile: String? = nil,
        lineRange: String? = nil,
        expectedBehavior: String? = nil,
        actualBehavior: String? = nil,
        evidenceLogs: [String] = [],
        isVerifiedRootCause: Bool = true,
        recommendedCorrection: String? = nil,
        alternativeApproaches: [String] = [],
        linkedRegressionTestId: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.affectedScreen = affectedScreen
        self.rootCause = rootCause
        self.regressionPattern = regressionPattern
        self.riskLevel = riskLevel
        self.reproductionSteps = reproductionSteps
        self.verifiedFixed = verifiedFixed
        
        // Map status cleanly: if verifiedFixed, default status is .verified
        self.status = status ?? (verifiedFixed ? .verified : .new)
        
        // Map severity from riskLevel if not explicitly specified
        if let severity = severity {
            self.severity = severity
        } else {
            switch riskLevel {
            case .critical: self.severity = .critical
            case .high: self.severity = .high
            case .medium: self.severity = .medium
            case .low: self.severity = .low
            }
        }
        
        self.category = category
        self.sourceFile = sourceFile
        self.lineRange = lineRange
        self.expectedBehavior = expectedBehavior
        self.actualBehavior = actualBehavior
        self.evidenceLogs = evidenceLogs
        self.isVerifiedRootCause = isVerifiedRootCause
        self.recommendedCorrection = recommendedCorrection
        self.alternativeApproaches = alternativeApproaches
        self.linkedRegressionTestId = linkedRegressionTestId ?? "REG_\(id)"
        self.timestamp = timestamp
    }
}

/// Central catalog preserving historical defects and synthesizing regression test suites.
public final class DefectCatalog: @unchecked Sendable {
    public static let shared = DefectCatalog()

    private let lock = NSLock()
    private var defects: [String: DefectRecord] = [:]

    private init() {
        populateBaselineDefects()
    }

    /// Records or updates a defect in the catalog.
    public func recordDefect(_ defect: DefectRecord) {
        lock.lock()
        defer { lock.unlock() }
        defects[defect.id] = defect
    }

    /// Updates the lifecycle status of an existing defect with invariant validation.
    @discardableResult
    public func updateStatus(
        id: String,
        newStatus: DefectStatus,
        verifiedByTest: Bool = false,
        verifiedByTestId: String? = nil
    ) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard var defect = defects[id] else { return false }

        // Invariant guard: Cannot mark as verified without verification confirmation
        let hasVerification = verifiedByTest || verifiedByTestId != nil || defect.verifiedFixed
        if newStatus == .verified && !hasVerification {
            return false
        }

        defect.status = newStatus
        if newStatus == .verified {
            defect.verifiedFixed = true
            if let testId = verifiedByTestId {
                defect.linkedRegressionTestId = testId
            }
        } else if newStatus == .reopened {
            defect.verifiedFixed = false
        }

        defects[id] = defect
        return true
    }

    /// Convenience wrapper for updateStatus using idiomatic argument labels.
    @discardableResult
    public func updateStatus(
        of id: String,
        to newStatus: DefectStatus,
        verifiedByTestId: String? = nil
    ) -> Bool {
        updateStatus(id: id, newStatus: newStatus, verifiedByTest: verifiedByTestId != nil, verifiedByTestId: verifiedByTestId)
    }

    /// Looks up a defect by identifier.
    public func findDefect(id: String) -> DefectRecord? {
        lock.lock()
        defer { lock.unlock() }
        return defects[id]
    }

    public var allDefects: [DefectRecord] {
        lock.lock()
        defer { lock.unlock() }
        return Array(defects.values).sorted { $0.id < $1.id }
    }

    /// Returns defects filtered by status.
    public func defects(withStatus status: DefectStatus) -> [DefectRecord] {
        lock.lock()
        defer { lock.unlock() }
        return defects.values.filter { $0.status == status }.sorted { $0.id < $1.id }
    }

    /// Returns all unverified or unresolved defects.
    public var openDefects: [DefectRecord] {
        lock.lock()
        defer { lock.unlock() }
        return defects.values.filter {
            $0.status == .new || $0.status == .triaged || $0.status == .fixInProgress || $0.status == .reopened
        }.sorted { $0.id < $1.id }
    }

    /// Returns release-blocking defects (Critical or High unverified bugs).
    public var releaseBlockingDefects: [DefectRecord] {
        lock.lock()
        defer { lock.unlock() }
        return defects.values.filter { defect in
            let isUnresolved = (defect.status != .verified && defect.status != .acceptedRisk)
            let isHighOrCritical = (defect.severity == .critical || defect.severity == .high)
            return isUnresolved && isHighOrCritical
        }.sorted { $0.id < $1.id }
    }

    /// Generates executable regression test cases for all learned defects.
    public func generateRegressionSuite() -> [GeneratedTestCase] {
        lock.lock()
        defer { lock.unlock() }

        return defects.values.map { defect in
            GeneratedTestCase(
                id: defect.linkedRegressionTestId ?? "REG_\(defect.id)",
                title: "Regression_\(defect.id)_\(defect.regressionPattern)",
                category: .regression,
                screenId: defect.affectedScreen,
                intent: "Verify regression does not recur: \(defect.title)",
                precondition: "Screen '\(defect.affectedScreen)' is presented.",
                steps: defect.reproductionSteps,
                expectedOutcome: "Root cause prevented: \(defect.rootCause)"
            )
        }
    }

    /// Resets catalog to baseline known invariants.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        defects.removeAll()
        populateBaselineDefects()
    }

    private func populateBaselineDefects() {
        let bug1 = DefectRecord(
            id: "BUG_001",
            title: "Profile Save Succeeds But UI Does Not Refresh",
            affectedScreen: "User Profile",
            rootCause: "State binding was not updated after asynchronous API response.",
            regressionPattern: "Profile_Save_UI_Refresh_Invariant",
            riskLevel: .high,
            reproductionSteps: [
                "Open Profile Screen",
                "Edit Display Name",
                "Tap Save",
                "Assert UI text updates immediately upon API success"
            ],
            verifiedFixed: true,
            status: .verified,
            severity: .high,
            category: .ui,
            sourceFile: "UserProfileViewController.swift",
            lineRange: "45-60",
            expectedBehavior: "Profile UI re-renders with new name immediately.",
            actualBehavior: "Profile name remained stale until next app relaunch.",
            evidenceLogs: ["API returned 200 OK, but @Published name did not fire on main thread."],
            recommendedCorrection: "Dispatch state update to MainActor explicitly."
        )

        let bug2 = DefectRecord(
            id: "BUG_002",
            title: "Infinite 401 Loop on Expired Token",
            affectedScreen: "Authentication",
            rootCause: "Token refresh handler re-triggered the failing request with expired token.",
            regressionPattern: "Token_Refresh_Loop_Prevention",
            riskLevel: .critical,
            reproductionSteps: [
                "Simulate 401 response",
                "Call refresh endpoint",
                "Assert request is retried once; if refresh fails, session transitions to unauthenticated"
            ],
            verifiedFixed: true,
            status: .verified,
            severity: .critical,
            category: .network,
            sourceFile: "APIClient.swift",
            lineRange: "110-135",
            expectedBehavior: "Failing refresh terminates retry and purges token.",
            actualBehavior: "401 triggered recursive refresh attempts causing deadlock.",
            evidenceLogs: ["Stack trace showed recursion depth > 20 in APIClient.executeRequest."],
            recommendedCorrection: "Set max retry count to 1 for token refresh and force logout on second 401."
        )

        let bug3 = DefectRecord(
            id: "BUG_003",
            title: "Background Transition Resets Unsaved Contact Form",
            affectedScreen: "Contacts List",
            rootCause: "ViewController reloaded view state on applicationWillEnterForeground.",
            regressionPattern: "Background_Interruption_State_Preservation",
            riskLevel: .medium,
            reproductionSteps: [
                "Enter new contact details",
                "Move app to background",
                "Return to foreground",
                "Assert form inputs are preserved"
            ],
            verifiedFixed: true,
            status: .verified,
            severity: .medium,
            category: .functional,
            sourceFile: "ContactsViewController.swift",
            lineRange: "80-95",
            expectedBehavior: "Entered form draft is preserved across background interruptions.",
            actualBehavior: "applicationWillEnterForeground cleared local text fields.",
            evidenceLogs: ["Draft reset observed in memory during lifecycle notification."],
            recommendedCorrection: "Preserve draft in temporary memory cache during backgrounding."
        )

        defects[bug1.id] = bug1
        defects[bug2.id] = bug2
        defects[bug3.id] = bug3
    }
}

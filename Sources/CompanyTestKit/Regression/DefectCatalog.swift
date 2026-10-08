import Foundation

/// Record of a verified production bug transformed into reusable regression intelligence.
public struct DefectRecord: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let affectedScreen: String
    public let rootCause: String
    public let regressionPattern: String
    public let riskLevel: AIRiskLevel
    public let reproductionSteps: [String]
    public var verifiedFixed: Bool

    public init(
        id: String,
        title: String,
        affectedScreen: String,
        rootCause: String,
        regressionPattern: String,
        riskLevel: AIRiskLevel = .high,
        reproductionSteps: [String] = [],
        verifiedFixed: Bool = true
    ) {
        self.id = id
        self.title = title
        self.affectedScreen = affectedScreen
        self.rootCause = rootCause
        self.regressionPattern = regressionPattern
        self.riskLevel = riskLevel
        self.reproductionSteps = reproductionSteps
        self.verifiedFixed = verifiedFixed
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

    /// Records a verified defect into the catalog.
    public func recordDefect(_ defect: DefectRecord) {
        lock.lock()
        defer { lock.unlock() }
        defects[defect.id] = defect
    }

    public var allDefects: [DefectRecord] {
        lock.lock()
        defer { lock.unlock() }
        return Array(defects.values).sorted { $0.id < $1.id }
    }

    /// Generates executable regression test cases for all learned defects.
    public func generateRegressionSuite() -> [GeneratedTestCase] {
        lock.lock()
        defer { lock.unlock() }

        return defects.values.map { defect in
            GeneratedTestCase(
                id: "REG_\(defect.id)",
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
            verifiedFixed: true
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
            verifiedFixed: true
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
            verifiedFixed: true
        )

        defects[bug1.id] = bug1
        defects[bug2.id] = bug2
        defects[bug3.id] = bug3
    }
}

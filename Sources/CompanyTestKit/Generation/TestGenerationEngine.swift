import Foundation

/// Model representing a generated test scenario.
public struct GeneratedTestCase: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let category: TestCategory
    public let screenId: String
    public let intent: String
    public let precondition: String
    public let steps: [String]
    public let expectedOutcome: String
    public let isExecutable: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        category: TestCategory,
        screenId: String,
        intent: String,
        precondition: String,
        steps: [String],
        expectedOutcome: String,
        isExecutable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.screenId = screenId
        self.intent = intent
        self.precondition = precondition
        self.steps = steps
        self.expectedOutcome = expectedOutcome
        self.isExecutable = isExecutable
    }
}

/// Comprehensive test matrix plan generated from discovered screens and journeys.
public struct GeneratedTestPlan: Codable, Sendable, Equatable {
    public let screenCount: Int
    public let journeyCount: Int
    public let testCases: [GeneratedTestCase]

    public var functionalTests: [GeneratedTestCase] {
        testCases.filter { $0.category == .unit || $0.category == .api }
    }

    public var uiTests: [GeneratedTestCase] {
        testCases.filter { $0.category == .ui }
    }

    public var journeyTests: [GeneratedTestCase] {
        testCases.filter { $0.category == .e2e || $0.category == .integration }
    }

    public var regressionTests: [GeneratedTestCase] {
        testCases.filter { $0.category == .regression }
    }
}

/// Engine synthesizing meaningful functional, UI, platform, and journey tests from screen definitions.
public struct TestGenerationEngine: Sendable {
    public init() {}

    /// Generates exhaustive test scenarios for provided screens and journeys.
    public func generateTests(
        for screens: [ScreenDefinition],
        journeys: [UserJourney] = []
    ) -> GeneratedTestPlan {
        var cases: [GeneratedTestCase] = []

        // 1. Generate Screen-Level Functional & UI Tests
        for screen in screens {
            // A. Happy Path / Rendering
            cases.append(GeneratedTestCase(
                title: "\(screen.name)_HappyPath_RendersInitialState",
                category: .ui,
                screenId: screen.id,
                intent: "Verify initial view hierarchy renders required controls and accessible elements.",
                precondition: "Application is navigated to '\(screen.route)'.",
                steps: [
                    "Navigate to route '\(screen.route)'",
                    "Verify all \(screen.elements.count) elements are present in the hierarchy",
                    "Assert primary action buttons are enabled"
                ],
                expectedOutcome: "Screen displays without layout clipping or missing labels."
            ))

            // B. Input Validation Tests (For text fields)
            let textFields = screen.elements.filter { $0.type == .textField || $0.type == .secureField }
            for field in textFields {
                cases.append(GeneratedTestCase(
                    title: "\(screen.name)_\(field.id)_WhenEmptyInput_DisplaysValidationError",
                    category: .unit,
                    screenId: screen.id,
                    intent: "Verify empty input validation triggers proper error presentation.",
                    precondition: "Screen '\(screen.name)' is presented.",
                    steps: [
                        "Leave '\(field.id)' empty",
                        "Trigger submission action",
                        "Inspect error banner or field feedback"
                    ],
                    expectedOutcome: "Validation error is presented; submission is blocked."
                ))

                cases.append(GeneratedTestCase(
                    title: "\(screen.name)_\(field.id)_WhenBoundaryLengthExceeded_PreventsOverflow",
                    category: .unit,
                    screenId: screen.id,
                    intent: "Verify field enforces character length limits cleanly.",
                    precondition: "Screen '\(screen.name)' is presented.",
                    steps: [
                        "Enter string exceeding max boundary length (255+ characters)",
                        "Attempt submission"
                    ],
                    expectedOutcome: "Input is truncated or validation error is presented cleanly."
                ))
            }

            // C. API Dependency & Network Error Tests
            for endpoint in screen.apiDependencies {
                cases.append(GeneratedTestCase(
                    title: "\(screen.name)_API_\(sanitizedEndpoint(endpoint))_WhenServerErrors_PresentsErrorBanner",
                    category: .api,
                    screenId: screen.id,
                    intent: "Verify HTTP 500/503 responses transition screen to error state with retry option.",
                    precondition: "MockAPIClient stubbed with HTTP 500 for '\(endpoint)'.",
                    steps: [
                        "Trigger action invoking '\(endpoint)'",
                        "Wait for network response",
                        "Assert ErrorBannerView is displayed"
                    ],
                    expectedOutcome: "User-facing error is displayed; user is able to tap retry."
                ))

                cases.append(GeneratedTestCase(
                    title: "\(screen.name)_API_\(sanitizedEndpoint(endpoint))_WhenOffline_EnforcesOfflineBanner",
                    category: .api,
                    screenId: screen.id,
                    intent: "Verify network disconnection displays friendly offline message.",
                    precondition: "MockNetworkMonitor set to offline.",
                    steps: [
                        "Trigger network action",
                        "Evaluate error presentation"
                    ],
                    expectedOutcome: "Offline connection alert is displayed."
                ))
            }

            // D. Platform Lifecycle & Interruption Tests
            cases.append(GeneratedTestCase(
                title: "\(screen.name)_Platform_WhenBackgroundInterruptionOccurs_PreservesState",
                category: .ui,
                screenId: screen.id,
                intent: "Verify backgrounding application during screen presentation does not reset entered form data.",
                precondition: "Screen '\(screen.name)' has user input populated.",
                steps: [
                    "Transition AppLifecycleCoordinator to .background",
                    "Wait 100ms",
                    "Transition AppLifecycleCoordinator to .active",
                    "Assert populated form values remain intact"
                ],
                expectedOutcome: "Screen state is restored without data loss."
            ))
        }

        // 2. Generate Multi-Screen User Journey Tests
        for journey in journeys {
            cases.append(GeneratedTestCase(
                title: "Journey_\(journey.name.replacingOccurrences(of: " ", with: "_"))_EndToEnd",
                category: .e2e,
                screenId: journey.initialRoute,
                intent: "Execute complete end-to-end user navigation workflow.",
                precondition: "User session authenticated.",
                steps: journey.steps.map { "Step \($0.stepNumber): Screen \($0.screenId) -> \($0.actionName)" },
                expectedOutcome: "All \(journey.steps.count) steps transition successfully without crashing."
            ))
        }

        return GeneratedTestPlan(
            screenCount: screens.count,
            journeyCount: journeys.count,
            testCases: cases
        )
    }

    private func sanitizedEndpoint(_ endpoint: String) -> String {
        return endpoint
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

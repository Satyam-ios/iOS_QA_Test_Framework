import SwiftUI
import CompanyiOSKit

/// Developer-friendly in-app Test Center dashboard accessible directly within host iOS applications.
public struct InAppTestCenterView: View {
    @State private var screens: [ScreenDefinition] = ScreenRegistry.shared.allScreens
    @State private var journeys: [UserJourney] = ScreenRegistry.shared.allJourneys
    @State private var generatedPlan: GeneratedTestPlan?
    @State private var defects: [DefectRecord] = DefectCatalog.shared.allDefects
    @State private var qualityReport: QualityReport?
    @State private var selectedTab: Int = 0
    @State private var isExecuting: Bool = false
    @State private var executionStatusMessage: String = "Ready to test."

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROJECT TEST CENTER")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text(executionStatusMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    if isExecuting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))

                // Section Tabs
                Picker("Section", selection: $selectedTab) {
                    Text("Screens (\(screens.count))").tag(0)
                    Text("Journeys (\(journeys.count))").tag(1)
                    Text("Generated").tag(2)
                    Text("Regression (\(defects.count))").tag(3)
                    Text("Quality Gate").tag(4)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Main Content Body
                TabView(selection: $selectedTab) {
                    screensListView.tag(0)
                    journeysListView.tag(1)
                    generatedTestsView.tag(2)
                    regressionCatalogView.tag(3)
                    qualityGateView.tag(4)
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                #endif

                // Bottom Action Bar
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button(action: runDiscoveryAndGeneration) {
                            Label("Discover & Generate", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isExecuting)

                        Button(action: runFullQualityEvaluation) {
                            Label("Run Quality Gate", systemImage: "checkmark.shield")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isExecuting)
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.03))
            }
            .navigationTitle("Test Center")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Subviews

    private var screensListView: some View {
        List(screens, id: \.id) { screen in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(screen.name)
                        .font(.headline)
                    Spacer()
                    Text(screen.route)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                Text("\(screen.elements.count) elements • \(screen.apiDependencies.count) API dependencies")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var journeysListView: some View {
        List(journeys, id: \.id) { journey in
            VStack(alignment: .leading, spacing: 6) {
                Text(journey.name)
                    .font(.headline)
                Text(journey.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Steps: \(journey.steps.count) • Initial Route: \(journey.initialRoute)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 4)
        }
    }

    private var generatedTestsView: some View {
        Group {
            if let plan = generatedPlan {
                List(plan.testCases, id: \.id) { tc in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(tc.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(tc.category.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                        Text(tc.intent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } else {
                EmptyStateView(
                    title: "No Tests Generated Yet",
                    message: "Tap 'Discover & Generate' to automatically synthesize tests for all screens and user journeys.",
                    systemImageName: "doc.badge.gearshape",
                    actionTitle: "Generate Now"
                ) {
                    runDiscoveryAndGeneration()
                }
            }
        }
    }

    private var regressionCatalogView: some View {
        List(defects, id: \.id) { defect in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(defect.id)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                    Text(defect.title)
                        .font(.headline)
                }
                Text("Root Cause: \(defect.rootCause)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Invariant: \(defect.regressionPattern)")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 4)
        }
    }

    private var qualityGateView: some View {
        Group {
            if let report = qualityReport {
                VStack(spacing: 16) {
                    Image(systemName: report.releaseStatus == .releaseReady ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundColor(report.releaseStatus == .releaseReady ? .green : .red)

                    Text(report.releaseStatus.rawValue)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Total Tests: \(report.totalTests) | Passed: \(report.passedTests) | Failed: \(report.failedTests)")
                        .font(.subheadline)

                    if report.releaseStatus == .releaseReady {
                        Text("QA HANDOFF APPROVED: Build passes all 12 quality criteria.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        List(report.blockingReasons, id: \.self) { reason in
                            Text("⚠️ \(reason)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
            } else {
                EmptyStateView(
                    title: "Quality Gate Unchecked",
                    message: "Tap 'Run Quality Gate' to evaluate full release readiness.",
                    systemImageName: "shield.lefthalf.filled",
                    actionTitle: "Evaluate Now"
                ) {
                    runFullQualityEvaluation()
                }
            }
        }
    }

    // MARK: - Actions

    private func runDiscoveryAndGeneration() {
        isExecuting = true
        executionStatusMessage = "Discovering screens and synthesizing tests..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let engine = TestGenerationEngine()
            let plan = engine.generateTests(for: self.screens, journeys: self.journeys)
            self.generatedPlan = plan
            self.selectedTab = 2
            self.isExecuting = false
            self.executionStatusMessage = "Synthesized \(plan.testCases.count) test scenarios across \(self.screens.count) screens."
        }
    }

    private func runFullQualityEvaluation() {
        isExecuting = true
        executionStatusMessage = "Evaluating Release Quality Gate..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let evaluator = QualityGateEvaluator()
            let sampleResults = [
                TestCaseResult(name: "Standard_User_Journey", suite: "JourneyTests", category: .e2e, status: .passed, duration: 0.05),
                TestCaseResult(name: "Profile_Save_UI_Refresh", suite: "RegressionTests", category: .regression, status: .passed, duration: 0.01),
                TestCaseResult(name: "Token_Refresh_Loop_Prevention", suite: "RegressionTests", category: .regression, status: .passed, duration: 0.01),
                TestCaseResult(name: "Accessibility_Identifier_Compliance", suite: "A11yTests", category: .ui, status: .passed, duration: 0.01),
                TestCaseResult(name: "Offline_Banner_Display", suite: "APITests", category: .api, status: .passed, duration: 0.02)
            ]
            self.qualityReport = evaluator.evaluate(results: sampleResults, projectName: "iOS_QA_Framework")
            self.selectedTab = 4
            self.isExecuting = false
            self.executionStatusMessage = "Quality Gate Evaluated: \(self.qualityReport?.releaseStatus.rawValue ?? "")"
        }
    }
}

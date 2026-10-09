import Foundation

/// Orchestrator for executing and validating end-to-end user journeys deterministically.
public actor JourneyRunner {
    private var registeredScreens: [String: ScreenDefinition] = [:]

    public init(screens: [ScreenDefinition] = []) {
        for screen in screens {
            self.registeredScreens[screen.id] = screen
        }
    }

    public func registerScreen(_ screen: ScreenDefinition) {
        registeredScreens[screen.id] = screen
    }

    /// Executes an end-to-end journey step-by-step with checkpoint tracing and automated defect synthesis.
    public func execute(
        journey: UserJourney,
        recordDefectOnFailure: Bool = true
    ) async -> JourneyExecutionResult {
        let startTime = Date()
        var stepResults: [StepResult] = []

        for step in journey.steps {
            let stepStart = Date()
            guard let screen = registeredScreens[step.screenId] else {
                let failResult = StepResult(
                    stepNumber: step.stepNumber,
                    screenId: step.screenId,
                    actionName: step.actionName,
                    isSuccessful: false,
                    failureReason: "Screen '\(step.screenId)' is not registered or reachable.",
                    duration: Date().timeIntervalSince(stepStart),
                    apiCallTriggered: step.apiCallTriggered,
                    targetElementId: step.targetElementId,
                    expectedRoute: step.expectedRoute,
                    checkpointTimestamp: Date()
                )
                stepResults.append(failResult)
                return handleFailure(
                    journey: journey,
                    failedStep: step,
                    failResult: failResult,
                    stepResults: stepResults,
                    startTime: startTime,
                    recordDefect: recordDefectOnFailure
                )
            }

            // Verify target element if specified
            if let elementId = step.targetElementId {
                guard let element = screen.elements.first(where: { $0.id == elementId }) else {
                    let failResult = StepResult(
                        stepNumber: step.stepNumber,
                        screenId: step.screenId,
                        actionName: step.actionName,
                        isSuccessful: false,
                        failureReason: "Element '\(elementId)' was not found on screen '\(screen.name)'.",
                        duration: Date().timeIntervalSince(stepStart),
                        apiCallTriggered: step.apiCallTriggered,
                        targetElementId: step.targetElementId,
                        expectedRoute: step.expectedRoute,
                        checkpointTimestamp: Date()
                    )
                    stepResults.append(failResult)
                    return handleFailure(
                        journey: journey,
                        failedStep: step,
                        failResult: failResult,
                        stepResults: stepResults,
                        startTime: startTime,
                        recordDefect: recordDefectOnFailure
                    )
                }

                if !element.isVisible {
                    let failResult = StepResult(
                        stepNumber: step.stepNumber,
                        screenId: step.screenId,
                        actionName: step.actionName,
                        isSuccessful: false,
                        failureReason: "Element '\(elementId)' is hidden on screen '\(screen.name)'.",
                        duration: Date().timeIntervalSince(stepStart),
                        apiCallTriggered: step.apiCallTriggered,
                        targetElementId: step.targetElementId,
                        expectedRoute: step.expectedRoute,
                        checkpointTimestamp: Date()
                    )
                    stepResults.append(failResult)
                    return handleFailure(
                        journey: journey,
                        failedStep: step,
                        failResult: failResult,
                        stepResults: stepResults,
                        startTime: startTime,
                        recordDefect: recordDefectOnFailure
                    )
                }

                if !element.isEnabled {
                    let failResult = StepResult(
                        stepNumber: step.stepNumber,
                        screenId: step.screenId,
                        actionName: step.actionName,
                        isSuccessful: false,
                        failureReason: "Element '\(elementId)' is disabled on screen '\(screen.name)'.",
                        duration: Date().timeIntervalSince(stepStart),
                        apiCallTriggered: step.apiCallTriggered,
                        targetElementId: step.targetElementId,
                        expectedRoute: step.expectedRoute,
                        checkpointTimestamp: Date()
                    )
                    stepResults.append(failResult)
                    return handleFailure(
                        journey: journey,
                        failedStep: step,
                        failResult: failResult,
                        stepResults: stepResults,
                        startTime: startTime,
                        recordDefect: recordDefectOnFailure
                    )
                }
            }

            let successResult = StepResult(
                stepNumber: step.stepNumber,
                screenId: step.screenId,
                actionName: step.actionName,
                isSuccessful: true,
                duration: Date().timeIntervalSince(stepStart),
                apiCallTriggered: step.apiCallTriggered,
                targetElementId: step.targetElementId,
                expectedRoute: step.expectedRoute,
                checkpointTimestamp: Date()
            )
            stepResults.append(successResult)
        }

        return JourneyExecutionResult(
            journeyId: journey.id,
            name: journey.name,
            isSuccessful: true,
            executedSteps: stepResults.count,
            totalSteps: journey.steps.count,
            duration: Date().timeIntervalSince(startTime),
            stepResults: stepResults
        )
    }

    private func handleFailure(
        journey: UserJourney,
        failedStep: JourneyStep,
        failResult: StepResult,
        stepResults: [StepResult],
        startTime: Date,
        recordDefect: Bool
    ) -> JourneyExecutionResult {
        var defectId: String? = nil
        if recordDefect {
            let id = "DEF-JOURNEY-\(UUID().uuidString.prefix(6))"
            let defect = DefectRecord(
                id: id,
                title: "Journey '\(journey.name)' failed at step \(failedStep.stepNumber): \(failedStep.actionName)",
                affectedScreen: failedStep.screenId,
                rootCause: failResult.failureReason ?? "Unknown step failure",
                regressionPattern: "JourneyStepFailure_\(failedStep.screenId)",
                riskLevel: .high,
                reproductionSteps: journey.steps.prefix(failedStep.stepNumber).map {
                    "Step \($0.stepNumber): Screen '\($0.screenId)' -> \($0.actionName)"
                },
                verifiedFixed: false,
                status: .new,
                severity: .high,
                category: .functional,
                expectedBehavior: "Step completes successfully",
                actualBehavior: failResult.failureReason
            )
            DefectCatalog.shared.recordDefect(defect)
            defectId = id
        }

        return JourneyExecutionResult(
            journeyId: journey.id,
            name: journey.name,
            isSuccessful: false,
            executedSteps: stepResults.count,
            totalSteps: journey.steps.count,
            failedStepNumber: failedStep.stepNumber,
            failureReason: failResult.failureReason,
            duration: Date().timeIntervalSince(startTime),
            stepResults: stepResults,
            synthesizedDefectId: defectId
        )
    }
}

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

    /// Executes an end-to-end journey step-by-step.
    public func execute(journey: UserJourney) async -> JourneyExecutionResult {
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
                    duration: Date().timeIntervalSince(stepStart)
                )
                stepResults.append(failResult)
                return JourneyExecutionResult(
                    journeyId: journey.id,
                    name: journey.name,
                    isSuccessful: false,
                    executedSteps: stepResults.count,
                    totalSteps: journey.steps.count,
                    failedStepNumber: step.stepNumber,
                    failureReason: failResult.failureReason,
                    duration: Date().timeIntervalSince(startTime),
                    stepResults: stepResults
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
                        duration: Date().timeIntervalSince(stepStart)
                    )
                    stepResults.append(failResult)
                    return JourneyExecutionResult(
                        journeyId: journey.id,
                        name: journey.name,
                        isSuccessful: false,
                        executedSteps: stepResults.count,
                        totalSteps: journey.steps.count,
                        failedStepNumber: step.stepNumber,
                        failureReason: failResult.failureReason,
                        duration: Date().timeIntervalSince(startTime),
                        stepResults: stepResults
                    )
                }

                if !element.isVisible {
                    let failResult = StepResult(
                        stepNumber: step.stepNumber,
                        screenId: step.screenId,
                        actionName: step.actionName,
                        isSuccessful: false,
                        failureReason: "Element '\(elementId)' is hidden on screen '\(screen.name)'.",
                        duration: Date().timeIntervalSince(stepStart)
                    )
                    stepResults.append(failResult)
                    return JourneyExecutionResult(
                        journeyId: journey.id,
                        name: journey.name,
                        isSuccessful: false,
                        executedSteps: stepResults.count,
                        totalSteps: journey.steps.count,
                        failedStepNumber: step.stepNumber,
                        failureReason: failResult.failureReason,
                        duration: Date().timeIntervalSince(startTime),
                        stepResults: stepResults
                    )
                }

                if !element.isEnabled {
                    let failResult = StepResult(
                        stepNumber: step.stepNumber,
                        screenId: step.screenId,
                        actionName: step.actionName,
                        isSuccessful: false,
                        failureReason: "Element '\(elementId)' is disabled on screen '\(screen.name)'.",
                        duration: Date().timeIntervalSince(stepStart)
                    )
                    stepResults.append(failResult)
                    return JourneyExecutionResult(
                        journeyId: journey.id,
                        name: journey.name,
                        isSuccessful: false,
                        executedSteps: stepResults.count,
                        totalSteps: journey.steps.count,
                        failedStepNumber: step.stepNumber,
                        failureReason: failResult.failureReason,
                        duration: Date().timeIntervalSince(startTime),
                        stepResults: stepResults
                    )
                }
            }

            let successResult = StepResult(
                stepNumber: step.stepNumber,
                screenId: step.screenId,
                actionName: step.actionName,
                isSuccessful: true,
                duration: Date().timeIntervalSince(stepStart)
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
}

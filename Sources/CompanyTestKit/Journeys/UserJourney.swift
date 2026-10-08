import Foundation

/// Individual step in a user journey.
public struct JourneyStep: Codable, Sendable, Equatable {
    public let stepNumber: Int
    public let screenId: String
    public let actionName: String
    public let targetElementId: String?
    public let inputValue: String?
    public let expectedState: ScreenStateKind
    public let expectedRoute: String?
    public let apiCallTriggered: String?

    public init(
        stepNumber: Int,
        screenId: String,
        actionName: String,
        targetElementId: String? = nil,
        inputValue: String? = nil,
        expectedState: ScreenStateKind = .normal,
        expectedRoute: String? = nil,
        apiCallTriggered: String? = nil
    ) {
        self.stepNumber = stepNumber
        self.screenId = screenId
        self.actionName = actionName
        self.targetElementId = targetElementId
        self.inputValue = inputValue
        self.expectedState = expectedState
        self.expectedRoute = expectedRoute
        self.apiCallTriggered = apiCallTriggered
    }
}

/// End-to-end representation of a real user navigation journey.
public struct UserJourney: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let initialRoute: String
    public var steps: [JourneyStep]

    public init(
        id: String,
        name: String,
        description: String = "",
        initialRoute: String,
        steps: [JourneyStep] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.initialRoute = initialRoute
        self.steps = steps
    }
}

/// Result of an individual step execution.
public struct StepResult: Codable, Sendable, Equatable {
    public let stepNumber: Int
    public let screenId: String
    public let actionName: String
    public let isSuccessful: Bool
    public let failureReason: String?
    public let duration: TimeInterval

    public init(
        stepNumber: Int,
        screenId: String,
        actionName: String,
        isSuccessful: Bool,
        failureReason: String? = nil,
        duration: TimeInterval = 0.001
    ) {
        self.stepNumber = stepNumber
        self.screenId = screenId
        self.actionName = actionName
        self.isSuccessful = isSuccessful
        self.failureReason = failureReason
        self.duration = duration
    }
}

/// Comprehensive outcome of an end-to-end journey execution.
public struct JourneyExecutionResult: Codable, Sendable, Equatable {
    public let journeyId: String
    public let name: String
    public let isSuccessful: Bool
    public let executedSteps: Int
    public let totalSteps: Int
    public let failedStepNumber: Int?
    public let failureReason: String?
    public let duration: TimeInterval
    public let stepResults: [StepResult]

    public init(
        journeyId: String,
        name: String,
        isSuccessful: Bool,
        executedSteps: Int,
        totalSteps: Int,
        failedStepNumber: Int? = nil,
        failureReason: String? = nil,
        duration: TimeInterval,
        stepResults: [StepResult] = []
    ) {
        self.journeyId = journeyId
        self.name = name
        self.isSuccessful = isSuccessful
        self.executedSteps = executedSteps
        self.totalSteps = totalSteps
        self.failedStepNumber = failedStepNumber
        self.failureReason = failureReason
        self.duration = duration
        self.stepResults = stepResults
    }
}

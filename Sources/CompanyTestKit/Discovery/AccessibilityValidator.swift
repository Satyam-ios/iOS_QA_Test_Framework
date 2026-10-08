import Foundation

/// Specific accessibility violation detected on a screen element.
public struct AccessibilityViolation: Codable, Sendable, Equatable {
    public let elementId: String
    public let screenName: String
    public let issueType: String
    public let recommendation: String

    public init(elementId: String, screenName: String, issueType: String, recommendation: String) {
        self.elementId = elementId
        self.screenName = screenName
        self.issueType = issueType
        self.recommendation = recommendation
    }
}

/// Report summarizing accessibility compliance across inspected screens.
public struct AccessibilityValidationReport: Codable, Sendable, Equatable {
    public let totalElementsChecked: Int
    public let violations: [AccessibilityViolation]
    public var isCompliant: Bool {
        return violations.isEmpty
    }
}

/// Automated validator checking compliance with Apple accessibility guidelines.
public struct AccessibilityValidator: Sendable {
    public init() {}

    /// Inspects a single screen definition for missing identifiers and VoiceOver labels.
    public func validate(screen: ScreenDefinition) -> [AccessibilityViolation] {
        var violations: [AccessibilityViolation] = []

        for element in screen.elements {
            // Interactive elements must have accessibility identifiers for automation
            if element.accessibilityIdentifier == nil || element.accessibilityIdentifier?.isEmpty == true {
                violations.append(AccessibilityViolation(
                    elementId: element.id,
                    screenName: screen.name,
                    issueType: "Missing Accessibility Identifier",
                    recommendation: "Provide a unique accessibilityIdentifier for UI testing automation."
                ))
            }

            // Buttons, text fields, and toggles require accessibility labels for VoiceOver
            switch element.type {
            case .button, .textField, .secureField, .toggle:
                if element.accessibilityLabel == nil || element.accessibilityLabel?.trimmingCharacters(in: .whitespaces).isEmpty == true {
                    violations.append(AccessibilityViolation(
                        elementId: element.id,
                        screenName: screen.name,
                        issueType: "Missing VoiceOver Accessibility Label",
                        recommendation: "Provide a concise accessibilityLabel describing the control's action or purpose."
                    ))
                }
            default:
                break
            }
        }

        return violations
    }

    /// Evaluates all registered screens.
    public func validate(screens: [ScreenDefinition]) -> AccessibilityValidationReport {
        var totalElements = 0
        var allViolations: [AccessibilityViolation] = []

        for screen in screens {
            totalElements += screen.elements.count
            allViolations.append(contentsOf: validate(screen: screen))
        }

        return AccessibilityValidationReport(
            totalElementsChecked: totalElements,
            violations: allViolations
        )
    }
}

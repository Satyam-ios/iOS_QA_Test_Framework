import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif
import CompanyiOSKit

/// Observes live UIKit view hierarchies to detect UI/UX rendering defects, text truncation, and layout engine hazards.
public final class LiveScreenAuditEngine: @unchecked Sendable {
    public static let shared = LiveScreenAuditEngine()

    private let lock = NSLock()
    private var isAuditing = false

    private init() {}

    #if canImport(UIKit) && !os(watchOS)
    /// Performs an immediate, deep runtime inspection of the key window and visible view controller.
    @MainActor
    @discardableResult
    public func auditActiveWindow() -> [DefectRecord] {
        guard let window = activeKeyWindow(), let rootVC = window.rootViewController else {
            return []
        }

        var detectedDefects: [DefectRecord] = []
        let topVC = topMostViewController(from: rootVC)
        let screenName = String(describing: type(of: topVC))

        // Recursively inspect all subviews for UI/UX rendering issues
        inspectViewHierarchy(topVC.view, screenName: screenName, defects: &detectedDefects)

        // Record all detected defects into DefectCatalog and RuntimeTelemetryStore
        for defect in detectedDefects {
            DefectCatalog.shared.recordDefect(defect)
            RuntimeTelemetryStore.shared.record(
                category: .ui,
                severity: defect.severity,
                title: defect.title,
                details: defect.rootCause,
                sourceLocation: defect.sourceFile,
                contextMetadata: ["actual": defect.actualBehavior ?? "", "fix": defect.recommendedCorrection ?? ""]
            )
        }

        return detectedDefects
    }

    @MainActor
    private func inspectViewHierarchy(_ view: UIView, screenName: String, defects: inout [DefectRecord]) {
        // 1. Audit UILabels for text truncation, ellipses ('...'), and clipping
        if let label = view as? UILabel, let text = label.text, !text.isEmpty {
            auditLabelForTruncation(label, text: text, screenName: screenName, defects: &defects)
        }

        // 2. Audit UIButtons for truncated title text and Apple HIG touch target sizing (< 44pt)
        if let button = view as? UIButton {
            auditButton(button, screenName: screenName, defects: &defects)
        }

        // Recurse through children
        for subview in view.subviews {
            inspectViewHierarchy(subview, screenName: screenName, defects: &defects)
        }
    }

    @MainActor
    private func auditLabelForTruncation(_ label: UILabel, text: String, screenName: String, defects: inout [DefectRecord]) {
        let hasEllipsis = text.hasSuffix("...") || text.hasSuffix("…") || text.contains("...") || text.contains("…")
        
        let targetSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: label.bounds.height > 0 ? label.bounds.height : 30)
        let requiredWidth = label.sizeThatFits(targetSize).width
        let isWidthClipped = label.bounds.width > 0 && requiredWidth > (label.bounds.width + 1.0) && label.numberOfLines == 1

        if hasEllipsis || isWidthClipped {
            let labelId = label.accessibilityIdentifier ?? "label_\(abs(label.hashValue % 10000))"
            let defectId = "BUG_UI_TRUNCATION_\(labelId)"

            let defect = DefectRecord(
                id: defectId,
                title: "UI Text Truncation: Label '\(labelId)' displays '\(text)' with ellipsis",
                affectedScreen: screenName,
                rootCause: "AutoLayout width constraint is too restrictive for text length. Rendered string was clipped with ellipsis: '\(text)'.",
                regressionPattern: "UI_Text_Truncation_Invariant",
                riskLevel: .medium,
                reproductionSteps: [
                    "Navigate to screen: \(screenName)",
                    "Locate label: \(labelId)",
                    "Observe rendered text is clipped as '\(text)' instead of full string"
                ],
                verifiedFixed: false,
                status: .new,
                severity: .medium,
                category: .ui,
                sourceFile: "\(screenName).swift",
                lineRange: "UI Hierarchy (width: \(Int(label.bounds.width))pt vs required: \(Int(requiredWidth))pt)",
                expectedBehavior: "Full text rendered completely without clipping or ellipses.",
                actualBehavior: "Rendered text displays ellipsis: '\(text)'.",
                evidenceLogs: [
                    "Rendered text: '\(text)'",
                    "Label bounds: \(label.bounds)",
                    "Required size: \(requiredWidth)pt",
                    "Ellipsis detected: \(hasEllipsis)",
                    "Width clipped: \(isWidthClipped)"
                ],
                recommendedCorrection: "Enable label.adjustsFontSizeToFitWidth = true with minimumScaleFactor = 0.8, change width constraint to >=, or set numberOfLines = 0."
            )

            defects.append(defect)
        }
    }

    @MainActor
    private func auditButton(_ button: UIButton, screenName: String, defects: inout [DefectRecord]) {
        // Touch target sizing check (Apple HIG minimum 44x44pt)
        if button.bounds.width > 0 && button.bounds.height > 0 {
            if button.bounds.width < 44.0 || button.bounds.height < 44.0 {
                let btnId = button.accessibilityIdentifier ?? "button_\(abs(button.hashValue % 10000))"
                let defectId = "BUG_A11Y_TOUCH_TARGET_\(btnId)"
                
                let defect = DefectRecord(
                    id: defectId,
                    title: "Touch Target Size Violation: Button '\(btnId)' is smaller than 44x44pt",
                    affectedScreen: screenName,
                    rootCause: "Button frame is \(Int(button.bounds.width))x\(Int(button.bounds.height))pt, violating Apple Human Interface Guidelines minimum touch target of 44x44pt.",
                    regressionPattern: "Apple_HIG_Touch_Target_Invariant",
                    riskLevel: .low,
                    reproductionSteps: [
                        "Navigate to \(screenName)",
                        "Inspect touch bounds for button '\(btnId)'"
                    ],
                    verifiedFixed: false,
                    status: .new,
                    severity: .low,
                    category: .ui,
                    sourceFile: "\(screenName).swift",
                    expectedBehavior: "Touch target bounds >= 44x44pt.",
                    actualBehavior: "Button frame is \(Int(button.bounds.width))x\(Int(button.bounds.height))pt.",
                    evidenceLogs: ["Frame: \(button.bounds)"],
                    recommendedCorrection: "Increase button frame constraint or expand contentInsets/hitTest bounds to at least 44x44pt."
                )
                defects.append(defect)
            }
        }
    }

    @MainActor
    private func activeKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
        } else {
            return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
    }

    @MainActor
    private func topMostViewController(from root: UIViewController) -> UIViewController {
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        if let nav = current as? UINavigationController, let top = nav.topViewController {
            return topMostViewController(from: top)
        }
        if let tab = current as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(from: selected)
        }
        return current
    }
    #endif
}

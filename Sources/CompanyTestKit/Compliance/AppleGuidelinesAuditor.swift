import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CompanyiOSKit

/// Classification of Apple guideline compliance findings.
public enum GuidelineViolationLevel: String, Codable, Sendable, CaseIterable {
    case confirmedViolation = "Confirmed Violation"
    case potentialRisk = "Potential Risk"
    case recommendation = "Apple HIG Recommendation"

    public var badgeColor: String {
        switch self {
        case .confirmedViolation: return "red"
        case .potentialRisk: return "orange"
        case .recommendation: return "blue"
        }
    }
}

/// A specific finding discovered during the Apple Guidelines & Compliance Audit.
public struct AppleGuidelineFinding: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let section: String // e.g. "Section 2.1 (App Completeness)", "Section 5.1.1 (Data Collection)"
    public let title: String
    public let detail: String
    public let level: GuidelineViolationLevel
    public let documentationURL: String
    public let remediationSteps: [String]
    public let affectedComponent: String?

    public init(
        id: String = UUID().uuidString,
        section: String,
        title: String,
        detail: String,
        level: GuidelineViolationLevel,
        documentationURL: String,
        remediationSteps: [String],
        affectedComponent: String? = nil
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.detail = detail
        self.level = level
        self.documentationURL = documentationURL
        self.remediationSteps = remediationSteps
        self.affectedComponent = affectedComponent
    }
}

/// Consolidated Apple Guidelines & Compliance Audit Report.
public struct AppleGuidelinesAuditReport: Codable, Sendable, Equatable {
    public let isCompliant: Bool
    public let scorePercentage: Double
    public let confirmedViolationsCount: Int
    public let potentialRisksCount: Int
    public let recommendationsCount: Int
    public let findings: [AppleGuidelineFinding]
    public let hasPrivacyManifest: Bool
    public let timestamp: Date

    public init(
        isCompliant: Bool,
        scorePercentage: Double,
        confirmedViolationsCount: Int,
        potentialRisksCount: Int,
        recommendationsCount: Int,
        findings: [AppleGuidelineFinding],
        hasPrivacyManifest: Bool,
        timestamp: Date = Date()
    ) {
        self.isCompliant = isCompliant
        self.scorePercentage = scorePercentage
        self.confirmedViolationsCount = confirmedViolationsCount
        self.potentialRisksCount = potentialRisksCount
        self.recommendationsCount = recommendationsCount
        self.findings = findings
        self.hasPrivacyManifest = hasPrivacyManifest
        self.timestamp = timestamp
    }
}

/// High-performance, 100% free Apple Review Guidelines & Compliance Auditor.
public final class AppleGuidelinesAuditor: Sendable {
    public init() {}

    /// Returns a clean baseline compliance report.
    public static func baselineReport() -> AppleGuidelinesAuditReport {
        AppleGuidelinesAuditReport(
            isCompliant: true,
            scorePercentage: 100.0,
            confirmedViolationsCount: 0,
            potentialRisksCount: 0,
            recommendationsCount: 0,
            findings: [],
            hasPrivacyManifest: true
        )
    }

    /// Runs a comprehensive compliance audit against App Store guidelines and Privacy Manifest requirements.
    public func auditApplication() -> AppleGuidelinesAuditReport {
        var findings: [AppleGuidelineFinding] = []
        let bundle = Bundle.main

        // 1. Guideline 5.1.1: Privacy Manifest & Required Reason APIs Verification
        let privacyManifestURL = bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        let hasPrivacyManifest = privacyManifestURL != nil

        if !hasPrivacyManifest {
            findings.append(AppleGuidelineFinding(
                section: "Guideline 5.1.1 - Data Collection and Storage",
                title: "Missing Privacy Manifest (PrivacyInfo.xcprivacy)",
                detail: "Apple strictly mandates a PrivacyInfo.xcprivacy file declaring all data collection, tracking domains, and Required Reason APIs (effective Spring 2024). Apps missing this manifest face automatic App Store rejection.",
                level: .confirmedViolation,
                documentationURL: "https://developer.apple.com/documentation/bundleresources/privacy_manifest_files",
                remediationSteps: [
                    "Create a new 'PrivacyInfo.xcprivacy' property list in your Xcode project root.",
                    "Declare 'NSPrivacyTracking' boolean.",
                    "Declare 'NSPrivacyCollectedDataTypes' array for any user analytics or crash data.",
                    "Declare 'NSPrivacyAccessedAPITypes' for UserDefaults, file timestamps, and system boot time APIs."
                ],
                affectedComponent: "App Bundle Root"
            ))
        }

        // 2. Guideline 5.1.2: App Tracking Transparency (ATT) Verification
        let infoDict = bundle.infoDictionary ?? [:]
        let hasUserTrackingDescription = infoDict["NSUserTrackingUsageDescription"] != nil
        if !hasUserTrackingDescription {
            findings.append(AppleGuidelineFinding(
                section: "Guideline 5.1.2 - Data Use and Sharing (ATT)",
                title: "NSUserTrackingUsageDescription Not Declared",
                detail: "If your app or any embedded third-party SDK utilizes the Advertising Identifier (IDFA) or performs cross-app tracking, iOS requires NSUserTrackingUsageDescription and user consent via ATTrackingManager.",
                level: .recommendation,
                documentationURL: "https://developer.apple.com/app-store/user-privacy-and-data-use/",
                remediationSteps: [
                    "If advertising or tracking SDKs are linked, add NSUserTrackingUsageDescription in Info.plist.",
                    "If no tracking is performed, confirm that third-party SDKs do not collect IDFA."
                ],
                affectedComponent: "Info.plist"
            ))
        }

        // 3. Guideline 2.1: App Completeness & Placeholder Assets
        let appName = (infoDict["CFBundleDisplayName"] as? String) ?? (infoDict["CFBundleName"] as? String) ?? ""
        if appName.lowercased().contains("test") || appName.lowercased().contains("demo") || appName.lowercased().contains("sample") {
            findings.append(AppleGuidelineFinding(
                section: "Guideline 2.1 - App Completeness",
                title: "App Title Contains Beta/Test Keyword ('\(appName)')",
                detail: "Apple rejects production submissions with titles containing 'Test', 'Demo', 'Trial', or 'Beta' in CFBundleDisplayName.",
                level: .confirmedViolation,
                documentationURL: "https://developer.apple.com/app-store/review/guidelines/#app-completeness",
                remediationSteps: [
                    "Update CFBundleDisplayName in Info.plist to your official product title before production release."
                ],
                affectedComponent: "Info.plist (CFBundleDisplayName)"
            ))
        }

        // 4. Guideline 2.5.1: Private API & Prohibited Dynamic Symbol Inspection
        let suspiciousSymbols = ["_CBLockDevice", "MSHookFunction", "OBJC_METACLASS_$_FLEXManager"]
        for sym in suspiciousSymbols {
            if dlsym(dlopen(nil, RTLD_NOW), sym) != nil {
                findings.append(AppleGuidelineFinding(
                    section: "Guideline 2.5.1 - Performance: Software Requirements",
                    title: "Potentially Forbidden Dynamic Symbol Detected (\(sym))",
                    detail: "Symbols associated with runtime hooking, private frameworks, or embedded debug toolbars can cause automatic App Store binary rejection.",
                    level: .confirmedViolation,
                    documentationURL: "https://developer.apple.com/app-store/review/guidelines/#software-requirements",
                    remediationSteps: [
                        "Ensure debugging frameworks (FLEX, Lookin, Reveal) are wrapped in #if DEBUG and excluded from release configurations."
                    ],
                    affectedComponent: "Binary Symbols"
                ))
            }
        }

        // 5. Guideline 4.0: Dark Mode & Dynamic Type HIG Readiness
        findings.append(AppleGuidelineFinding(
            section: "Guideline 4.0 - Design: Human Interface Guidelines",
            title: "Dynamic Type & Minimum 44x44pt Touch Targets",
            detail: "Apple HIG requires touch targets to measure at least 44x44 points and recommend supporting Dynamic Type font scaling for accessibility compliance.",
            level: .recommendation,
            documentationURL: "https://developer.apple.com/design/human-interface-guidelines/accessibility",
            remediationSteps: [
                "Verify custom UIButtons maintain a minimum 44x44pt hit test bounds.",
                "Adopt UIFontMetrics or SwiftUI .font(.body) instead of hardcoded fixed point sizes."
            ],
            affectedComponent: "UI Layer"
        ))

        // Calculate score
        let confirmedCount = findings.filter { $0.level == .confirmedViolation }.count
        let riskCount = findings.filter { $0.level == .potentialRisk }.count
        let recCount = findings.filter { $0.level == .recommendation }.count

        var score = 100.0 - (Double(confirmedCount) * 25.0) - (Double(riskCount) * 10.0) - (Double(recCount) * 2.0)
        if score < 0.0 { score = 0.0 }

        return AppleGuidelinesAuditReport(
            isCompliant: confirmedCount == 0,
            scorePercentage: score,
            confirmedViolationsCount: confirmedCount,
            potentialRisksCount: riskCount,
            recommendationsCount: recCount,
            findings: findings,
            hasPrivacyManifest: hasPrivacyManifest
        )
    }
}

import Foundation

/// App Store Review Guidelines compliance status.
public enum ComplianceStatus: String, Codable, Sendable {
    case compliant = "COMPLIANT"
    case atRisk = "AT RISK"
    case nonCompliant = "NON COMPLIANT"
}

/// Discovered compliance or App Store Guideline violation.
public struct ComplianceIssue: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let guideline: String
    public let severity: DefectSeverity
    public let title: String
    public let explanation: String
    public let remediationSteps: [String]
    public let sourceFile: String?
    public let sourceLine: Int?

    public init(
        id: String = UUID().uuidString,
        guideline: String,
        severity: DefectSeverity,
        title: String,
        explanation: String,
        remediationSteps: [String],
        sourceFile: String? = nil,
        sourceLine: Int? = nil
    ) {
        self.id = id
        self.guideline = guideline
        self.severity = severity
        self.title = title
        self.explanation = explanation
        self.remediationSteps = remediationSteps
        self.sourceFile = sourceFile
        self.sourceLine = sourceLine
    }
}

/// Report summarizing App Store review guideline checks and Privacy Manifest verification.
public struct ComplianceAuditReport: Codable, Sendable, Equatable {
    public let status: ComplianceStatus
    public let issues: [ComplianceIssue]
    public let scannedFilesCount: Int
    public let hasPrivacyManifest: Bool
    public let timestamp: Date

    public init(
        status: ComplianceStatus,
        issues: [ComplianceIssue],
        scannedFilesCount: Int,
        hasPrivacyManifest: Bool,
        timestamp: Date = Date()
    ) {
        self.status = status
        self.issues = issues
        self.scannedFilesCount = scannedFilesCount
        self.hasPrivacyManifest = hasPrivacyManifest
        self.timestamp = timestamp
    }
}

/// Checks iOS project assets against Apple App Store Guidelines and Privacy Manifest mandates.
public struct AppleComplianceChecker: Sendable {
    public init() {}

    /// Audits project source directory against App Store guidelines.
    public func auditProject(
        directoryURL: URL,
        infoPlistDictionary: [String: Any]? = nil
    ) -> ComplianceAuditReport {
        let fileManager = FileManager.default
        var scanned = 0
        var issues: [ComplianceIssue] = []

        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return ComplianceAuditReport(status: .nonCompliant, issues: [], scannedFilesCount: 0, hasPrivacyManifest: false)
        }

        // 1. Check for Privacy Manifest (PrivacyInfo.xcprivacy)
        let manifestURL = directoryURL.appendingPathComponent("PrivacyInfo.xcprivacy")
        let hasPrivacyManifest = fileManager.fileExists(atPath: manifestURL.path)

        if !hasPrivacyManifest {
            issues.append(ComplianceIssue(
                guideline: "Apple Privacy Manifests (Spring 2024 Mandate)",
                severity: .high,
                title: "Missing PrivacyInfo.xcprivacy",
                explanation: "Apple mandates a Privacy Manifest declaring Required Reason APIs (e.g. UserDefaults, system uptime) and third-party SDK domains.",
                remediationSteps: [
                    "Create PrivacyInfo.xcprivacy in your Xcode project root.",
                    "Declare NSPrivacyAccessedAPITypes for UserDefaults (NSPrivacyAccessedAPICategoryUserDefaults).",
                    "Add NSPrivacyCollectedDataTypes for analytics and diagnostics."
                ]
            ))
        }

        // 2. Scan Swift files for Guideline 2.1 (Placeholders) and Permission APIs
        var usedPermissions: Set<String> = []

        let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])
        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }
            scanned += 1

            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                let relative = fileURL.path.replacingOccurrences(of: directoryURL.path + "/", with: "")
                let fileIssues = auditSourceCode(content: content, filePath: relative)
                issues.append(contentsOf: fileIssues)

                // Accumulate referenced permissions
                if content.contains("AVCaptureDevice") { usedPermissions.insert("NSCameraUsageDescription") }
                if content.contains("CLLocationManager") { usedPermissions.insert("NSLocationWhenInUseUsageDescription") }
                if content.contains("CBCentralManager") { usedPermissions.insert("NSBluetoothAlwaysUsageDescription") }
                if content.contains("PHPhotoLibrary") { usedPermissions.insert("NSPhotoLibraryUsageDescription") }
            }
        }

        // 3. Guideline 5.1.1: Missing Info.plist usage descriptions
        if let infoPlist = infoPlistDictionary {
            for key in usedPermissions {
                if infoPlist[key] == nil {
                    issues.append(ComplianceIssue(
                        guideline: "Guideline 5.1.1 - Data Collection and Storage",
                        severity: .critical,
                        title: "Missing Required Info.plist Usage Description: \(key)",
                        explanation: "App code references system hardware APIs requiring user authorization, but Info.plist lacks the required '\(key)' description string.",
                        remediationSteps: [
                            "Open Info.plist and add key '\(key)'.",
                            "Provide a clear, human-readable justification explaining to the user why the application requires access."
                        ]
                    ))
                }
            }
        }

        let hasCritical = issues.contains { $0.severity == .critical }
        let hasHigh = issues.contains { $0.severity == .high }

        let status: ComplianceStatus
        if hasCritical {
            status = .nonCompliant
        } else if hasHigh {
            status = .atRisk
        } else {
            status = .compliant
        }

        return ComplianceAuditReport(
            status: status,
            issues: issues,
            scannedFilesCount: scanned,
            hasPrivacyManifest: hasPrivacyManifest
        )
    }

    /// Audits individual source code contents for placeholder text or forbidden patterns.
    public func auditSourceCode(content: String, filePath: String) -> [ComplianceIssue] {
        guard !filePath.contains("Compliance") && !filePath.contains("Tests") else { return [] }
        var issues: [ComplianceIssue] = []
        let lines = content.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Guideline 2.1: App Completeness (Lorem Ipsum, example.com in production strings)
            if trimmed.contains("\"Lorem ipsum") || trimmed.contains("Lorem ipsum dolor") {
                issues.append(ComplianceIssue(
                    guideline: "Guideline 2.1 - App Completeness",
                    severity: .high,
                    title: "Placeholder Text 'Lorem Ipsum' in UI String",
                    explanation: "App Store Review rejects apps containing placeholder text, incomplete forms, or dummy labels.",
                    remediationSteps: ["Replace placeholder text with localized production copy."],
                    sourceFile: filePath,
                    sourceLine: lineNumber
                ))
            }

            if trimmed.contains("\"https://example.com") || trimmed.contains("\"http://example.com") {
                issues.append(ComplianceIssue(
                    guideline: "Guideline 2.1 - App Completeness",
                    severity: .medium,
                    title: "Placeholder URL 'example.com' Detected",
                    explanation: "Hardcoded placeholder domain 'example.com' found in production code.",
                    remediationSteps: ["Configure dynamic environment base URL via AppConfiguration."],
                    sourceFile: filePath,
                    sourceLine: lineNumber
                ))
            }
        }

        return issues
    }
}

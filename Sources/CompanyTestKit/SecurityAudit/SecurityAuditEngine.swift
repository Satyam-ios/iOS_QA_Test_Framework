import Foundation
import CompanyiOSKit

/// Security category classifications.
public enum SecurityCategory: String, Codable, Sendable, CaseIterable {
    case credentialLeak = "Credential Leak"
    case insecureStorage = "Insecure Storage"
    case insecureTransport = "Insecure Transport"
    case sensitiveDataLogging = "Sensitive Data in Logs"
    case jailbreakOrIntegrity = "Device Integrity / Jailbreak"
}

/// Discovered security vulnerability or privacy violation.
public struct SecurityFinding: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let category: SecurityCategory
    public let severity: DefectSeverity
    public let sourceFile: String
    public let sourceLine: Int
    public let evidence: String
    public let recommendation: String
    public let remediationSnippet: String?

    public init(
        id: String = UUID().uuidString,
        category: SecurityCategory,
        severity: DefectSeverity,
        sourceFile: String,
        sourceLine: Int,
        evidence: String,
        recommendation: String,
        remediationSnippet: String? = nil
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.sourceFile = sourceFile
        self.sourceLine = sourceLine
        self.evidence = evidence
        self.recommendation = recommendation
        self.remediationSnippet = remediationSnippet
    }
}

/// Comprehensive audit report containing security and privacy findings.
public struct SecurityAuditReport: Codable, Sendable, Equatable {
    public let scannedFilesCount: Int
    public let findings: [SecurityFinding]
    public let timestamp: Date

    public init(
        scannedFilesCount: Int,
        findings: [SecurityFinding],
        timestamp: Date = Date()
    ) {
        self.scannedFilesCount = scannedFilesCount
        self.findings = findings
        self.timestamp = timestamp
    }

    public var criticalCount: Int { findings.filter { $0.severity == .critical }.count }
    public var highCount: Int { findings.filter { $0.severity == .high }.count }
    public var mediumCount: Int { findings.filter { $0.severity == .medium }.count }
    public var lowCount: Int { findings.filter { $0.severity == .low }.count }

    public var isPassing: Bool {
        criticalCount == 0 && highCount == 0
    }
}

/// Automated security and privacy auditing engine for iOS projects.
public struct SecurityAuditEngine: Sendable {
    public init() {}

    /// Audits an entire project folder for static security vulnerabilities.
    public func auditProject(at directoryURL: URL) -> SecurityAuditReport {
        let fileManager = FileManager.default
        var scanned = 0
        var allFindings: [SecurityFinding] = []

        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return SecurityAuditReport(scannedFilesCount: 0, findings: [])
        }

        let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])

        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" || fileURL.lastPathComponent.contains("Info.plist") else { continue }
            scanned += 1

            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                let relative = fileURL.path.replacingOccurrences(of: directoryURL.path + "/", with: "")
                let findings = auditSourceCode(content: content, filePath: relative)
                allFindings.append(contentsOf: findings)
            }
        }

        return SecurityAuditReport(scannedFilesCount: scanned, findings: allFindings)
    }

    /// Audits single source code text for security defects.
    public func auditSourceCode(content: String, filePath: String) -> [SecurityFinding] {
        // Skip self-inspection of auditing definitions and tests to prevent false positives from rule constants
        guard !filePath.contains("SecurityAudit") && !filePath.contains("Tests") && !filePath.contains("AICodeReviewEngine") else {
            return []
        }

        var findings: [SecurityFinding] = []
        let lines = content.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments
            if trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") {
                continue
            }

            // 1. Insecure Storage: Storing secrets/tokens in UserDefaults
            let lower = trimmed.lowercased()
            if (lower.contains("userdefaults") && (lower.contains("token") || lower.contains("password") || lower.contains("apikey") || lower.contains("secret") || lower.contains("auth_key"))) {
                findings.append(SecurityFinding(
                    category: .insecureStorage,
                    severity: .critical,
                    sourceFile: filePath,
                    sourceLine: lineNumber,
                    evidence: SensitiveDataRedactor.shared.redact(trimmed),
                    recommendation: "Never store credentials or auth tokens in unencrypted UserDefaults. Use KeychainManager.",
                    remediationSnippet: "try KeychainManager.shared.save(key: \"authToken\", data: tokenData)"
                ))
            }

            // 2. Hardcoded API Keys / Secrets
            if containsHardcodedSecret(trimmed) {
                findings.append(SecurityFinding(
                    category: .credentialLeak,
                    severity: .critical,
                    sourceFile: filePath,
                    sourceLine: lineNumber,
                    evidence: SensitiveDataRedactor.shared.redact(trimmed),
                    recommendation: "Hardcoded secret detected. Move credentials to Keychain, xcconfig, or secure runtime injection.",
                    remediationSnippet: "let apiKey = AppConfiguration.current.apiKey"
                ))
            }

            // 3. Insecure Transport: Cleartext HTTP
            if trimmed.contains("\"http://") && !trimmed.contains("localhost") && !trimmed.contains("127.0.0.1") {
                findings.append(SecurityFinding(
                    category: .insecureTransport,
                    severity: .high,
                    sourceFile: filePath,
                    sourceLine: lineNumber,
                    evidence: trimmed,
                    recommendation: "Insecure cleartext HTTP URL detected. Use HTTPS with TLS 1.3.",
                    remediationSnippet: trimmed.replacingOccurrences(of: "\"http://", with: "\"https://")
                ))
            }

            // 4. Insecure ATS Overrides in Info.plist
            if trimmed.contains("NSAllowsArbitraryLoads") && (trimmed.contains("<true/>") || trimmed.contains("true")) {
                findings.append(SecurityFinding(
                    category: .insecureTransport,
                    severity: .critical,
                    sourceFile: filePath,
                    sourceLine: lineNumber,
                    evidence: trimmed,
                    recommendation: "App Transport Security is globally disabled. Remove NSAllowsArbitraryLoads before App Store submission."
                ))
            }
        }

        return findings
    }

    private func containsHardcodedSecret(_ line: String) -> Bool {
        let patterns = [
            "sk_" + "live_[0-9a-zA-Z]{24}",
            "AK" + "IA[0-9A-Z]{16}",
            "gh" + "p_[0-9a-zA-Z]{36}",
            "Bearer " + "eyJ[0-9a-zA-Z_-]{20,}"
        ]

        for pattern in patterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }

        // Generic key assignments
        let genericKeyPattern = "(?i)(api[_-]?key|secret[_-]?key|client[_-]?secret)\\s*=\\s*\"[A-Za-z0-9_-]{16,}\""
        if line.range(of: genericKeyPattern, options: .regularExpression) != nil {
            return true
        }

        return false
    }
}

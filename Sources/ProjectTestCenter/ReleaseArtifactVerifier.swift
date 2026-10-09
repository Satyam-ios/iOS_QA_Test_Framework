import Foundation

/// Verification status of release artifact isolation.
public struct ReleaseIsolationReport: Sendable, Equatable {
    public let isIsolated: Bool
    public let inspectedPath: String
    public let foundViolations: [String]
    public let recommendations: [String]

    public init(
        isIsolated: Bool,
        inspectedPath: String,
        foundViolations: [String] = [],
        recommendations: [String] = []
    ) {
        self.isIsolated = isIsolated
        self.inspectedPath = inspectedPath
        self.foundViolations = foundViolations
        self.recommendations = recommendations
    }
}

/// Verifies that macOS CLI tools and non-production testing runners are never linked into production iOS app bundles.
public struct ReleaseArtifactVerifier: Sendable {
    public init() {}

    /// Inspects an app bundle or Xcode project file to verify target isolation.
    public func verifyIsolation(at targetPath: String) -> ReleaseIsolationReport {
        let fileManager = FileManager.default
        var violations: [String] = []
        var recommendations: [String] = []

        guard fileManager.fileExists(atPath: targetPath) else {
            return ReleaseIsolationReport(
                isIsolated: false,
                inspectedPath: targetPath,
                foundViolations: ["Target path not found: \(targetPath)"]
            )
        }

        let url = URL(fileURLWithPath: targetPath)

        // 1. If inspecting an Xcode project (e.g. project.pbxproj)
        if targetPath.contains(".xcodeproj") {
            let pbxprojURL = url.appendingPathComponent("project.pbxproj")
            if let content = try? String(contentsOf: pbxprojURL, encoding: .utf8) {
                // Check if ProjectTestCenter is linked in PBXFrameworksBuildPhase of the iOS target
                if content.contains("ProjectTestCenter in Frameworks") || content.contains("productRef = ProjectTestCenter") {
                    violations.append("ProjectTestCenter CLI executable is referenced in iOS target Frameworks build phase.")
                    recommendations.append("Remove ProjectTestCenter from 'Frameworks, Libraries, and Embedded Content' in Xcode target settings. Only link CompanyiOSKit (and CompanyTestKit for test schemes).")
                }
            }
        }

        // 2. If inspecting a built .app bundle
        if targetPath.hasSuffix(".app") {
            let frameworksURL = url.appendingPathComponent("Frameworks")
            if fileManager.fileExists(atPath: frameworksURL.path) {
                let items = (try? fileManager.contentsOfDirectory(atPath: frameworksURL.path)) ?? []
                for item in items {
                    if item.contains("ProjectTestCenter") {
                        violations.append("Executable ProjectTestCenter found inside .app/Frameworks directory.")
                        recommendations.append("Ensure ProjectTestCenter is configured strictly as a macOS executable product, never embedded in iOS bundles.")
                    }
                }
            }
        }

        let isClean = violations.isEmpty
        return ReleaseIsolationReport(
            isIsolated: isClean,
            inspectedPath: targetPath,
            foundViolations: violations,
            recommendations: recommendations
        )
    }
}

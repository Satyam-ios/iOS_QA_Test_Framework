import Foundation

/// API endpoint discovered through static code scanning.
public struct DiscoveredAPIEndpoint: Codable, Sendable, Equatable, Hashable {
    public let endpoint: String
    public let sourceFile: String
    public let sourceLine: Int
    public let associatedScreenName: String?

    public init(
        endpoint: String,
        sourceFile: String,
        sourceLine: Int,
        associatedScreenName: String? = nil
    ) {
        self.endpoint = endpoint
        self.sourceFile = sourceFile
        self.sourceLine = sourceLine
        self.associatedScreenName = associatedScreenName
    }
}

/// System permission requirement detected in source code or configurations.
public struct DiscoveredPermissionRequirement: Codable, Sendable, Equatable, Hashable {
    public let permissionType: String
    public let usageDescriptionKey: String
    public let sourceFile: String
    public let sourceLine: Int
    public let isConfiguredInInfoPlist: Bool

    public init(
        permissionType: String,
        usageDescriptionKey: String,
        sourceFile: String,
        sourceLine: Int,
        isConfiguredInInfoPlist: Bool = false
    ) {
        self.permissionType = permissionType
        self.usageDescriptionKey = usageDescriptionKey
        self.sourceFile = sourceFile
        self.sourceLine = sourceLine
        self.isConfiguredInInfoPlist = isConfiguredInInfoPlist
    }
}

/// Static code quality finding discovered during source code scanning.
public struct StaticCodeFinding: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let ruleId: String
    public let message: String
    public let severity: DefectSeverity
    public let sourceFile: String
    public let sourceLine: Int
    public let codeSnippet: String
    public let recommendation: String

    public init(
        id: String = UUID().uuidString,
        ruleId: String,
        message: String,
        severity: DefectSeverity,
        sourceFile: String,
        sourceLine: Int,
        codeSnippet: String,
        recommendation: String
    ) {
        self.id = id
        self.ruleId = ruleId
        self.message = message
        self.severity = severity
        self.sourceFile = sourceFile
        self.sourceLine = sourceLine
        self.codeSnippet = codeSnippet
        self.recommendation = recommendation
    }
}

/// Complete structural landscape discovered from source code analysis.
public struct DiscoveredProjectLandscape: Codable, Sendable, Equatable {
    public let scannedFileCount: Int
    public let screens: [ScreenDefinition]
    public let apis: [DiscoveredAPIEndpoint]
    public let permissions: [DiscoveredPermissionRequirement]
    public let codeQualityFindings: [StaticCodeFinding]
    public let scanErrorsOrLimitations: [String]

    public init(
        scannedFileCount: Int,
        screens: [ScreenDefinition],
        apis: [DiscoveredAPIEndpoint],
        permissions: [DiscoveredPermissionRequirement],
        codeQualityFindings: [StaticCodeFinding],
        scanErrorsOrLimitations: [String]
    ) {
        self.scannedFileCount = scannedFileCount
        self.screens = screens
        self.apis = apis
        self.permissions = permissions
        self.codeQualityFindings = codeQualityFindings
        self.scanErrorsOrLimitations = scanErrorsOrLimitations
    }
}

/// Static analyzer scanning iOS source files for UI hierarchies, routes, APIs, and code quality hazards.
public struct ProjectSourceAnalyzer: Sendable {
    public init() {}

    /// Analyzes Swift source files within a project directory hierarchy.
    public func analyzeProject(at directoryURL: URL) -> DiscoveredProjectLandscape {
        let fileManager = FileManager.default
        var scannedFiles = 0
        var allScreens: [ScreenDefinition] = []
        var allAPIs: [DiscoveredAPIEndpoint] = []
        var allPermissions: [DiscoveredPermissionRequirement] = []
        var allFindings: [StaticCodeFinding] = []
        var limitations: [String] = []

        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return DiscoveredProjectLandscape(
                scannedFileCount: 0,
                screens: [],
                apis: [],
                permissions: [],
                codeQualityFindings: [],
                scanErrorsOrLimitations: ["Directory not found or inaccessible: \(directoryURL.path)"]
            )
        }

        let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])

        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }
            scannedFiles += 1

            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                let relativePath = fileURL.path.replacingOccurrences(of: directoryURL.path + "/", with: "")
                let singleFileLandscape = analyzeSourceCode(content: content, filePath: relativePath)
                allScreens.append(contentsOf: singleFileLandscape.screens)
                allAPIs.append(contentsOf: singleFileLandscape.apis)
                allPermissions.append(contentsOf: singleFileLandscape.permissions)
                allFindings.append(contentsOf: singleFileLandscape.codeQualityFindings)
            } catch {
                limitations.append("Unable to read \(fileURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        return DiscoveredProjectLandscape(
            scannedFileCount: scannedFiles,
            screens: allScreens,
            apis: allAPIs,
            permissions: allPermissions,
            codeQualityFindings: allFindings,
            scanErrorsOrLimitations: limitations
        )
    }

    /// Analyzes the string contents of a single Swift source file.
    public func analyzeSourceCode(content: String, filePath: String) -> DiscoveredProjectLandscape {
        let lines = content.components(separatedBy: "\n")
        var screens: [ScreenDefinition] = []
        var apis: [DiscoveredAPIEndpoint] = []
        var permissions: [DiscoveredPermissionRequirement] = []
        var findings: [StaticCodeFinding] = []

        var currentScreenName: String?
        var currentScreenLine: Int = 1
        var currentElements: [UIElementDescriptor] = []
        var currentAPIs: [String] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 1. Screen Discovery (SwiftUI View or UIKit UIViewController)
            if let viewMatch = extractSwiftUIView(from: trimmed) {
                if let name = currentScreenName {
                    screens.append(buildScreen(name: name, line: currentScreenLine, file: filePath, elements: currentElements, apis: currentAPIs))
                    currentElements = []
                    currentAPIs = []
                }
                currentScreenName = viewMatch
                currentScreenLine = lineNumber
            } else if let vcMatch = extractUIViewController(from: trimmed) {
                if let name = currentScreenName {
                    screens.append(buildScreen(name: name, line: currentScreenLine, file: filePath, elements: currentElements, apis: currentAPIs))
                    currentElements = []
                    currentAPIs = []
                }
                currentScreenName = vcMatch
                currentScreenLine = lineNumber
            }

            // 2. Element Descriptors
            if trimmed.contains("Button(") || trimmed.contains("UIButton") {
                let id = "btn_\(lineNumber)"
                currentElements.append(UIElementDescriptor(id: id, type: .button, accessibilityIdentifier: id, accessibilityLabel: "Action Button"))
            } else if trimmed.contains("TextField(") || trimmed.contains("UITextField") {
                let id = "field_\(lineNumber)"
                currentElements.append(UIElementDescriptor(id: id, type: .textField, accessibilityIdentifier: id, accessibilityLabel: "Input Field"))
            } else if trimmed.contains("SecureField(") {
                let id = "secure_\(lineNumber)"
                currentElements.append(UIElementDescriptor(id: id, type: .secureField, accessibilityIdentifier: id, accessibilityLabel: "Secure Field"))
            } else if trimmed.contains("Toggle(") || trimmed.contains("UISwitch") {
                let id = "toggle_\(lineNumber)"
                currentElements.append(UIElementDescriptor(id: id, type: .toggle, accessibilityIdentifier: id, accessibilityLabel: "Toggle"))
            }

            // 3. API Route Literals
            if let endpoint = extractEndpoint(from: trimmed) {
                currentAPIs.append(endpoint)
                apis.append(DiscoveredAPIEndpoint(endpoint: endpoint, sourceFile: filePath, sourceLine: lineNumber, associatedScreenName: currentScreenName))
            }

            // 4. Permissions
            if trimmed.contains("AVCaptureDevice") {
                permissions.append(DiscoveredPermissionRequirement(permissionType: "Camera/Mic", usageDescriptionKey: "NSCameraUsageDescription", sourceFile: filePath, sourceLine: lineNumber))
            } else if trimmed.contains("CLLocationManager") {
                permissions.append(DiscoveredPermissionRequirement(permissionType: "Location", usageDescriptionKey: "NSLocationWhenInUseUsageDescription", sourceFile: filePath, sourceLine: lineNumber))
            } else if trimmed.contains("CBCentralManager") {
                permissions.append(DiscoveredPermissionRequirement(permissionType: "Bluetooth", usageDescriptionKey: "NSBluetoothAlwaysUsageDescription", sourceFile: filePath, sourceLine: lineNumber))
            }

            // 5. Code Quality Findings
            if trimmed.contains("!") && !trimmed.contains("!=") && !trimmed.hasPrefix("//") && !trimmed.contains("\"") {
                findings.append(StaticCodeFinding(
                    ruleId: "UNSAFE_FORCE_UNWRAP",
                    message: "Unsafe force unwrap operator '!' can cause unexpected fatal crash at runtime.",
                    severity: .high,
                    sourceFile: filePath,
                    sourceLine: lineNumber,
                    codeSnippet: trimmed,
                    recommendation: "Replace with 'guard let' or 'if let' optional binding, or nil-coalescing '??'."
                ))
            }

            if trimmed.contains("DispatchQueue.main.sync") {
                findings.append(StaticCodeFinding(
                    ruleId: "MAIN_THREAD_DEADLOCK",
                    message: "Synchronous dispatch to the main queue from the main thread causes immediate deadlock.",
                    severity: .critical,
                    sourceFile: filePath,
                    sourceLine: lineNumber,
                    codeSnippet: trimmed,
                    recommendation: "Use DispatchQueue.main.async or Swift Concurrency MainActor.run { }."
                ))
            }
        }

        if let lastName = currentScreenName {
            screens.append(buildScreen(name: lastName, line: currentScreenLine, file: filePath, elements: currentElements, apis: currentAPIs))
        }

        return DiscoveredProjectLandscape(
            scannedFileCount: 1,
            screens: screens,
            apis: apis,
            permissions: permissions,
            codeQualityFindings: findings,
            scanErrorsOrLimitations: []
        )
    }

    private func extractSwiftUIView(from line: String) -> String? {
        guard line.contains("struct ") && line.contains(": View") else { return nil }
        let parts = line.components(separatedBy: "struct ")
        guard parts.count > 1 else { return nil }
        let after = parts[1]
        let name = after.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces)
        return name
    }

    private func extractUIViewController(from line: String) -> String? {
        guard line.contains("class ") && line.contains(": UIViewController") else { return nil }
        let parts = line.components(separatedBy: "class ")
        guard parts.count > 1 else { return nil }
        let after = parts[1]
        let name = after.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces)
        return name
    }

    private func extractEndpoint(from line: String) -> String? {
        // Look for string literals starting with /api/ or /v1/
        guard let start = line.range(of: "\"/api/") ?? line.range(of: "\"/v1/") else { return nil }
        let suffix = line[start.upperBound...]
        guard let end = suffix.range(of: "\"") else { return nil }
        let route = String(suffix[..<end.lowerBound])
        let prefix = line[start.lowerBound...].hasPrefix("\"/api/") ? "/api/" : "/v1/"
        return prefix + route
    }

    private func buildScreen(name: String, line: Int, file: String, elements: [UIElementDescriptor], apis: [String]) -> ScreenDefinition {
        let route = "/" + name.lowercased().replacingOccurrences(of: "viewcontroller", with: "").replacingOccurrences(of: "view", with: "")
        return ScreenDefinition(
            id: "screen_\(name.lowercased())",
            name: name,
            route: route,
            elements: elements,
            apiDependencies: apis,
            availableStates: [.normal],
            sourceFile: file,
            sourceLine: line,
            featureModule: inferModule(from: file),
            discoverySource: .staticSourceAnalysis,
            viewClassName: name
        )
    }

    private func inferModule(from path: String) -> String {
        let parts = path.components(separatedBy: "/")
        if parts.count > 1 {
            return parts[parts.count - 2]
        }
        return "Core"
    }
}

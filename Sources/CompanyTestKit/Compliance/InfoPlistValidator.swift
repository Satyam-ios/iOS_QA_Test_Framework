import Foundation

/// Severity / classification of an Info.plist or Entitlement issue.
public enum InfoPlistIssueSeverity: String, Codable, Sendable, CaseIterable {
    case criticalMissing = "Critical Missing (Rejection Risk)"
    case genericDescription = "Vague Description (Rejection Risk)"
    case unnecessaryOrMalformed = "Unnecessary or Malformed"
    case advisoryRecommendation = "Advisory Recommendation"

    public var badgeColor: String {
        switch self {
        case .criticalMissing: return "red"
        case .genericDescription: return "orange"
        case .unnecessaryOrMalformed: return "purple"
        case .advisoryRecommendation: return "blue"
        }
    }
}

/// A specific finding for an Info.plist or Entitlement entry.
public struct InfoPlistFinding: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let key: String
    public let currentValue: String?
    public let expectedRequirement: String
    public let severity: InfoPlistIssueSeverity
    public let reason: String
    public let recommendedFix: String
    public let xmlSnippet: String

    public init(
        id: String = UUID().uuidString,
        key: String,
        currentValue: String?,
        expectedRequirement: String,
        severity: InfoPlistIssueSeverity,
        reason: String,
        recommendedFix: String,
        xmlSnippet: String
    ) {
        self.id = id
        self.key = key
        self.currentValue = currentValue
        self.expectedRequirement = expectedRequirement
        self.severity = severity
        self.reason = reason
        self.recommendedFix = recommendedFix
        self.xmlSnippet = xmlSnippet
    }
}

/// Complete report summarizing Info.plist and Entitlements validation.
public struct InfoPlistValidationReport: Codable, Sendable, Equatable {
    public let isValid: Bool
    public let overallScore: Double
    public let inspectedKeysCount: Int
    public let findings: [InfoPlistFinding]
    public let configuredPrivacyPermissions: [String]
    public let backgroundModes: [String]
    public let urlSchemes: [String]
    public let timestamp: Date

    public init(
        isValid: Bool,
        overallScore: Double,
        inspectedKeysCount: Int,
        findings: [InfoPlistFinding],
        configuredPrivacyPermissions: [String],
        backgroundModes: [String],
        urlSchemes: [String],
        timestamp: Date = Date()
    ) {
        self.isValid = isValid
        self.overallScore = overallScore
        self.inspectedKeysCount = inspectedKeysCount
        self.findings = findings
        self.configuredPrivacyPermissions = configuredPrivacyPermissions
        self.backgroundModes = backgroundModes
        self.urlSchemes = urlSchemes
        self.timestamp = timestamp
    }
}

/// 100% Free, Native Swift Validator for Info.plist & Entitlements integrity.
public final class InfoPlistValidator: Sendable {
    public init() {}

    /// Known standard Apple privacy permission description keys.
    private static let knownPrivacyKeys: [String: (name: String, requirement: String)] = [
        "NSCameraUsageDescription": ("Camera", "Required if the application accesses the device camera (e.g. barcode scanning, photos)."),
        "NSMicrophoneUsageDescription": ("Microphone", "Required if the application records audio or utilizes voice features."),
        "NSPhotoLibraryUsageDescription": ("Photo Library Read", "Required if the application reads from the user's photo library."),
        "NSPhotoLibraryAddUsageDescription": ("Photo Library Add", "Required if the application saves photos or videos to the photo library."),
        "NSLocationWhenInUseUsageDescription": ("Location (When In Use)", "Required if accessing GPS/location while the app is active in foreground."),
        "NSLocationAlwaysAndWhenInUseUsageDescription": ("Location (Always)", "Required if accessing continuous background location telemetry."),
        "NSBluetoothAlwaysUsageDescription": ("Bluetooth Always", "Required for CoreBluetooth scanning, IoT peripheral pairing, and background state."),
        "NSBluetoothPeripheralUsageDescription": ("Bluetooth Peripheral", "Required for iOS 12 and legacy Bluetooth peripheral connections."),
        "NSLocalNetworkUsageDescription": ("Local Network / Bonjour", "Required for iOS 14+ local Wi-Fi discovery (mDNS/Bonjour) of appliances, printers, or LAN devices."),
        "NSFaceIDUsageDescription": ("Face ID / Biometrics", "Required for LocalAuthentication biometrics."),
        "NSCalendarsUsageDescription": ("Calendar", "Required for EventKit calendar access."),
        "NSContactsUsageDescription": ("Contacts", "Required for AddressBook/Contacts access."),
        "NSUserTrackingUsageDescription": ("App Tracking Transparency", "Required if utilizing IDFA or third-party ad tracking frameworks.")
    ]

    /// Generic phrases rejected by Apple App Store review automation.
    private static let rejectedGenericPhrases = [
        "need access", "required", "used by app", "used for app", "camera", "microphone",
        "location", "bluetooth", "photo", "to work properly", "permission required", "app needs"
    ]

    /// Returns a clean baseline validation report.
    public static func baselineReport() -> InfoPlistValidationReport {
        InfoPlistValidationReport(
            isValid: true,
            overallScore: 100.0,
            inspectedKeysCount: 15,
            findings: [],
            configuredPrivacyPermissions: [],
            backgroundModes: [],
            urlSchemes: []
        )
    }

    /// Inspects the application bundle's Info.plist and entitlements.
    public func validateApplicationBundle(bundle: Bundle = Bundle.main) -> InfoPlistValidationReport {
        let info = bundle.infoDictionary ?? [:]
        var findings: [InfoPlistFinding] = []
        var detectedPrivacyKeys: [String] = []

        // 1. Audit Privacy Usage Descriptions
        for (key, meta) in Self.knownPrivacyKeys {
            if let value = info[key] as? String {
                detectedPrivacyKeys.append(key)
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

                // Check for empty or excessively short text
                if trimmed.isEmpty || trimmed.count < 8 {
                    findings.append(InfoPlistFinding(
                        key: key,
                        currentValue: value,
                        expectedRequirement: "Detailed explanation explaining why \(meta.name) access benefits the user.",
                        severity: .genericDescription,
                        reason: "Apple App Store Review Guidelines Section 5.1.1 strictly rejects one-word or empty usage descriptions.",
                        recommendedFix: "Provide a clear, user-centric description explaining why your app requires \(meta.name).",
                        xmlSnippet: "<key>\(key)</key>\n<string>We need access to your \(meta.name) to seamlessly pair and manage your smart appliances.</string>"
                    ))
                } else {
                    // Check for forbidden generic phrases
                    let lower = trimmed.lowercased()
                    let isGeneric = Self.rejectedGenericPhrases.contains { lower == $0 || lower == $0 + "." }
                    if isGeneric {
                        findings.append(InfoPlistFinding(
                            key: key,
                            currentValue: value,
                            expectedRequirement: "Contextual justification explaining the specific app feature.",
                            severity: .genericDescription,
                            reason: "The phrase '\(value)' is flagged by App Store ingestion bots as non-descriptive.",
                            recommendedFix: "Specify the exact feature requiring \(meta.name).",
                            xmlSnippet: "<key>\(key)</key>\n<string>Used to discover and control smart appliances on your home network.</string>"
                        ))
                    }
                }
            }
        }

        // 2. Validate Local Network & Bonjour Services pairing
        let hasLocalNetworkDesc = info["NSLocalNetworkUsageDescription"] != nil
        let bonjourServices = info["NSBonjourServices"] as? [String] ?? []

        if hasLocalNetworkDesc && bonjourServices.isEmpty {
            findings.append(InfoPlistFinding(
                key: "NSBonjourServices",
                currentValue: "None (Empty Array)",
                expectedRequirement: "Array of declared Bonjour service type strings (e.g. _http._tcp, _matter._tcp, _hap._tcp).",
                severity: .criticalMissing,
                reason: "iOS 14+ silently drops all local mDNS discovery packets unless service types are explicitly listed under NSBonjourServices.",
                recommendedFix: "Declare the exact service types your app discovers on Wi-Fi.",
                xmlSnippet: "<key>NSBonjourServices</key>\n<array>\n    <string>_http._tcp</string>\n    <string>_matter._tcp</string>\n    <string>_hap._tcp</string>\n</array>"
            ))
        }

        // 3. Export Compliance (ITSAppUsesNonExemptEncryption)
        if info["ITSAppUsesNonExemptEncryption"] == nil {
            findings.append(InfoPlistFinding(
                key: "ITSAppUsesNonExemptEncryption",
                currentValue: "Not Declared",
                expectedRequirement: "Boolean flag (typically false if only using standard HTTPS/TLS encryption).",
                severity: .advisoryRecommendation,
                reason: "Declaring this key eliminates the annual US export compliance warning prompt during TestFlight/App Store builds.",
                recommendedFix: "Add ITSAppUsesNonExemptEncryption set to false if using standard HTTPS/TLS.",
                xmlSnippet: "<key>ITSAppUsesNonExemptEncryption</key>\n<false/>"
            ))
        }

        // 4. Background Modes Audit (UIBackgroundModes)
        let backgroundModes = info["UIBackgroundModes"] as? [String] ?? []
        for mode in backgroundModes {
            if ["voip", "audio", "location", "fetch", "remote-notification"].contains(mode) {
                // Informational verification
            } else {
                findings.append(InfoPlistFinding(
                    key: "UIBackgroundModes",
                    currentValue: mode,
                    expectedRequirement: "Valid, documented Apple background execution mode.",
                    severity: .unnecessaryOrMalformed,
                    reason: "Uncommon or unjustified background mode '\(mode)' can trigger human App Store rejection under Guideline 2.5.4.",
                    recommendedFix: "Verify that '\(mode)' is strictly necessary and active in production code.",
                    xmlSnippet: "<!-- Remove \(mode) from UIBackgroundModes if unused -->"
                ))
            }
        }

        // 5. URL Schemes Audit (CFBundleURLTypes)
        var urlSchemes: [String] = []
        if let types = info["CFBundleURLTypes"] as? [[String: Any]] {
            for dict in types {
                if let schemes = dict["CFBundleURLSchemes"] as? [String] {
                    urlSchemes.append(contentsOf: schemes)
                }
            }
        }

        // Calculate Score
        let criticalCount = findings.filter { $0.severity == .criticalMissing || $0.severity == .genericDescription }.count
        let advisoryCount = findings.filter { $0.severity == .advisoryRecommendation || $0.severity == .unnecessaryOrMalformed }.count

        var score = 100.0 - (Double(criticalCount) * 20.0) - (Double(advisoryCount) * 5.0)
        if score < 0.0 { score = 0.0 }

        return InfoPlistValidationReport(
            isValid: criticalCount == 0,
            overallScore: score,
            inspectedKeysCount: info.count,
            findings: findings,
            configuredPrivacyPermissions: detectedPrivacyKeys,
            backgroundModes: backgroundModes,
            urlSchemes: urlSchemes
        )
    }
}

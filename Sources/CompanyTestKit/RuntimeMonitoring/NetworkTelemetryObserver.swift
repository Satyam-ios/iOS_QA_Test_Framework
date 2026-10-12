import Foundation
import CompanyiOSKit

/// Classifies network failure origins to distinguish client code bugs from backend outages.
public enum NetworkFailureOrigin: String, Codable, Sendable {
    case clientDefect = "CLIENT_DEFECT"             // 4xx Bad Request, malformed JSON sent, etc.
    case backendOutage = "BACKEND_OUTAGE"           // 5xx Internal Server Error, Bad Gateway, etc.
    case environmentOrTimeout = "NETWORK_TIMEOUT"   // Timeout, no connectivity, DNS failure
    case contractMismatch = "CONTRACT_MISMATCH"     // Expected response model did not match payload
}

/// Record of an observed network telemetry event.
public struct ObservedNetworkEvent: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let timestamp: Date
    public let endpoint: String
    public let httpMethod: String
    public let statusCode: Int?
    public let duration: TimeInterval
    public let failureOrigin: NetworkFailureOrigin?
    public let errorMessage: String?
    public let sanitizedHeaders: [String: String]

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        endpoint: String,
        httpMethod: String,
        statusCode: Int?,
        duration: TimeInterval,
        failureOrigin: NetworkFailureOrigin?,
        errorMessage: String?,
        sanitizedHeaders: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.statusCode = statusCode
        self.duration = duration
        self.failureOrigin = failureOrigin
        self.errorMessage = errorMessage
        self.sanitizedHeaders = sanitizedHeaders
    }
}

/// Passive observer recording network transaction outcomes and flagging contract/outage failures.
public final class NetworkTelemetryObserver: @unchecked Sendable {
    public static let shared = NetworkTelemetryObserver()

    private let lock = NSLock()
    private var observedEvents: [ObservedNetworkEvent] = []

    private init() {
        NotificationCenter.default.addObserver(
            forName: .companyAPIDidFailDecoding,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let path = userInfo["path"] as? String,
                  let targetType = userInfo["targetType"] as? String,
                  let error = userInfo["error"] as? Error else { return }
            self.recordContractViolation(endpoint: path, targetType: targetType, decodingError: error)
        }
    }

    /// Records a completed network request outcome.
    public func record(
        endpoint: String,
        method: String,
        statusCode: Int?,
        duration: TimeInterval,
        error: Error? = nil,
        headers: [String: String] = [:]
    ) {
        lock.lock()
        defer { lock.unlock() }

        // Sanitize headers
        var safeHeaders: [String: String] = [:]
        for (k, v) in headers {
            if k.lowercased().contains("auth") || k.lowercased().contains("cookie") || k.lowercased().contains("key") {
                safeHeaders[k] = "[REDACTED]"
            } else {
                safeHeaders[k] = SensitiveDataRedactor.shared.redact(v)
            }
        }

        // Determine failure origin
        var origin: NetworkFailureOrigin?
        var severity: DefectSeverity = .info

        if let status = statusCode {
            if (500...599).contains(status) {
                origin = .backendOutage
                severity = .high
            } else if (400...499).contains(status) {
                origin = .clientDefect
                severity = (status == 401 || status == 403) ? .medium : .high
            }
        } else if let err = error {
            let nsErr = err as NSError
            if nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorTimedOut {
                origin = .environmentOrTimeout
                severity = .medium
            } else {
                origin = .environmentOrTimeout
                severity = .high
            }
        }

        let event = ObservedNetworkEvent(
            endpoint: endpoint,
            httpMethod: method,
            statusCode: statusCode,
            duration: duration,
            failureOrigin: origin,
            errorMessage: error?.localizedDescription,
            sanitizedHeaders: safeHeaders
        )
        observedEvents.append(event)

        // Forward failures to RuntimeTelemetryStore
        if let failOrigin = origin {
            let category: RuntimeEventCategory = (failOrigin == .contractMismatch) ? .contractViolation : .networkFailure
            let statusText = statusCode != nil ? "HTTP \(statusCode!)" : "Error"
            RuntimeTelemetryStore.shared.record(
                category: category,
                severity: severity,
                title: "\(failOrigin.rawValue): \(method) \(endpoint) (\(statusText))",
                details: error?.localizedDescription ?? "Status \(statusText) returned from endpoint.",
                sourceLocation: endpoint,
                contextMetadata: [
                    "origin": failOrigin.rawValue,
                    "method": method,
                    "duration": String(format: "%.3fs", duration)
                ]
            )
        }
    }

    /// Records a model decoding contract violation.
    public func recordContractViolation(
        endpoint: String,
        targetType: String,
        decodingError: Error
    ) {
        lock.lock()
        defer { lock.unlock() }

        let event = ObservedNetworkEvent(
            endpoint: endpoint,
            httpMethod: "RESPONSE_DECODING",
            statusCode: 200,
            duration: 0.0,
            failureOrigin: .contractMismatch,
            errorMessage: "Failed to decode \(targetType): \(decodingError.localizedDescription)"
        )
        observedEvents.append(event)

        RuntimeTelemetryStore.shared.record(
            category: .contractViolation,
            severity: .high,
            title: "API Contract Mismatch: \(targetType)",
            details: "Endpoint '\(endpoint)' returned JSON payload incompatible with model '\(targetType)': \(decodingError.localizedDescription)",
            sourceLocation: endpoint,
            contextMetadata: ["targetModel": targetType]
        )
    }

    /// Returns all observed network events.
    public var events: [ObservedNetworkEvent] {
        lock.lock()
        defer { lock.unlock() }
        return observedEvents
    }

    /// Clears observed events.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        observedEvents.removeAll()
    }
}

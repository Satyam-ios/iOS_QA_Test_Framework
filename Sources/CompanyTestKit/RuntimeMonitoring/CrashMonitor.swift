import Foundation
import CompanyiOSKit

/// Details of a captured uncaught exception or fatal signal crash.
public struct CrashReport: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let timestamp: Date
    public let name: String
    public let reason: String
    public let callStack: [String]
    public let appVersion: String
    public let osVersion: String

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        name: String,
        reason: String,
        callStack: [String] = [],
        appVersion: String = "1.0.0",
        osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString
    ) {
        self.id = id
        self.timestamp = timestamp
        self.name = name
        self.reason = reason
        self.callStack = callStack
        self.appVersion = appVersion
        self.osVersion = osVersion
    }
}

/// Global hook callback holding safe static reference for C function pointers.
private final class CrashMonitorState: @unchecked Sendable {
    static let shared = CrashMonitorState()
    var isInstalled = false
    var crashLogDirectory: URL?
    private init() {}
}

/// Lightweight, crash-safe monitor capturing uncaught exceptions and fatal termination signals.
public final class CrashMonitor: @unchecked Sendable {
    public static let shared = CrashMonitor()

    private let lock = NSLock()
    private var detectedCrashReports: [CrashReport] = []

    private init() {
        setupDirectory()
        loadPersistedCrashes()
    }

    private func setupDirectory() {
        let fileManager = FileManager.default
        let baseDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let crashDir = baseDir.appendingPathComponent("CompanyTestKit_Crashes", isDirectory: true)
        try? fileManager.createDirectory(at: crashDir, withIntermediateDirectories: true)
        CrashMonitorState.shared.crashLogDirectory = crashDir
    }

    private func loadPersistedCrashes() {
        guard let dir = CrashMonitorState.shared.crashLogDirectory else { return }
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }

        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let report = try? JSONDecoder().decode(CrashReport.self, from: data) {
                detectedCrashReports.append(report)
                // Register into RuntimeTelemetryStore
                RuntimeTelemetryStore.shared.record(
                    category: .crash,
                    severity: .critical,
                    title: "Fatal Crash: \(report.name)",
                    details: "\(report.reason) (at \(report.timestamp))",
                    sourceLocation: report.callStack.first,
                    stackTrace: report.callStack,
                    contextMetadata: ["appVersion": report.appVersion, "osVersion": report.osVersion]
                )
            }
        }
    }

    /// Installs exception and signal handlers to catch fatal errors.
    public func startMonitoring() {
        lock.lock()
        defer { lock.unlock() }

        guard !CrashMonitorState.shared.isInstalled else { return }
        CrashMonitorState.shared.isInstalled = true

        // 1. Uncaught NSException handler
        NSSetUncaughtExceptionHandler { exception in
            let symbols = exception.callStackSymbols
            let name = exception.name.rawValue
            let reason = exception.reason ?? "No reason specified"
            let report = CrashReport(name: name, reason: reason, callStack: symbols)

            if let dir = CrashMonitorState.shared.crashLogDirectory {
                let fileURL = dir.appendingPathComponent("crash_\(UUID().uuidString).json")
                if let data = try? JSONEncoder().encode(report) {
                    try? data.write(to: fileURL, options: .atomic)
                }
            }
        }

        // 2. POSIX Signal Handlers
        let signals: [Int32] = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE]
        for sig in signals {
            signal(sig) { signalNumber in
                let signalName: String
                switch signalNumber {
                case SIGABRT: signalName = "SIGABRT"
                case SIGILL: signalName = "SIGILL"
                case SIGSEGV: signalName = "SIGSEGV"
                case SIGFPE: signalName = "SIGFPE"
                case SIGBUS: signalName = "SIGBUS"
                case SIGPIPE: signalName = "SIGPIPE"
                default: signalName = "SIGNAL_\(signalNumber)"
                }

                let symbols = Thread.callStackSymbols
                let report = CrashReport(
                    name: "Fatal Signal \(signalName)",
                    reason: "Process terminated with POSIX signal \(signalNumber)",
                    callStack: symbols
                )

                if let dir = CrashMonitorState.shared.crashLogDirectory {
                    let fileURL = dir.appendingPathComponent("signal_\(UUID().uuidString).json")
                    if let data = try? JSONEncoder().encode(report) {
                        try? data.write(to: fileURL, options: .atomic)
                    }
                }
                exit(signalNumber)
            }
        }
    }

    /// Records a diagnostic exception or simulated crash event without terminating process.
    public func recordDiagnosticException(name: String, reason: String, stackSymbols: [String] = Thread.callStackSymbols) {
        lock.lock()
        defer { lock.unlock() }

        let report = CrashReport(name: name, reason: reason, callStack: stackSymbols)
        detectedCrashReports.append(report)

        RuntimeTelemetryStore.shared.record(
            category: .crash,
            severity: .critical,
            title: "Exception Diagnostic: \(name)",
            details: reason,
            sourceLocation: stackSymbols.first,
            stackTrace: stackSymbols
        )
    }

    /// All historical crash reports known to this device.
    public var historicalCrashReports: [CrashReport] {
        lock.lock()
        defer { lock.unlock() }
        return detectedCrashReports
    }

    /// Clears crash logs from memory and disk.
    public func clearCrashLogs() {
        lock.lock()
        defer { lock.unlock() }

        detectedCrashReports.removeAll()
        if let dir = CrashMonitorState.shared.crashLogDirectory {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for file in files {
                    try? fileManager.removeItem(at: file)
                }
            }
        }
    }
}

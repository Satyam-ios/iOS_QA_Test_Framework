import Foundation
import os

/// Protocol defining the logging interface.
public protocol LoggerProtocol: Sendable {
    var minimumLogLevel: LogLevel { get }
    func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        category: String,
        file: String,
        function: String,
        line: Int
    )
}

public extension LoggerProtocol {
    func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: level, category: category, file: file, function: function, line: line)
    }


    func verbose(_ message: @autoclosure () -> String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), level: .verbose, category: category, file: file, function: function, line: line)
    }

    func debug(_ message: @autoclosure () -> String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), level: .debug, category: category, file: file, function: function, line: line)
    }

    func info(_ message: @autoclosure () -> String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), level: .info, category: category, file: file, function: function, line: line)
    }

    func warning(_ message: @autoclosure () -> String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), level: .warning, category: category, file: file, function: function, line: line)
    }

    func error(_ message: @autoclosure () -> String, category: String = "App", file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), level: .error, category: category, file: file, function: function, line: line)
    }
}

/// Standard production logger with automatic sensitive data redaction.
public final class AppLogger: LoggerProtocol, @unchecked Sendable {
    public static let shared = AppLogger()

    private let lock = NSLock()
    private var _minimumLogLevel: LogLevel
    private let redactor: SensitiveDataRedactor
    private let subsystem: String

    public var minimumLogLevel: LogLevel {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _minimumLogLevel
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _minimumLogLevel = newValue
        }
    }

    public init(
        subsystem: String = "com.company.ioskit",
        minimumLogLevel: LogLevel = .debug,
        redactor: SensitiveDataRedactor = .shared
    ) {
        self.subsystem = subsystem
        self._minimumLogLevel = minimumLogLevel
        self.redactor = redactor
    }

    public func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLogLevel, level != .none else { return }

        let rawText = message()
        let sanitizedText = redactor.redact(rawText)
        let fileName = (file as NSString).lastPathComponent

        let formatted = "[\(level.tag)] [\(category)] [\(fileName):\(line)] \(function) -> \(sanitizedText)"

        let osLog = os.Logger(subsystem: subsystem, category: category)
        switch level {
        case .verbose, .debug:
            osLog.debug("\(formatted, privacy: .public)")
        case .info:
            osLog.info("\(formatted, privacy: .public)")
        case .warning:
            osLog.warning("\(formatted, privacy: .public)")
        case .error:
            osLog.error("\(formatted, privacy: .public)")
        case .none:
            break
        }
    }
}

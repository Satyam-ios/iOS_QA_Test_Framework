import Foundation

// MARK: - Objective-C Compatible Keychain Manager

@objc(CompanyObjcKeychainManager)
public final class CompanyObjcKeychainManager: NSObject, @unchecked Sendable {
    @objc public static let shared = CompanyObjcKeychainManager()

    private let keychain = KeychainManager.shared

    private override init() {
        super.init()
    }

    @objc public func save(string: String, forKey key: String) throws {
        try keychain.save(key: key, string: string)
    }

    @objc public func readString(forKey key: String) -> String? {
        return try? keychain.readString(key: key)
    }

    @objc public func delete(key: String) throws {
        try keychain.delete(key: key)
    }

    @objc public func deleteAll() throws {
        try keychain.deleteAll()
    }
}

// MARK: - Objective-C Compatible Validator

@objc(CompanyObjcValidator)
public final class CompanyObjcValidator: NSObject, Sendable {
    private override init() {
        super.init()
    }

    @objc public static func validateEmail(_ email: String) -> Bool {
        return EmailValidator.shared.validate(email).isValid
    }

    @objc public static func emailValidationError(_ email: String) -> String? {
        return EmailValidator.shared.validate(email).failureReason
    }

    @objc public static func validatePhone(_ phone: String) -> Bool {
        return PhoneValidator.shared.validate(phone).isValid
    }

    @objc public static func phoneValidationError(_ phone: String) -> String? {
        return PhoneValidator.shared.validate(phone).failureReason
    }

    @objc public static func validatePassword(_ password: String) -> Bool {
        return PasswordValidator.standard.validate(password).isValid
    }

    @objc public static func passwordValidationError(_ password: String) -> String? {
        return PasswordValidator.standard.validate(password).failureReason
    }
}

// MARK: - Objective-C Compatible Logger

@objc(CompanyObjcLogger)
public final class CompanyObjcLogger: NSObject, @unchecked Sendable {
    @objc public static let shared = CompanyObjcLogger()

    private let logger = AppLogger.shared

    private override init() {
        super.init()
    }

    @objc public func logDebug(_ message: String) {
        logger.debug(message)
    }

    @objc public func logInfo(_ message: String) {
        logger.info(message)
    }

    @objc public func logWarning(_ message: String) {
        logger.warning(message)
    }

    @objc public func logError(_ message: String) {
        logger.error(message)
    }
}

// MARK: - Objective-C Compatible API Client

@objc(CompanyObjcAPIClient)
public final class CompanyObjcAPIClient: NSObject, @unchecked Sendable {
    @objc public static let shared = CompanyObjcAPIClient()

    private var client: APIClient

    public init(baseURL: URL = AppEnvironment.production.defaultBaseURL) {
        self.client = APIClient(baseURL: baseURL)
        super.init()
    }

    @objc public func setBaseURL(_ url: URL) {
        self.client = APIClient(baseURL: url)
    }

    @objc public func executeRequest(
        path: String,
        method: String,
        body: Data? = nil,
        completion: @escaping @Sendable (Data?, Int, Error?) -> Void
    ) {
        let httpMethod: HTTPMethod
        switch method.uppercased() {
        case "POST": httpMethod = .post
        case "PUT": httpMethod = .put
        case "DELETE": httpMethod = .delete
        case "PATCH": httpMethod = .patch
        default: httpMethod = .get
        }

        let request = APIRequest(
            path: path,
            method: httpMethod,
            body: body
        )

        Task {
            do {
                let (data, response) = try await self.client.executeRaw(request)
                completion(data, response.statusCode, nil)
            } catch {
                completion(nil, 0, error)
            }
        }
    }
}

// MARK: - Objective-C Compatible Session Manager

@objc(CompanyObjcSessionManager)
public final class CompanyObjcSessionManager: NSObject, @unchecked Sendable {
    @objc public static let shared = CompanyObjcSessionManager()

    private let sessionManager = SessionManager.shared

    private override init() {
        super.init()
    }

    @objc public func setAuthenticated(userId: String) {
        Task {
            await sessionManager.setAuthenticated(userId: userId)
        }
    }

    @objc public func logout(completion: @escaping @Sendable (Error?) -> Void) {
        Task {
            do {
                try await sessionManager.logout()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    @objc public func checkAuthentication(completion: @escaping @Sendable (Bool) -> Void) {
        Task {
            let state = await sessionManager.currentState
            completion(state.isAuthenticated)
        }
    }
}

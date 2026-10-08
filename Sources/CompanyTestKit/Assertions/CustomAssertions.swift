import Foundation
import CompanyiOSKit

/// Domain assertions for validating results and errors cleanly.
public enum CustomAssertions {
    public static func assertSuccess<T, E: Error>(_ result: Result<T, E>) throws -> T {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    public static func assertAppError(_ error: Error, expected: AppError) -> Bool {
        guard let appError = error as? AppError else { return false }
        return appError == expected
    }
}

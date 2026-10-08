import Foundation

/// Common constants used across networking, persistence, and caching.
public enum AppConstants {
    public enum HTTPHeader {
        public static let authorization = "Authorization"
        public static let contentType = "Content-Type"
        public static let accept = "Accept"
        public static let userAgent = "User-Agent"
        public static let requestId = "X-Request-ID"
        public static let clientVersion = "X-Client-Version"
    }

    public enum ContentType {
        public static let json = "application/json"
        public static let formUrlEncoded = "application/x-www-form-urlencoded"
        public static let multipartFormData = "multipart/form-data"
    }

    public enum Storage {
        public static let defaultCacheDuration: TimeInterval = 86400 // 24 hours
        public static let defaultMaxDiskCacheBytes: Int = 50 * 1024 * 1024 // 50 MB
    }
}

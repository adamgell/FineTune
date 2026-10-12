import Foundation

nonisolated struct AutomationError: Error, Codable, Equatable, Sendable {
    enum Code: String, Codable, Sendable {
        case invalidRequest = "invalid_request", unsupportedVersion = "unsupported_version", unknownMethod = "unknown_method", invalidParameter = "invalid_parameter", notFound = "not_found", ambiguousTarget = "ambiguous_target", unavailable, permissionRequired = "permission_required", conflict, busy, timeout, internalError = "internal_error"
    }
    let code: Code
    let message: String
    let field: String?
    init(_ code: Code, _ message: String, field: String? = nil) { self.code = code; self.message = message; self.field = field }
}

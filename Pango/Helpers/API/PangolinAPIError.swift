enum PangolinAPIError: Error, Equatable, Sendable {
    case invalidBaseURL
    case missingAPIKey
    case organizationRequired
    case transport
    case unauthenticated
    case forbidden
    case unsupported
    case serverRejected(status: Int, message: String)
    case httpFailure(status: Int)
    case decoding

    var localizationKey: String {
        switch self {
        case .invalidBaseURL:
            return "ERROR_INVALID_SERVER_URL"
        case .missingAPIKey, .unauthenticated:
            return "ERROR_API_KEY"
        case .organizationRequired:
            return "ERROR_ORGANIZATION_REQUIRED"
        case .transport:
            return "ERROR_CONNECTING_TO_SERVER"
        case .forbidden:
            return "ERROR_API_PERMISSION"
        case .unsupported:
            return "ERROR_API_UNSUPPORTED"
        case .serverRejected:
            return "ERROR_API_REJECTED"
        case .httpFailure:
            return "ERROR_API_HTTP"
        case .decoding:
            return "ERROR_API_RESPONSE"
        }
    }
}

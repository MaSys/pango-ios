import Foundation

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
    case resourcePasswordTooShort
    case resourcePasswordTooLong
    case resourcePinCodeInvalid

    func localizedMessage(bundle: Bundle = .main) -> String {
        if case let .serverRejected(status, message) = self, [400, 409, 422].contains(status),
           let validationMessage = PangolinValidationMessage.message(for: message, bundle: bundle) {
            return validationMessage
        }
        return bundle.localizedString(forKey: localizationKey, value: nil, table: nil)
    }

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
        case .resourcePasswordTooShort:
            return "ERROR_RESOURCE_PASSWORD_TOO_SHORT"
        case .resourcePasswordTooLong:
            return "ERROR_RESOURCE_PASSWORD_TOO_LONG"
        case .resourcePinCodeInvalid:
            return "ERROR_RESOURCE_PIN_CODE_INVALID"
        }
    }
}

import Foundation

/// Translates recognized Pangolin/Zod validation details without displaying raw server text.
enum PangolinValidationMessage {
    static func message(for serverMessage: String, bundle: Bundle) -> String? {
        switch serverMessage {
        case "INVALID_PORT":
            return localized("ERROR_VALIDATION_PORT", bundle: bundle)
        case "PATH_REQUIRED":
            return localized("ERROR_VALIDATION_PATH_REQUIRED", bundle: bundle)
        default:
            break
        }
        guard serverMessage.hasPrefix("Validation error: "), serverMessage.utf8.count <= 16_384 else { return nil }
        let details = String(serverMessage.dropFirst("Validation error: ".count))
        if details == "Invalid subdomain" {
            return localized("ERROR_VALIDATION_SUBDOMAIN", bundle: bundle)
        }
        var messages: [String] = []
        for issue in details.components(separatedBy: "; ") {
            if let message = message(forIssue: issue, bundle: bundle), !messages.contains(message) {
                messages.append(message)
            }
            if messages.count == 5 { break }
        }
        return messages.isEmpty ? nil : messages.joined(separator: "\n")
    }

    private static func message(forIssue issue: String, bundle: Bundle) -> String? {
        guard let separator = issue.range(of: " at \"", options: .backwards), issue.hasSuffix("\"") else { return nil }
        let path = String(issue[separator.upperBound...].dropLast())
        let field = String(path.prefix { $0 != "." && $0 != "[" })
        guard let fieldKey = fields[field] else { return nil }
        let detail = String(issue[..<separator.lowerBound]).lowercased()
        let label = localized(fieldKey, bundle: bundle)
        if field == "pincode" { return localized("ERROR_RESOURCE_PIN_CODE_INVALID", bundle: bundle) }
        if detail.contains("invalid email") { return localized("ERROR_VALIDATION_EMAIL", bundle: bundle) }
        if detail.contains("invalid url") { return format("ERROR_VALIDATION_URL", label, bundle: bundle) }
        if detail.contains("received undefined") || detail.contains("required") {
            return format("ERROR_VALIDATION_REQUIRED", label, bundle: bundle)
        }
        if detail.contains("expected int") || detail.contains("expected integer") {
            return format("ERROR_VALIDATION_INTEGER", label, bundle: bundle)
        }
        let isLength = detail.contains("string") || detail.contains("character")
        let isArray = detail.contains("array") || detail.contains("element") || detail.contains("items")
        if let minimum = number(in: detail, pattern: #"(?:>=|at least |greater than or equal to )(\d+)"#) {
            if minimum == 1 && isLength { return format("ERROR_VALIDATION_REQUIRED", label, bundle: bundle) }
            let key = isLength ? "ERROR_VALIDATION_MIN_LENGTH" : isArray ? "ERROR_VALIDATION_MIN_ITEMS" : "ERROR_VALIDATION_MIN_NUMBER"
            return format(key, label, minimum, bundle: bundle)
        }
        if let maximum = number(in: detail, pattern: #"(?:<=|at most |less than or equal to )(\d+)"#) {
            let key = isLength ? "ERROR_VALIDATION_MAX_LENGTH" : isArray ? "ERROR_VALIDATION_MAX_ITEMS" : "ERROR_VALIDATION_MAX_NUMBER"
            return format(key, label, maximum, bundle: bundle)
        }
        if let minimum = number(in: detail, pattern: #"(?:>|greater than )(\d+)"#) {
            return format("ERROR_VALIDATION_GREATER_NUMBER", label, minimum, bundle: bundle)
        }
        if let maximum = number(in: detail, pattern: #"(?:<|less than )(\d+)"#) {
            return format("ERROR_VALIDATION_LESS_NUMBER", label, maximum, bundle: bundle)
        }
        if field == "subdomain" { return localized("ERROR_VALIDATION_SUBDOMAIN", bundle: bundle) }
        return format("ERROR_VALIDATION_FIELD", label, bundle: bundle)
    }

    private static func number(in detail: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: detail, range: NSRange(detail.startIndex..., in: detail)),
              let range = Range(match.range(at: 1), in: detail) else { return nil }
        return Int(detail[range])
    }

    private static func format(_ key: String, _ label: String, _ limit: Int? = nil, bundle: Bundle) -> String {
        var arguments: [CVarArg] = [label]
        if let limit { arguments.append(limit) }
        return String(format: localized(key, bundle: bundle), arguments: arguments)
    }

    private static func localized(_ key: String, bundle: Bundle) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private static let fields: [String: String] = [
        "name": "NAME", "description": "DESCRIPTION", "password": "PASSWORD", "pincode": "PIN_CODE",
        "email": "EMAIL", "validHours": "VALID_FOR", "roleId": "ROLE", "roleIds": "ROLES",
        "userIds": "USERS", "clientIds": "CLIENTS", "siteId": "SITE", "siteIds": "SITES",
        "domainId": "BASE_DOMAIN", "subdomain": "SUBDOMAIN", "ip": "IP_HOSTNAME", "port": "PORT",
        "proxyPort": "PORT", "destinationPort": "PORT", "destination": "DESTINATION", "alias": "ALIAS",
        "tcpPortRangeString": "TCP", "udpPortRangeString": "UDP", "path": "PATH",
        "rewritePath": "REWRITE_PATH", "pathMatchType": "MATCH_TYPE", "rewritePathType": "REWRITE_TYPE",
        "mode": "MODE", "type": "TYPE", "method": "METHOD", "scheme": "SCHEME", "protocol": "PROTOCOL",
        "url": "URL", "interval": "INTERVAL", "triggerType": "TRIGGER_TYPE",
        "notificationMethod": "NOTIFICATION_METHOD", "notificationTarget": "NOTIFICATION_TARGET",
        "clientId": "CLIENT_ID", "clientSecret": "CLIENT_SECRET", "authUrl": "AUTH_URL", "tokenUrl": "TOKEN_URL",
        "scopes": "SCOPES", "identifierPath": "IDENTIFIER_PATH", "emailPath": "EMAIL_PATH", "namePath": "NAME_PATH",
        "variant": "VARIANT", "orgId": "ORGANIZATION_ID", "hcPort": "PORT", "hcHostname": "IP_HOSTNAME",
        "hcPath": "PATH", "hcInterval": "INTERVAL", "hcTimeout": "TIMEOUT"
    ]
}

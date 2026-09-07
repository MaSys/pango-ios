import Foundation

struct PangolinAPIConfiguration: Sendable {
    enum Error: Swift.Error, Equatable {
        case invalidBaseURL
        case missingAPIKey
    }

    let baseURL: URL
    private let apiKey: String

    var authorizationHeader: String {
        "Bearer \(apiKey)"
    }

    init(baseURLString: String, apiKey: String) throws {
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAPIKey.isEmpty else {
            throw Error.missingAPIKey
        }

        let trimmedURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmedURL),
              components.scheme?.lowercased() == "https",
              components.host?.isEmpty == false,
              components.query == nil,
              components.fragment == nil else {
            throw Error.invalidBaseURL
        }

        var path = components.path
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        if path == "/" || path == "/v1" {
            path = ""
        }
        components.path = path

        guard let baseURL = components.url else {
            throw Error.invalidBaseURL
        }

        self.baseURL = baseURL
        self.apiKey = trimmedAPIKey
    }
}

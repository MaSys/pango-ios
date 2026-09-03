import Foundation

struct PangolinAPIClient: Sendable {
    private let configuration: PangolinAPIConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        configuration: PangolinAPIConfiguration,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.configuration = configuration
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func send<Response: Decodable>(
        _ method: PangolinHTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> PangolinResponse<Response> {
        let data = try await perform(method, path: path, queryItems: queryItems, body: nil)
        return try decode(PangolinResponse<Response>.self, from: data)
    }

    func send<Response: Decodable, Body: Encodable>(
        _ method: PangolinHTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: Body
    ) async throws -> PangolinResponse<Response> {
        let encodedBody: Data
        do {
            encodedBody = try encoder.encode(body)
        } catch {
            throw PangolinAPIError.decoding
        }
        let data = try await perform(method, path: path, queryItems: queryItems, body: encodedBody)
        return try decode(PangolinResponse<Response>.self, from: data)
    }

    func sendRaw<Response: Decodable>(
        _ method: PangolinHTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        let data = try await perform(method, path: path, queryItems: queryItems, body: nil)
        return try decode(Response.self, from: data)
    }

    private func perform(
        _ method: PangolinHTTPMethod,
        path: String,
        queryItems: [URLQueryItem],
        body: Data?
    ) async throws -> Data {
        let url = try requestURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(configuration.authorizationHeader, forHTTPHeaderField: "Authorization")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw PangolinAPIError.transport
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PangolinAPIError.transport
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw mapError(statusCode: httpResponse.statusCode, data: data)
        }

        return data
    }

    private func decode<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw PangolinAPIError.decoding
        }
    }

    private func requestURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw PangolinAPIError.invalidBaseURL
        }
        let relativePath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = relativePath.isEmpty ? "/v1" : "/v1/\(relativePath)"
        components.percentEncodedQuery = encodedQuery(queryItems)
        guard let url = components.url else {
            throw PangolinAPIError.invalidBaseURL
        }
        return url
    }

    private func encodedQuery(_ queryItems: [URLQueryItem]) -> String? {
        guard !queryItems.isEmpty else {
            return nil
        }
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return queryItems.map { item in
            let name = item.name.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
            guard let value = item.value else {
                return name
            }
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
            return "\(name)=\(encodedValue)"
        }.joined(separator: "&")
    }

    private func mapError(statusCode: Int, data: Data) -> PangolinAPIError {
        switch statusCode {
        case 401:
            return .unauthenticated
        case 403:
            return .forbidden
        case 404, 405:
            return .unsupported
        case 400, 409, 422:
            if let response = try? decoder.decode(PangolinResponse<PangolinEmptyResponse>.self, from: data) {
                return .serverRejected(status: statusCode, message: response.message)
            }
            return .serverRejected(status: statusCode, message: "")
        default:
            return .httpFailure(status: statusCode)
        }
    }
}

import Foundation
import Testing
@testable import Pango

@Suite("Pangolin identity provider service", .serialized)
struct PangolinIdentityProviderServiceTests {
    private func makeService() throws -> PangolinIdentityProviderService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinIdentityProviderService(
            client: PangolinAPIClient(
                configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
                session: URLSession(configuration: configuration)
            ),
            organizationId: "synthetic-org"
        )
    }

    @Test("lists organization identity providers")
    func listsIdentityProviders() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/idp")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.httpBody == nil && request.httpBodyStream == nil)
            return .init(statusCode: 200, data: Self.envelope(#"{"idps":[{"idpId":7,"orgId":"synthetic-org","name":"Work","type":"oidc","variant":"google","tags":null},{"idpId":8,"orgId":"synthetic-org","name":"Lab","type":"oidc","variant":"oidc","tags":"lab"}],"pagination":{"total":2,"limit":100,"offset":0}}"#))
        }

        let providers = try await makeService().listIdentityProviders()
        #expect(providers.map(\.idpId) == [7, 8])
        #expect(providers.map(\.name) == ["Work", "Lab"])
        #expect(providers.map(\.orgId) == ["synthetic-org", "synthetic-org"])
        #expect(providers.map(\.variant) == ["google", "oidc"])
        #expect(providers.map(\.tags) == [nil, "lab"])
    }

    @Test("preserves empty and null list results", arguments: ["null", #"{"idps":[]}"#])
    func listsEmptyIdentityProviders(data: String) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Self.envelope(data)) }
        let providers = try await makeService().listIdentityProviders()
        #expect(providers.isEmpty)
    }

    @Test("loads identity provider details and OIDC configuration")
    func getsIdentityProvider() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/idp/7")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.httpBody == nil && request.httpBodyStream == nil)
            return .init(statusCode: 200, data: Self.envelope(#"{"idp":{"idpId":7,"name":"Work","type":"oidc","autoProvision":true,"tags":null},"idpOidcConfig":{"clientId":"synthetic-client","clientSecret":"synthetic-secret","authUrl":"https://idp.example.com/auth","tokenUrl":"https://idp.example.com/token","identifierPath":"sub","emailPath":"email","namePath":"name","scopes":"openid email","variant":"google"},"redirectUrl":"https://api.example.com/auth/callback"}"#))
        }

        let detail = try #require(try await makeService().getIdentityProvider(idpId: 7))
        #expect(detail.idp.idpId == 7)
        #expect(detail.idp.name == "Work")
        #expect(detail.idp.autoProvision == true)
        #expect(detail.redirectUrl == "https://api.example.com/auth/callback")
        let config = try #require(detail.idpOidcConfig)
        #expect(config.clientId == "synthetic-client")
        #expect(config.clientSecret == "synthetic-secret")
        #expect(config.authUrl == "https://idp.example.com/auth")
        #expect(config.tokenUrl == "https://idp.example.com/token")
        #expect(config.identifierPath == "sub")
        #expect(config.emailPath == "email")
        #expect(config.namePath == "name")
        #expect(config.scopes == "openid email")
        #expect(config.variant == "google")
    }

    @Test("accepts missing optional OIDC configuration")
    func getsDetailWithoutConfiguration() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 200, data: Self.envelope(#"{"idp":{"idpId":7,"name":"Work","type":"oidc"},"idpOidcConfig":null,"redirectUrl":"https://api.example.com/auth/callback"}"#))
        }
        let detail = try #require(try await makeService().getIdentityProvider(idpId: 7))
        #expect(detail.idpOidcConfig == nil)
        #expect(detail.idp.autoProvision == nil)
    }

    @Test("preserves null detail results")
    func getsNullDetail() async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Self.envelope("null")) }
        let detail = try await makeService().getIdentityProvider(idpId: 7)
        #expect(detail == nil)
    }

    @Test("identity provider reads reject failed envelopes", arguments: [true, false], [
        #"{"data":null,"success":false,"error":false,"message":"rejected","status":400}"#,
        #"{"data":null,"success":true,"error":true,"message":"rejected","status":400}"#
    ])
    func rejectsFailedReads(list: Bool, envelope: String) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Data(envelope.utf8)) }
        await #expect(throws: PangolinAPIError.serverRejected(status: 400, message: "rejected")) {
            if list { _ = try await makeService().listIdentityProviders() }
            else { _ = try await makeService().getIdentityProvider(idpId: 7) }
        }
    }

    @Test("identity provider reads preserve authentication errors", arguments: [true, false], [401, 403])
    func preservesAuthenticationErrors(list: Bool, status: Int) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: status, data: Data()) }
        await #expect(throws: status == 401 ? PangolinAPIError.unauthenticated : .forbidden) {
            if list { _ = try await makeService().listIdentityProviders() }
            else { _ = try await makeService().getIdentityProvider(idpId: 7) }
        }
    }

    @Test("identity provider reads reject malformed data", arguments: [true, false])
    func rejectsMalformedReads(list: Bool) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Self.envelope("{}")) }
        await #expect(throws: PangolinAPIError.decoding) {
            if list { _ = try await makeService().listIdentityProviders() }
            else { _ = try await makeService().getIdentityProvider(idpId: 7) }
        }
    }

    @Test("creates and updates OIDC providers with only the intended fields", arguments: [true, false], [true, false])
    func writesOIDC(create: Bool, optionalPaths: Bool) async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == (create
                ? "https://api.example.com/v1/org/synthetic-org/idp/oidc"
                : "https://api.example.com/v1/org/synthetic-org/idp/7/oidc"))
            #expect(request.httpMethod == (create ? "PUT" : "POST"))
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: AnyHashable])
            var expected: [String: AnyHashable] = [
                "name": "Work", "clientId": "synthetic-client", "clientSecret": "synthetic-\"secret",
                "authUrl": "https://idp.example.com/auth", "tokenUrl": "https://idp.example.com/token",
                "scopes": "openid email", "identifierPath": "sub", "autoProvision": false
            ]
            if create { expected["variant"] = "google" }
            if optionalPaths {
                expected["emailPath"] = "email"
                expected["namePath"] = "name"
            }
            #expect(json == expected)
            return .init(statusCode: create ? 201 : 200, data: Self.envelope(optionalPaths ? #"{"idpId":7}"# : "null"))
        }
        let service = try makeService()
        let input = Self.input(optionalPaths: optionalPaths)
        if create { try await service.createOIDC(input: input, variant: "google") }
        else { try await service.updateOIDC(idpId: 7, input: input) }
    }

    @Test("deletes an identity provider without a body", arguments: ["null", "{}"])
    func deletesIdentityProvider(data: String) async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/idp/7")
            #expect(request.httpMethod == "DELETE")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.bodyData == nil)
            return .init(statusCode: 200, data: Self.envelope(data))
        }
        try await makeService().deleteIdentityProvider(idpId: 7)
    }

    @Test("identity provider writes reject failed envelopes", arguments: WriteAction.allCases, [
        #"{"data":null,"success":false,"error":false,"message":"rejected","status":400}"#,
        #"{"data":null,"success":true,"error":true,"message":"rejected","status":400}"#
    ])
    func rejectsFailedWrites(action: WriteAction, envelope: String) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Data(envelope.utf8)) }
        await #expect(throws: PangolinAPIError.serverRejected(status: 400, message: "rejected")) {
            try await write(action)
        }
    }

    @Test("identity provider writes preserve HTTP errors", arguments: WriteAction.allCases, [401, 403, 422])
    func preservesWriteHTTPErrors(action: WriteAction, status: Int) async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: status, data: Data(#"{"data":null,"success":false,"error":true,"message":"rejected","status":422}"#.utf8))
        }
        let expected: PangolinAPIError = status == 401 ? .unauthenticated
            : status == 403 ? .forbidden : .serverRejected(status: 422, message: "rejected")
        await #expect(throws: expected) { try await write(action) }
    }

    @Test("identity provider writes reject malformed responses", arguments: WriteAction.allCases)
    func rejectsMalformedWrites(action: WriteAction) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Data("invalid".utf8)) }
        await #expect(throws: PangolinAPIError.decoding) { try await write(action) }
    }

    enum WriteAction: CaseIterable, Sendable {
        case create, update, delete
    }

    private func write(_ action: WriteAction) async throws {
        let service = try makeService()
        switch action {
        case .create: try await service.createOIDC(input: Self.input(), variant: "oidc")
        case .update: try await service.updateOIDC(idpId: 7, input: Self.input())
        case .delete: try await service.deleteIdentityProvider(idpId: 7)
        }
    }

    private static func input(optionalPaths: Bool = false) -> OIDCIdentityProviderInput {
        OIDCIdentityProviderInput(
            name: "Work", clientId: "synthetic-client", clientSecret: "synthetic-\"secret",
            authUrl: "https://idp.example.com/auth", tokenUrl: "https://idp.example.com/token",
            scopes: "openid email", identifierPath: "sub", emailPath: optionalPaths ? "email" : "",
            namePath: optionalPaths ? "name" : "", autoProvision: false
        )
    }

    private static func envelope(_ data: String) -> Data {
        Data("{\"data\":\(data),\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }
}

private extension URLRequest {
    var bodyData: Data? {
        if let httpBody { return httpBody }
        guard let httpBodyStream else { return nil }
        httpBodyStream.open()
        defer { httpBodyStream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1_024)
        defer { buffer.deallocate() }
        while httpBodyStream.hasBytesAvailable {
            let count = httpBodyStream.read(buffer, maxLength: 1_024)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

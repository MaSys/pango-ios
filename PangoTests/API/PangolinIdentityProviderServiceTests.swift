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

    private static func envelope(_ data: String) -> Data {
        Data("{\"data\":\(data),\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }
}

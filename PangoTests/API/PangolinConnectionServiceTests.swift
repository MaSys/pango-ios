import Foundation
import Testing
@testable import Pango

@Suite("Pangolin connection validation", .serialized)
struct PangolinConnectionServiceTests {
    private func makeService() throws -> PangolinConnectionService {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolStub.self]
        let configuration = try PangolinAPIConfiguration(
            baseURLString: "https://api.example.com",
            apiKey: "synthetic-key"
        )
        return PangolinConnectionService(
            client: PangolinAPIClient(
                configuration: configuration,
                session: URLSession(configuration: sessionConfiguration)
            )
        )
    }

    @Test("validates health before loading organizations")
    func validatesHealthAndOrganizations() async throws {
        URLProtocolStub.handler = { request in
            switch request.url?.path {
            case "/v1":
                return .init(statusCode: 200, data: Data(#"{"message":"Healthy"}"#.utf8))
            case "/v1/orgs":
                return .init(
                    statusCode: 200,
                    data: Data(#"{"data":{"orgs":[{"orgId":"synthetic-org","name":"Synthetic"}]},"success":true,"error":false,"message":"","status":200}"#.utf8)
                )
            default:
                return .init(statusCode: 404, data: Data())
            }
        }

        let organizations = try await makeService().validate(organizationId: nil)

        #expect(organizations.count == 1)
        #expect(organizations.first?.orgId == "synthetic-org")
    }

    @Test("rejects an unhealthy API")
    func rejectsUnhealthyAPI() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 200, data: Data(#"{"message":"Starting"}"#.utf8))
        }

        await #expect(throws: PangolinAPIError.unsupported) {
            try await makeService().validate(organizationId: nil)
        }
    }

    @Test("preserves authentication failures")
    func preservesAuthenticationFailure() async throws {
        URLProtocolStub.handler = { request in
            if request.url?.path == "/v1" {
                return .init(statusCode: 200, data: Data(#"{"message":"Healthy"}"#.utf8))
            }
            return .init(statusCode: 401, data: Data())
        }

        await #expect(throws: PangolinAPIError.unauthenticated) {
            try await makeService().validate(organizationId: nil)
        }
    }

    @Test("asks for an organization when discovery is forbidden")
    func requiresOrganizationForScopedKey() async throws {
        URLProtocolStub.handler = { request in
            if request.url?.path == "/v1" {
                return .init(statusCode: 200, data: Data(#"{"message":"Healthy"}"#.utf8))
            }
            return .init(statusCode: 403, data: Data())
        }

        await #expect(throws: PangolinAPIError.organizationRequired) {
            try await makeService().validate(organizationId: nil)
        }
    }

    @Test("validates an organization-scoped key through its organization")
    func validatesOrganizationScopedKey() async throws {
        URLProtocolStub.handler = { request in
            switch request.url?.path {
            case "/v1":
                return .init(statusCode: 200, data: Data(#"{"message":"Healthy"}"#.utf8))
            case "/v1/org/synthetic-org/sites":
                return .init(
                    statusCode: 200,
                    data: Data(#"{"data":{"sites":[]},"success":true,"error":false,"message":"","status":200}"#.utf8)
                )
            default:
                return .init(statusCode: 403, data: Data())
            }
        }

        let organizations = try await makeService().validate(organizationId: "synthetic-org")

        #expect(organizations.first?.orgId == "synthetic-org")
    }
}

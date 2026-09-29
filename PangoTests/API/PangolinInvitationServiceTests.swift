import Foundation
import Testing
@testable import Pango

@Suite("Pangolin invitations", .serialized)
struct PangolinInvitationServiceTests {
    private func service() throws -> PangolinInvitationService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinInvitationService(client: PangolinAPIClient(
            configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
            session: URLSession(configuration: configuration)
        ), organizationId: "org-1")
    }

    @Test func listsEveryPageAndNullableRoleNames() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            #expect(url.path == "/v1/org/org-1/invitations")
            let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
            #expect(query.first { $0.name == "limit" }?.value == "1")
            let offset = try #require(query.first { $0.name == "offset" }?.value)
            return .init(statusCode: 200, data: Self.response("{\"invitations\":[{\"inviteId\":\"invite-\(offset)\",\"email\":\"test@example.com\",\"expiresAt\":1800000000000,\"roles\":[{\"roleId\":7,\"roleName\":null}]}],\"pagination\":{\"total\":2,\"limit\":1,\"offset\":\(offset)}}"))
        }
        let invitations = try await service().listAllInvitations(limit: 1)
        #expect(invitations.map(\.inviteId) == ["invite-0", "invite-1"])
        #expect(invitations.first?.roleNames == "")
    }

    @Test func createsPlusAddressAndReturnsLink() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/org/org-1/create-invite")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.invitationBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["email"] as? String == "person+test@example.com")
            #expect(json["roleId"] as? Int == 7)
            #expect(json["validHours"] as? Int == 24)
            return .init(statusCode: 200, data: Self.response(#"{"inviteLink":"https://example.com/invite?token=synthetic","expiresAt":1800000000000}"#))
        }
        let invitation = try await service().create(email: "person+test@example.com", validHours: 24, roleId: 7)
        #expect(invitation.inviteLink == "https://example.com/invite?token=synthetic")
    }

    @Test func stopsRepeatedPagination() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 200, data: Self.response(#"{"invitations":[],"pagination":{"total":3,"limit":1,"offset":0}}"#))
        }
        await #expect(throws: PangolinAPIError.decoding) {
            try await service().listAllInvitations(limit: 1)
        }
    }

    private static func response(_ data: String) -> Data {
        Data("{\"data\":\(data),\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }
}

private extension URLRequest {
    var invitationBodyData: Data? {
        if let httpBody { return httpBody }
        guard let httpBodyStream else { return nil }
        httpBodyStream.open()
        defer { httpBodyStream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while httpBodyStream.hasBytesAvailable {
            let count = httpBodyStream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(contentsOf: buffer.prefix(count))
        }
        return data
    }
}

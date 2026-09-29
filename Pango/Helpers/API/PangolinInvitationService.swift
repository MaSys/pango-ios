import Foundation

struct InvitationPagination: Decodable {
    let total: Int
    let limit: Int
    let offset: Int
}

struct InvitationsPage: Decodable {
    let invitations: [Invitation]
    let pagination: InvitationPagination
}

struct CreatedInvitation: Decodable {
    let inviteLink: String
    let expiresAt: Int
}

struct PangolinInvitationService: Sendable {
    private struct CreateBody: Encodable {
        let email: String
        let validHours: Int
        let roleId: Int
    }

    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listAllInvitations(limit: Int = 1_000) async throws -> [Invitation] {
        var invitations: [Invitation] = []
        var requestedOffset = 0
        while true {
            let response: PangolinResponse<InvitationsPage> = try await client.send(
                .get, path: "/org/\(organizationId)/invitations",
                queryItems: [URLQueryItem(name: "limit", value: String(limit)),
                    URLQueryItem(name: "offset", value: String(requestedOffset))]
            )
            let result = try response.requireInvitationData()
            invitations.append(contentsOf: result.invitations)
            guard result.pagination.limit > 0,
                  result.pagination.offset + result.pagination.limit < result.pagination.total else {
                return invitations
            }
            let nextOffset = result.pagination.offset + result.pagination.limit
            guard nextOffset > requestedOffset else { throw PangolinAPIError.decoding }
            requestedOffset = nextOffset
        }
    }

    func create(email: String, validHours: Int, roleId: Int) async throws -> CreatedInvitation {
        let response: PangolinResponse<CreatedInvitation> = try await client.send(
            .post, path: "/org/\(organizationId)/create-invite",
            body: CreateBody(email: email, validHours: validHours, roleId: roleId)
        )
        return try response.requireInvitationData()
    }
}

private extension PangolinResponse {
    func requireInvitationData() throws -> Value {
        guard success, !error else {
            throw PangolinAPIError.serverRejected(status: status, message: message)
        }
        guard let data else { throw PangolinAPIError.decoding }
        return data
    }
}

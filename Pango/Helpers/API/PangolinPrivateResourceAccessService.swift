struct PangolinPrivateResourceAccessService: Sendable {
    private struct AssignedUser: Decodable {
        let userId: String
        let email: String?
        let username: String?
    }
    private struct AssignedRole: Decodable {
        let roleId: Int
        let name: String?
        let isAdmin: Bool
    }
    private struct AssignedClient: Decodable {
        let clientId: Int
        let name: String?
        let subnet: String?
    }
    private struct Users: Decodable { let users: [AssignedUser] }
    private struct Roles: Decodable { let roles: [AssignedRole] }
    private struct Clients: Decodable { let clients: [AssignedClient] }

    let client: PangolinAPIClient

    func listAssignments(resourceId: Int, kind: PrivateResourceAccessKind) async throws -> [PrivateResourceAccessOption] {
        let path = "/private-resource/\(resourceId)/\(kind.rawValue)"
        switch kind {
        case .users:
            let response: PangolinResponse<Users> = try await client.send(.get, path: path)
            return try response.accessData().users.map {
                .init(id: $0.userId, name: $0.email ?? $0.username ?? $0.userId)
            }
        case .roles:
            let response: PangolinResponse<Roles> = try await client.send(.get, path: path)
            return try response.accessData().roles.map {
                .init(id: String($0.roleId), name: $0.name ?? String($0.roleId), isReadOnly: $0.isAdmin)
            }
        case .clients:
            let response: PangolinResponse<Clients> = try await client.send(.get, path: path)
            return try response.accessData().clients.map {
                .init(id: String($0.clientId), name: $0.name ?? $0.subnet ?? String($0.clientId))
            }
        }
    }

    func setAssignments(resourceId: Int, kind: PrivateResourceAccessKind, ids: Set<String>) async throws {
        let path = "/private-resource/\(resourceId)/\(kind.rawValue)"
        let response: PangolinResponse<PangolinEmptyResponse>
        switch kind {
        case .users:
            response = try await client.send(.post, path: path, body: ["userIds": ids.sorted()])
        case .roles, .clients:
            let numericIDs = try ids.map { id -> Int in
                guard let number = Int(id), number > 0 else { throw PangolinAPIError.decoding }
                return number
            }.sorted()
            response = try await client.send(.post, path: path, body: [kind == .roles ? "roleIds" : "clientIds": numericIDs])
        }
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

private extension PangolinResponse {
    func accessData() throws -> Value {
        guard success, !error else {
            throw PangolinAPIError.serverRejected(status: status, message: message)
        }
        guard let data else { throw PangolinAPIError.decoding }
        return data
    }
}

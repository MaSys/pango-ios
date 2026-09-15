import Foundation

struct PublicResourcePolicy: Decodable, Sendable {
    private struct Role: Decodable {
        let roleId: Int
    }

    private struct User: Decodable {
        let userId: String
    }

    let resourcePolicyId: Int
    let sso: Bool
    let passwordId: Int?
    let pincodeId: Int?
    let idpId: Int?
    private let roles: [Role]
    private let users: [User]

    var roleIds: [Int] { roles.map(\.roleId) }
    var userIds: [String] { users.map(\.userId) }
}

private struct PublicResourcePolicies: Decodable {
    let defaultPolicy: PublicResourcePolicy
}

private struct PasswordBody: Encodable {
    enum CodingKeys: String, CodingKey { case password }

    let password: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(password, forKey: .password)
    }
}

private struct PinCodeBody: Encodable {
    enum CodingKeys: String, CodingKey { case pincode }

    let pinCode: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pinCode, forKey: .pincode)
    }
}

private struct AccessControlBody: Encodable {
    let sso: Bool
    let userIds: [String]
    let roleIds: [Int]
    let skipToIdpId: Int?
}

struct PangolinPublicResourceAuthService: Sendable {
    private let client: PangolinAPIClient

    init(client: PangolinAPIClient) {
        self.client = client
    }

    func getDefaultPolicy(resourceId: Int) async throws -> PublicResourcePolicy {
        let response: PangolinResponse<PublicResourcePolicies> = try await client.send(
            .get,
            path: "/public-resource/\(resourceId)/policies"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        guard let policy = response.data?.defaultPolicy else {
            throw PangolinAPIError.decoding
        }
        return policy
    }

    func setPassword(policyId: Int, password: String?) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .post,
            path: "/public-resource-policy/\(policyId)/password",
            body: PasswordBody(password: password)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }

    func setPinCode(policyId: Int, pinCode: String?) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .post,
            path: "/public-resource-policy/\(policyId)/pincode",
            body: PinCodeBody(pinCode: pinCode)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }

    func setSSO(resourceId: Int, enabled: Bool) async throws {
        let policy = try await getDefaultPolicy(resourceId: resourceId)
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .post,
            path: "/public-resource-policy/\(policy.resourcePolicyId)/access-control",
            body: AccessControlBody(
                sso: enabled,
                userIds: policy.userIds,
                roleIds: policy.roleIds,
                skipToIdpId: policy.idpId
            )
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

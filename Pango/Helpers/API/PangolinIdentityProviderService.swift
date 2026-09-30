struct OIDCIdentityProviderInput: Sendable {
    let name: String
    let clientId: String
    let clientSecret: String
    let authUrl: String
    let tokenUrl: String
    let scopes: String
    let identifierPath: String
    let emailPath: String
    let namePath: String
    let autoProvision: Bool
}

struct PangolinIdentityProviderService: Sendable {
    private struct OIDCBody: Encodable {
        let name: String
        let clientId: String
        let clientSecret: String
        let authUrl: String
        let tokenUrl: String
        let scopes: String
        let identifierPath: String
        let emailPath: String?
        let namePath: String?
        let autoProvision: Bool
        let variant: String?

        init(input: OIDCIdentityProviderInput, variant: String? = nil) {
            name = input.name
            clientId = input.clientId
            clientSecret = input.clientSecret
            authUrl = input.authUrl
            tokenUrl = input.tokenUrl
            scopes = input.scopes
            identifierPath = input.identifierPath
            emailPath = input.emailPath.isEmpty ? nil : input.emailPath
            namePath = input.namePath.isEmpty ? nil : input.namePath
            autoProvision = input.autoProvision
            self.variant = variant
        }
    }

    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listIdentityProviders() async throws -> [IdentityProvider] {
        let response: PangolinResponse<IdentityProvidersResponse> = try await client.send(
            .get,
            path: "/org/\(organizationId)/idp"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        return response.data?.idps ?? []
    }

    func getIdentityProvider(idpId: Int) async throws -> IdentityProviderDetail? {
        let response: PangolinResponse<IdentityProviderDetail> = try await client.send(
            .get,
            path: "/org/\(organizationId)/idp/\(idpId)"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        return response.data
    }

    func createOIDC(input: OIDCIdentityProviderInput, variant: String) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .put,
            path: "/org/\(organizationId)/idp/oidc",
            body: OIDCBody(input: input, variant: variant)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }

    func updateOIDC(idpId: Int, input: OIDCIdentityProviderInput) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .post,
            path: "/org/\(organizationId)/idp/\(idpId)/oidc",
            body: OIDCBody(input: input)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }

    func deleteIdentityProvider(idpId: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .delete,
            path: "/org/\(organizationId)/idp/\(idpId)"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

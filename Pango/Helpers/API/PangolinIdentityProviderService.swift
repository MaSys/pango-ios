struct PangolinIdentityProviderService: Sendable {
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
}

struct PangolinConnectionService: Sendable {
    private let client: PangolinAPIClient

    init(client: PangolinAPIClient) {
        self.client = client
    }

    func validate(organizationId: String?) async throws -> [Organization] {
        let health: HealthCheckResponse = try await client.sendRaw(.get, path: "")
        guard health.message == "Healthy" else {
            throw PangolinAPIError.unsupported
        }

        let trimmedOrganizationId = organizationId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedOrganizationId.isEmpty {
            let response: PangolinResponse<SitesResponse> = try await client.send(
                .get,
                path: "/org/\(trimmedOrganizationId)/sites"
            )
            guard response.success, !response.error else {
                throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
            }
            return [Organization(orgId: trimmedOrganizationId, name: trimmedOrganizationId)]
        }

        let response: PangolinResponse<OrganizationsResponse>
        do {
            response = try await client.send(.get, path: "/orgs")
        } catch PangolinAPIError.forbidden {
            throw PangolinAPIError.organizationRequired
        }
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        guard let organizations = response.data?.orgs else {
            throw PangolinAPIError.decoding
        }
        return organizations
    }
}

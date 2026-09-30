struct PangolinHealthCheckService: Sendable {
    private struct CreateBody: Encodable {
        let name: String
        let type: String
        let url: String
        let interval: Int
    }

    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listHealthChecks() async throws -> [HealthCheck] {
        let response: PangolinResponse<HealthChecksResponse> = try await client.send(
            .get, path: "/org/\(organizationId)/health-checks"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        return response.data?.healthChecks ?? []
    }

    func createHealthCheck(name: String, type: String, url: String, interval: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .put,
            path: "/org/\(organizationId)/health-check",
            body: CreateBody(name: name, type: type, url: url, interval: interval)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }

    func deleteHealthCheck(healthCheckId: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .delete, path: "/org/\(organizationId)/health-check/\(healthCheckId)"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

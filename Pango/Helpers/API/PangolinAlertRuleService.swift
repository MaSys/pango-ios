struct PangolinAlertRuleService: Sendable {
    private struct CreateBody: Encodable {
        let name: String
        let triggerType: String
        let notificationMethod: String
        let notificationTarget: String
    }

    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listAlertRules() async throws -> [AlertRule] {
        let response: PangolinResponse<AlertRulesResponse> = try await client.send(
            .get, path: "/org/\(organizationId)/alerts"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        return response.data?.alerts ?? []
    }

    func createAlertRule(name: String, triggerType: String, notificationMethod: String, notificationTarget: String) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .put,
            path: "/org/\(organizationId)/alert",
            body: CreateBody(name: name, triggerType: triggerType, notificationMethod: notificationMethod, notificationTarget: notificationTarget)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }

    func deleteAlertRule(alertId: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .delete, path: "/org/\(organizationId)/alert/\(alertId)"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

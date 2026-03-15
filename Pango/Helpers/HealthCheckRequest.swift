//
//  HealthCheckRequest.swift
//  Pango
//

import Alamofire

class HealthCheckConfigRequest {

    static func fetch(resourceId: Int) async throws -> HealthCheckConfigResponse? {
        let config = try BaseRequest.config()
        let url = config.url("resource/\(resourceId)/health-check")
        return try await BaseRequest.get(
            MainResponse<HealthCheckConfigResponse>.self,
            url: url,
            headers: config.headers
        )
    }

    static func update(
        resourceId: Int,
        enabled: Bool,
        endpoint: String?,
        interval: Int?,
        timeout: Int?
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("resource/\(resourceId)/health-check")
        var params: [String: Any] = ["enabled": enabled]
        if let endpoint = endpoint { params["endpoint"] = endpoint }
        if let interval = interval { params["interval"] = interval }
        if let timeout = timeout { params["timeout"] = timeout }
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        return response.success
    }
}

class MaintenanceRequest {

    static func fetch(resourceId: Int) async throws -> MaintenanceResponse? {
        let config = try BaseRequest.config()
        let url = config.url("resource/\(resourceId)/maintenance")
        return try await BaseRequest.get(
            MainResponse<MaintenanceResponse>.self,
            url: url,
            headers: config.headers
        )
    }

    static func update(
        resourceId: Int,
        enabled: Bool,
        title: String?,
        message: String?
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("resource/\(resourceId)/maintenance")
        var params: [String: Any] = ["enabled": enabled]
        if let title = title { params["title"] = title }
        if let message = message { params["message"] = message }
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        return response.success
    }
}

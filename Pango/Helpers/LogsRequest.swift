//
//  LogsRequest.swift
//  Pango
//

import Alamofire

class LogsRequest {

    static func fetchAccessLogs(page: Int = 1, limit: Int = 50) async throws -> [AccessLog] {
        let config = try BaseRequest.config()
        let url = config.orgURL("access-logs?page=\(page)&limit=\(limit)")
        let data = try await BaseRequest.get(
            MainResponse<AccessLogsResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.logs ?? []
    }

    static func fetchActionLogs(page: Int = 1, limit: Int = 50) async throws -> [ActionLog] {
        let config = try BaseRequest.config()
        let url = config.orgURL("action-logs?page=\(page)&limit=\(limit)")
        let data = try await BaseRequest.get(
            MainResponse<ActionLogsResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.logs ?? []
    }

    static func fetchRequestLogs(page: Int = 1, limit: Int = 50) async throws -> [RequestLog] {
        let config = try BaseRequest.config()
        let url = config.orgURL("request-logs?page=\(page)&limit=\(limit)")
        let data = try await BaseRequest.get(
            MainResponse<RequestLogsResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.logs ?? []
    }
}

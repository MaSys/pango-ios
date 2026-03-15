//
//  LogsRequest.swift
//  Pango
//

import Alamofire

class LogsRequest {

    static func fetchRequestLogs(limit: Int = 100, offset: Int = 0) async throws -> [RequestAuditLog] {
        let config = try BaseRequest.config()
        let url = config.orgURL("logs/request?limit=\(limit)&offset=\(offset)")
        let data = try await BaseRequest.get(
            MainResponse<RequestAuditLogResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.log ?? []
    }
}

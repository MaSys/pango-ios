//
//  RulesRequest.swift
//  Pango
//

import Alamofire

class RulesRequest {

    static func fetch(resourceId: Int) async throws -> [Rule] {
        let config = try BaseRequest.config()
        let url = config.url("resource/\(resourceId)/rules")
        let data = try await BaseRequest.get(
            MainResponse<RulesResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.rules ?? []
    }

    static func create(
        resourceId: Int,
        action: String,
        match: String,
        value: String
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("resource/\(resourceId)/rule")
        let response = try await BaseRequest.put(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: [
                "action": action,
                "match": match,
                "value": value
            ],
            headers: config.headers
        )
        return response.success
    }

    static func update(
        ruleId: Int,
        action: String?,
        match: String?,
        value: String?,
        enabled: Bool?
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("rule/\(ruleId)")
        var params: [String: Any] = [:]
        if let action = action { params["action"] = action }
        if let match = match { params["match"] = match }
        if let value = value { params["value"] = value }
        if let enabled = enabled { params["enabled"] = enabled }
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        return response.success
    }

    static func delete(ruleId: Int) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("rule/\(ruleId)")
        let response = try await BaseRequest.delete(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }
}

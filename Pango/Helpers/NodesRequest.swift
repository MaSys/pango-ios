//
//  NodesRequest.swift
//  Pango
//

import Alamofire

class NodesRequest {

    static func fetch() async throws -> [Node] {
        let config = try BaseRequest.config()
        let url = config.orgURL("nodes")
        let data = try await BaseRequest.get(
            MainResponse<NodesResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.nodes ?? []
    }

    static func create(
        name: String,
        address: String,
        region: String?
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.orgURL("node")
        var params: [String: Any] = [
            "name": name,
            "address": address
        ]
        if let region = region { params["region"] = region }
        let response = try await BaseRequest.put(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        return response.success
    }

    static func delete(nodeId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("node/\(nodeId)")
        let response = try await BaseRequest.delete(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }
}

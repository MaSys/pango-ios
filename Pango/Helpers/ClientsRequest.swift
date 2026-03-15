//
//  ClientsRequest.swift
//  Pango
//

import Alamofire

class ClientsRequest {

    static func fetch() async throws -> [Client] {
        let config = try BaseRequest.config()
        let url = config.orgURL("clients")
        let data = try await BaseRequest.get(
            MainResponse<ClientsResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.clients ?? []
    }

    static func approve(clientId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("client/\(clientId)/approve")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }

    static func block(clientId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("client/\(clientId)/block")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }

    static func unblock(clientId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("client/\(clientId)/unblock")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }

    static func archive(clientId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("client/\(clientId)/archive")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }

    static func unarchive(clientId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("client/\(clientId)/unarchive")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }

    static func delete(clientId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("client/\(clientId)")
        let response = try await BaseRequest.delete(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }
}

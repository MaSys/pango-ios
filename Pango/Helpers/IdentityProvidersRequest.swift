//
//  IdentityProvidersRequest.swift
//  Pango
//

import Alamofire

class IdentityProvidersRequest {

    static func fetch() async throws -> [IdentityProvider] {
        let config = try BaseRequest.config()
        let url = config.url("idp")
        let data = try await BaseRequest.get(
            MainResponse<IdentityProvidersResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.idps ?? []
    }

    static func create(
        name: String,
        type: String,
        clientId: String,
        clientSecret: String,
        issuerUrl: String?,
        authUrl: String?,
        tokenUrl: String?,
        autoProvision: Bool
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("idp/oidc")
        var params: [String: Any] = [
            "name": name,
            "type": type,
            "clientId": clientId,
            "clientSecret": clientSecret,
            "autoProvision": autoProvision
        ]
        if let issuerUrl = issuerUrl { params["issuerUrl"] = issuerUrl }
        if let authUrl = authUrl { params["authUrl"] = authUrl }
        if let tokenUrl = tokenUrl { params["tokenUrl"] = tokenUrl }
        let response = try await BaseRequest.put(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        return response.success
    }

    static func update(
        idpId: Int,
        name: String?,
        enabled: Bool?,
        autoProvision: Bool?
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("idp/\(idpId)/oidc")
        var params: [String: Any] = [:]
        if let name = name { params["name"] = name }
        if let enabled = enabled { params["enabled"] = enabled }
        if let autoProvision = autoProvision { params["autoProvision"] = autoProvision }
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        return response.success
    }

    static func delete(idpId: Int) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("idp/\(idpId)")
        do {
            let response = try await BaseRequest.delete(
                MainResponse<EmptyResponse>.self,
                url: url,
                headers: config.headers
            )
            return response.success
        } catch {
            return false
        }
    }
}

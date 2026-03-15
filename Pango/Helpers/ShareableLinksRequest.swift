//
//  ShareableLinksRequest.swift
//  Pango
//

import Alamofire

class ShareableLinksRequest {

    static func fetch(resourceId: Int) async throws -> [ShareableLink] {
        let config = try BaseRequest.config()
        let url = config.url("resource/\(resourceId)/shareable-links")
        let data = try await BaseRequest.get(
            MainResponse<ShareableLinksResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.links ?? []
    }

    static func create(
        resourceId: Int,
        maxUses: Int?,
        expiresInHours: Int?
    ) async throws -> ShareableLink? {
        let config = try BaseRequest.config()
        let url = config.url("resource/\(resourceId)/shareable-link")
        var params: [String: Any] = [:]
        if let maxUses = maxUses { params["maxUses"] = maxUses }
        if let expiresInHours = expiresInHours { params["expiresInHours"] = expiresInHours }
        let response = await AF.request(
            url,
            method: .put,
            parameters: params,
            encoding: JSONEncoding.default,
            headers: config.headers
        )
        .serializingDecodable(MainResponse<ShareableLink>.self)
        .response
        guard let value = response.value, value.success else {
            throw APIError.requestFailed(response.value?.message ?? "Failed to create link")
        }
        return value.data
    }

    static func delete(linkId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("shareable-link/\(linkId)")
        let response = try await BaseRequest.delete(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }
}

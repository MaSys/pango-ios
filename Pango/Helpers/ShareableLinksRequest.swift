//
//  ShareableLinksRequest.swift
//  Pango
//

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
        let response = try await BaseRequest.put(
            MainResponse<ShareableLink>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        guard response.success else {
            throw APIError.requestFailed(response.message ?? "Request failed")
        }
        return response.data
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

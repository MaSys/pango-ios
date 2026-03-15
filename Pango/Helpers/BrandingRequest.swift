//
//  BrandingRequest.swift
//  Pango
//

import Foundation
import Alamofire

class BrandingRequest {

    static func fetch() async throws -> BrandingResponse? {
        let config = try BaseRequest.config()
        let url = config.orgURL("branding")
        return try await BaseRequest.get(
            MainResponse<BrandingResponse>.self,
            url: url,
            headers: config.headers
        )
    }

    static func update(
        primaryColor: String?,
        accentColor: String?,
        loginTitle: String?,
        loginMessage: String?,
        footerText: String?
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.orgURL("branding")
        var params: [String: Any] = [:]
        if let primaryColor = primaryColor { params["primaryColor"] = primaryColor }
        if let accentColor = accentColor { params["accentColor"] = accentColor }
        if let loginTitle = loginTitle { params["loginTitle"] = loginTitle }
        if let loginMessage = loginMessage { params["loginMessage"] = loginMessage }
        if let footerText = footerText { params["footerText"] = footerText }
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        return response.success
    }

    static func uploadLogo(imageData: Data) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.orgURL("branding/logo")
        return await withCheckedContinuation { continuation in
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "logo", fileName: "logo.png", mimeType: "image/png")
            }, to: url, headers: config.headers)
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                continuation.resume(returning: response.value?.success ?? false)
            }
        }
    }
}

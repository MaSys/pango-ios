//
//  SecuritySettingsRequest.swift
//  Pango
//

import Alamofire

class SecuritySettingsRequest {

    // MARK: - Security Settings

    static func fetchSecuritySettings() async throws -> SecuritySettingsResponse? {
        let config = try BaseRequest.config()
        let url = config.orgURL("security-settings")
        return try await BaseRequest.get(
            MainResponse<SecuritySettingsResponse>.self,
            url: url,
            headers: config.headers
        )
    }

    static func updateSecuritySettings(
        mfaRequired: Bool?,
        sessionLength: Int?,
        passwordRotationDays: Int?
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.orgURL("security-settings")
        var params: [String: Any] = [:]
        if let mfaRequired = mfaRequired { params["mfaRequired"] = mfaRequired }
        if let sessionLength = sessionLength { params["sessionLength"] = sessionLength }
        if let passwordRotationDays = passwordRotationDays { params["passwordRotationDays"] = passwordRotationDays }
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: params,
            headers: config.headers
        )
        return response.success
    }

    // MARK: - Geo-blocking

    static func fetchGeoBlocking() async throws -> GeoBlockingResponse? {
        let config = try BaseRequest.config()
        let url = config.orgURL("geo-blocking")
        return try await BaseRequest.get(
            MainResponse<GeoBlockingResponse>.self,
            url: url,
            headers: config.headers
        )
    }

    static func updateGeoBlocking(
        enabled: Bool,
        countries: [String],
        mode: String
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.orgURL("geo-blocking")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: [
                "enabled": enabled,
                "countries": countries,
                "mode": mode
            ],
            headers: config.headers
        )
        return response.success
    }

    // MARK: - ASN Blocking

    static func fetchASNBlocking() async throws -> ASNBlockingResponse? {
        let config = try BaseRequest.config()
        let url = config.orgURL("asn-blocking")
        return try await BaseRequest.get(
            MainResponse<ASNBlockingResponse>.self,
            url: url,
            headers: config.headers
        )
    }

    static func updateASNBlocking(
        enabled: Bool,
        asns: [String],
        mode: String
    ) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.orgURL("asn-blocking")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            parameters: [
                "enabled": enabled,
                "asns": asns,
                "mode": mode
            ],
            headers: config.headers
        )
        return response.success
    }
}

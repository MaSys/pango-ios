//
//  DeviceApprovalsRequest.swift
//  Pango
//

import Alamofire

class DeviceApprovalsRequest {

    static func fetchPending() async throws -> [DeviceApproval] {
        let config = try BaseRequest.config()
        let url = config.orgURL("device-approvals")
        let data = try await BaseRequest.get(
            MainResponse<DeviceApprovalsResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.approvals ?? []
    }

    static func approve(approvalId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("device-approval/\(approvalId)/approve")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }

    static func deny(approvalId: String) async throws -> Bool {
        let config = try BaseRequest.config()
        let url = config.url("device-approval/\(approvalId)/deny")
        let response = try await BaseRequest.post(
            MainResponse<EmptyResponse>.self,
            url: url,
            headers: config.headers
        )
        return response.success
    }
}

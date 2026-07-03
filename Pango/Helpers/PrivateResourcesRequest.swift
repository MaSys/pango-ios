//
//  PrivateResourcesRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI
import Alamofire

class PrivateResourcesRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ resources: [PrivateResource]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/site-resources")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .printError()
            .responseDecodable(of: MainResponse<PrivateResourcesResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(true, val.data?.siteResources ?? [])
                } else {
                    completionHandler(false, [])
                }
            }
    }

    public static func create(
        name: String,
        siteId: Int,
        mode: String,
        ssl: Bool,
        scheme: String?,
        destinationPort: Int?,
        destination: String,
        alias: String?,
        tcpPortRangeString: String?,
        udpPortRangeString: String?,
        disableIcmp: Bool?,
        domainId: String?,
        subdomain: String?,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, nil)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/site-resource")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        var params: [String: Any] = [
            "name": name,
            "siteId": siteId,
            "mode": mode,
            "ssl": ssl,
            "destination": destination,
            "enabled": true,
            "userIds": [],
            "roleIds": [],
            "clientIds": []
        ]
        if let scheme = scheme { params["scheme"] = scheme }
        if let destinationPort = destinationPort { params["destinationPort"] = destinationPort }
        if let alias = alias, !alias.isEmpty { params["alias"] = alias }
        if let tcpPortRangeString = tcpPortRangeString, !tcpPortRangeString.isEmpty { params["tcpPortRangeString"] = tcpPortRangeString }
        if let udpPortRangeString = udpPortRangeString, !udpPortRangeString.isEmpty { params["udpPortRangeString"] = udpPortRangeString }
        if let disableIcmp = disableIcmp { params["disableIcmp"] = disableIcmp }
        if let domainId = domainId, !domainId.isEmpty { params["domainId"] = domainId }
        if let subdomain = subdomain, !subdomain.isEmpty { params["subdomain"] = subdomain }

        AF.request(url, method: .put, parameters: params, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
                }
            }
    }

    public static func update(
        id: Int,
        name: String,
        siteIds: [Int],
        mode: String,
        ssl: Bool,
        scheme: String?,
        destinationPort: Int?,
        destination: String,
        alias: String?,
        tcpPortRangeString: String?,
        udpPortRangeString: String?,
        disableIcmp: Bool?,
        domainId: String?,
        subdomain: String?,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/site-resource/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        var params: [String: Any] = [
            "name": name,
            "siteIds": siteIds,
            "mode": mode,
            "ssl": ssl,
            "destination": destination,
            "userIds": [],
            "roleIds": [],
            "clientIds": []
        ]
        if let scheme = scheme { params["scheme"] = scheme }
        if let destinationPort = destinationPort { params["destinationPort"] = destinationPort }
        if let alias = alias, !alias.isEmpty { params["alias"] = alias }
        if let tcpPortRangeString = tcpPortRangeString, !tcpPortRangeString.isEmpty { params["tcpPortRangeString"] = tcpPortRangeString }
        if let udpPortRangeString = udpPortRangeString, !udpPortRangeString.isEmpty { params["udpPortRangeString"] = udpPortRangeString }
        if let disableIcmp = disableIcmp { params["disableIcmp"] = disableIcmp }
        if let domainId = domainId, !domainId.isEmpty { params["domainId"] = domainId }
        if let subdomain = subdomain, !subdomain.isEmpty { params["subdomain"] = subdomain }

        AF.request(url, method: .post, parameters: params, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
                }
            }
    }

    public static func delete(
        id: Int,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/site-resource/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .delete, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                completionHandler(response.value?.success == true)
            }
    }
}

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

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/resources?type=private")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<PrivateResourcesResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(true, val.data?.resources ?? [])
                } else {
                    completionHandler(false, [])
                }
            }
    }

    public static func create(
        name: String,
        siteId: Int,
        type: String,
        ip: String?,
        subnet: String?,
        alias: String?,
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

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/resource")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        var params: [String: Any] = [
            "name": name,
            "siteId": siteId,
            "type": type,
            "resourceType": "private"
        ]
        if let ip = ip, !ip.isEmpty { params["ip"] = ip }
        if let subnet = subnet, !subnet.isEmpty { params["subnet"] = subnet }
        if let alias = alias, !alias.isEmpty { params["alias"] = alias }

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
        icmp: Bool,
        ports: String,
        alias: String?,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/resource/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        var params: [String: Any] = [
            "name": name,
            "icmp": icmp,
            "ports": ports
        ]
        if let alias = alias { params["alias"] = alias }

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

        let url = URL(string: "\(baseUrl)/v1/resource/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .delete, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                completionHandler(response.value?.success == true)
            }
    }
}

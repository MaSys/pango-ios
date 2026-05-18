//
//  HealthChecksRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI
import Alamofire

class HealthChecksRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ healthChecks: [HealthCheck]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/health-checks")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<HealthChecksResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(true, val.data?.healthChecks ?? [])
                } else {
                    completionHandler(false, [])
                }
            }
    }

    public static func create(
        name: String,
        type: String,
        url targetUrl: String,
        interval: Int,
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

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/health-check")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        let params: [String: Any] = [
            "name": name,
            "type": type,
            "url": targetUrl,
            "interval": interval
        ]
        AF.request(url, method: .put, parameters: params, encoding: encoder, headers: ["Authorization": token])
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
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/health-check/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .delete, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                completionHandler(response.value?.success == true)
            }
    }
}

//
//  AlertRulesRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI
import Alamofire

class AlertRulesRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ alerts: [AlertRule]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/alerts")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<AlertRulesResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(true, val.data?.alerts ?? [])
                } else {
                    completionHandler(false, [])
                }
            }
    }

    public static func create(
        name: String,
        triggerType: String,
        notificationMethod: String,
        notificationTarget: String,
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

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/alert")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        let params: [String: Any] = [
            "name": name,
            "triggerType": triggerType,
            "notificationMethod": notificationMethod,
            "notificationTarget": notificationTarget
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

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/alert/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .delete, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                completionHandler(response.value?.success == true)
            }
    }
}

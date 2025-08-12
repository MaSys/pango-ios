//
//  TargetsRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 11/08/25.
//

import SwiftUI
import Alamofire

class TargetsRequest {
    public static func fetch(
        id: Int,
        completionHandler: @escaping (_ success: Bool, _ targets: [Target]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)/targets")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .get, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<TargetsResponse>.self) { response in
                if let val = response.value {
                    completionHandler(val.success, val.data!.targets)
                } else {
                    completionHandler(false, [])
                }
            }
    }
    
    public static func create(
        resourceId: Int,
        method: String,
        ip: String,
        port: String,
        enabled: Bool,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(resourceId)/target")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .put, parameters: [
            "method": method,
            "ip": ip,
            "port": Int(port),
            "enabled": enabled
        ], encoding: encoder, headers: ["Authorization": token])
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
        method: String,
        ip: String,
        port: String,
        enabled: Bool,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/target/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        let params: [String: Any] = [
            "method": method,
            "ip": ip,
            "port": Int(port)!,
            "enabled": enabled
        ]
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
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/target/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .delete, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
                }
            }
    }
}

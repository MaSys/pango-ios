//
//  ResourcesRequest.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 07/08/25.
//

import SwiftUI
import Alamofire

class ResourcesRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ resources: [Resource]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
                let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/org/\(org)/resources")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<ResourcesResponse>.self) { response in
                if let val = response.value {
                    if val.success {
                        completionHandler(true, val.data!.resources)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    completionHandler(false, [])
                }
            }
    }
    
    public static func toggleStatus(
        id: Int,
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
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .post, parameters: ["enabled": enabled], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                }
                completionHandler(false, nil)
            }
    }
    
    public static func updateName(
        id: Int,
        name: String,
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
        AF.request(url, method: .post, parameters: ["name": name], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                }
                completionHandler(false, nil)
            }
    }
    
    public static func setPassword(
        id: Int,
        password: String,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)/password")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .post, parameters: ["password": password.isEmpty ? nil : password], encoding: encoder, headers: ["Authorization": token])
            .printError()
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                }
                completionHandler(false, nil)
            }
    }
    
    public static func setPinCode(
        id: Int,
        pinCode: String,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)/pincode")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .post, parameters: ["pincode": pinCode.isEmpty ? nil : pinCode], encoding: encoder, headers: ["Authorization": token])
            .printError()
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                }
                completionHandler(false, nil)
            }
    }
}

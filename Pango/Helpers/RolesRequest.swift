//
//  RolesRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

import SwiftUI
import Alamofire

class RolesRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ targets: [Role]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/org/\(org)/roles")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .get, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<RolesResponse>.self) { response in
                if let val = response.value {
                    if let roles = val.data?.roles {
                        completionHandler(val.success, roles)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    completionHandler(false, [])
                }
            }
    }
    
    public static func create(
        name: String,
        description: String,
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
        
        let url = URL(string: "\(baseUrl)/v1/org/\(org)/role")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .put, parameters: ["name": name, "description": description], encoding: encoder, headers: ["Authorization": token])
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
        roleId: Int,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false)
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/role/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .delete, parameters: ["roleId": "\(roleId)"], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                print(response)
                if let val = response.value {
                    completionHandler(val.success)
                } else {
                    completionHandler(false)
                }
            }
    }
}

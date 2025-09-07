//
//  ResourcesRequest.swift
//  Pango
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
    
    public static func create(
        name: String,
        http: Bool,
        subdomain: String?,
        domainId: String?,
        protocolString: String,
        proxyPort: Int?,
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
        var params: [String: Any?] = [:]
        if http {
            params = [
                "name": name,
                "http": http,
                "protocol": "tcp",
                "subdomain": subdomain!,
                "domainId": domainId ?? nil
            ]
        } else {
            params = [
                "name": name,
                "http": http,
                "protocol": protocolString,
                "proxyPort": proxyPort!
            ]
        }
        
        AF.request(url, method: .put, parameters: params, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
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
                } else {
                    completionHandler(false, nil)
                }
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
                } else {
                    completionHandler(false, nil)
                }
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
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
                }
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
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
                }
            }
    }
    
    public static func toggleSSL(
        id: Int,
        ssl: Bool,
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
        AF.request(url, method: .post, parameters: ["ssl": ssl], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
                }
            }
    }
    
    public static func toggleSSO(
        id: Int,
        sso: Bool,
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
        AF.request(url, method: .post, parameters: ["sso": sso], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
                }
            }
    }
    
    public static func updateSubdomain(
        id: Int,
        domainId: String,
        subdomain: String,
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
        AF.request(url, method: .post, parameters: ["domainId": domainId, "subdomain": subdomain], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
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
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .delete, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                } else {
                    completionHandler(false, nil)
                }
            }
    }
    
    public static func users(
        id: Int,
        completionHandler: @escaping (_ success: Bool, _ users: [ResourceUser]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)/users")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<ResourceUsersResponse>.self) { response in
                if let val = response.value {
                    if val.success {
                        completionHandler(true, val.data!.users)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    print(response)
                    completionHandler(false, [])
                }
            }
    }
    
    public static func setUser(
        id: Int,
        userIds: [String],
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)/users")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .post, parameters: ["userIds": userIds], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                } else {
                    print(response)
                    completionHandler(false, response.value)
                }
            }
    }
    
    public static func roles(
        id: Int,
        completionHandler: @escaping (_ success: Bool, _ roles: [Role]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)/roles")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<RolesResponse>.self) { response in
                if let val = response.value {
                    if val.success {
                        completionHandler(true, val.data!.roles)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    print(response)
                    completionHandler(false, [])
                }
            }
    }
    
    public static func setRoles(
        id: Int,
        roleIds: [Int],
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key") else
        {
            completionHandler(false, nil)
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/resource/\(id)/roles")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .post, parameters: ["roleIds": roleIds], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(val.success, val)
                } else {
                    print(response)
                    completionHandler(false, response.value)
                }
            }
    }
}

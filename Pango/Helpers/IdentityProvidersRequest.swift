//
//  IdentityProvidersRequest.swift
//  Pango
//

import SwiftUI
import Alamofire

class IdentityProvidersRequest {

    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ idps: [IdentityProvider]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else {
            completionHandler(false, [])
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/idp")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<IdentityProvidersResponse>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(true, val.data?.idps ?? [])
                } else {
                    completionHandler(false, [])
                }
            }
    }

    public static func get(
        id: Int,
        completionHandler: @escaping (_ success: Bool, _ detail: IdentityProviderDetail?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else {
            completionHandler(false, nil)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/idp/\(id)")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<IdentityProviderDetail>.self) { response in
                if let val = response.value, val.success {
                    completionHandler(true, val.data)
                } else {
                    completionHandler(false, nil)
                }
            }
    }

    public static func create(
        name: String,
        clientId: String,
        clientSecret: String,
        authUrl: String,
        tokenUrl: String,
        scopes: String,
        identifierPath: String,
        emailPath: String,
        namePath: String,
        autoProvision: Bool,
        variant: String,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else {
            completionHandler(false, nil)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/idp/oidc")!
        let token = "Bearer \(apiKey)"
        var params: [String: Any] = [
            "name": name,
            "clientId": clientId,
            "clientSecret": clientSecret,
            "authUrl": authUrl,
            "tokenUrl": tokenUrl,
            "scopes": scopes,
            "identifierPath": identifierPath,
            "autoProvision": autoProvision,
            "variant": variant
        ]
        if !emailPath.isEmpty { params["emailPath"] = emailPath }
        if !namePath.isEmpty { params["namePath"] = namePath }

        AF.request(url, method: .put, parameters: params, encoding: JSONEncoding.default,
                   headers: ["Authorization": token])
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
        clientId: String,
        clientSecret: String,
        authUrl: String,
        tokenUrl: String,
        scopes: String,
        identifierPath: String,
        emailPath: String,
        namePath: String,
        autoProvision: Bool,
        completionHandler: @escaping (_ success: Bool, _ response: MainResponse<EmptyResponse>?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else {
            completionHandler(false, nil)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/idp/\(id)/oidc")!
        let token = "Bearer \(apiKey)"
        var params: [String: Any] = [
            "name": name,
            "clientId": clientId,
            "clientSecret": clientSecret,
            "authUrl": authUrl,
            "tokenUrl": tokenUrl,
            "scopes": scopes,
            "identifierPath": identifierPath,
            "autoProvision": autoProvision
        ]
        if !emailPath.isEmpty { params["emailPath"] = emailPath }
        if !namePath.isEmpty { params["namePath"] = namePath }

        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default,
                   headers: ["Authorization": token])
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
              let org = userDefaults.string(forKey: "pangolin_organization_id") else {
            completionHandler(false)
            return
        }

        let url = URL(string: "\(baseUrl)/v1/org/\(org)/idp/\(id)")!
        let token = "Bearer \(apiKey)"
        AF.request(url, method: .delete, encoding: JSONEncoding.default,
                   headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                completionHandler(response.value?.success == true)
            }
    }
}

//
//  Request.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI
import Alamofire

class Request {
    public static func healthCheck(
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let baseUrl = UserDefaults.standard.string(forKey: "pangolin_server_url")!
        let url = URL(string: "\(baseUrl)/v1")!
        AF.request(url)
            .responseDecodable(of: HealthCheckResponse.self) { response in
                if let res = response.value, res.message == "Healthy" {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            }
    }
    
    public static func fetchOrgs(
        completionHandler: @escaping (_ success: Bool, _ orgs: [Organization]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        let baseUrl = userDefaults.string(forKey: "pangolin_server_url")!
        let apiKey = userDefaults.string(forKey: "pangolin_api_key")!
        let url = URL(string: "\(baseUrl)/v1/orgs")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<OrganizationsResponse>.self) { response in
                if let val = response.value {
                    if val.success {
                        completionHandler(false, val.data!.orgs)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    completionHandler(false, [])
                }
            }
    }
    
    public static func fetchSites(
        completionHandler: @escaping (_ success: Bool, _ sites: [Site]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
                let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/org/\(org)/sites")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<SitesResponse>.self) { response in
                if let val = response.value {
                    if val.success {
                        completionHandler(true, val.data!.sites)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    completionHandler(false, [])
                }
            }
    }
    
    public static func fetchDomains(
        completionHandler: @escaping (_ success: Bool, _ sites: [Domain]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
                let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/org/\(org)/domains")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<DomainsResponse>.self) { response in
                if let val = response.value {
                    if val.success {
                        completionHandler(true, val.data!.domains)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    completionHandler(false, [])
                }
            }
    }
}

extension DataRequest {
    func printError() -> Self {
        responseString { response in
            debugPrint("Error:", response)
        }
    }
}

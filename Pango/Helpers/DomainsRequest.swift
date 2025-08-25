//
//  DomainsRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 25/08/25.
//

import SwiftUI
import Alamofire

class DomainsRequest {
    public static func fetch(
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

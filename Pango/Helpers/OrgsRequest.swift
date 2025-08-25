//
//  OrgsRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 25/08/25.
//

import SwiftUI
import Alamofire

class OrgsRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ orgs: [Organization]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let url = URL(string: "\(baseUrl)/v1/orgs") else {
            completionHandler(false, [])
            return
        }
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<OrganizationsResponse>.self) { response in
                if let val = response.value {
                    if val.success {
                        completionHandler(true, val.data!.orgs)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    completionHandler(false, [])
                }
            }
    }
}

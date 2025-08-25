//
//  UsersRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

import SwiftUI
import Alamofire

class UsersRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ targets: [User]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
              let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/org/\(org)/users")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .get, encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<UsersResponse>.self) { response in
                if let val = response.value {
                    completionHandler(val.success, val.data!.users)
                } else {
                    completionHandler(false, [])
                }
            }
    }
}

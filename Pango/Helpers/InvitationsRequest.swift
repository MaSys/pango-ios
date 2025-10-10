//
//  InvitationsRequest.swift
//  Pango
//
//  Created by Yaser Almasri on 05/10/25.
//

import SwiftUI
import Alamofire

class InvitationsRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ invitations: [Invitation]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "pangolin_server_url"),
              let apiKey = userDefaults.string(forKey: "pangolin_api_key"),
                let org = userDefaults.string(forKey: "pangolin_organization_id") else
        {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/v1/org/\(org)/invitations")!
        let token = "Bearer \(apiKey)"
        AF.request(url, headers: ["Authorization": token])
            .printError()
            .responseDecodable(of: MainResponse<InvitationsResponse>.self) { response in
                print(response)
                if let val = response.value {
                    if val.success {
                        completionHandler(true, val.data!.invitations)
                    } else {
                        completionHandler(false, [])
                    }
                } else {
                    completionHandler(false, [])
                }
            }
    }
    
    public static func create(
        email: String,
        validHours: Int,
        roleId: Int,
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
        
        let url = URL(string: "\(baseUrl)/v1/org/\(org)/create-invite")!
        let token = "Bearer \(apiKey)"
        let encoder = JSONEncoding.default
        AF.request(url, method: .post, parameters: ["email": email, "validHours": validHours, "roleId": roleId], encoding: encoder, headers: ["Authorization": token])
            .responseDecodable(of: MainResponse<EmptyResponse>.self) { response in
                if let val = response.value {
                    completionHandler(val.success)
                } else {
                    completionHandler(false)
                }
            }
    }
}

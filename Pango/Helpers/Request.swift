//
//  Request.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI
import Alamofire

class Request {
    public static func healthCheck(
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        guard let baseUrl = UserDefaults.standard.string(forKey: "pangolin_server_url") else {
            completionHandler(false)
            return
        }
        let url = URL(string: "\(baseUrl)/v1")!
        AF.request(url)
            .responseDecodable(of: HealthCheckResponse.self) { response in
                print(response)
                if let res = response.value {
                    completionHandler(res.message == "Healthy")
                } else {
                    completionHandler(false)
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

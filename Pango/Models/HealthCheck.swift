//
//  HealthCheck.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

struct HealthCheck: Decodable {
    var healthCheckId: Int
    var name: String
    var type: String
    var url: String?
    var host: String?
    var port: Int?
    var interval: Int
    var status: String?
}

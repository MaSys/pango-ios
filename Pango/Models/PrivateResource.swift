//
//  PrivateResource.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

struct PrivateResource: Decodable {
    var resourceId: Int
    var name: String
    var siteId: Int
    var type: String
    var ip: String?
    var subnet: String?
    var alias: String?
    var enabled: Bool
    var icmp: Bool?
    var ports: String?
}

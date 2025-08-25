//
//  Role.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

struct Role: Decodable {
    var roleId: Int
    var orgId: String?
    var isAdmin: Bool?
    var name: String
    var description: String?
    var orgName: String?
}

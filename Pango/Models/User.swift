//
//  User.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

struct User: Decodable {
    var id: String
    var email: String
    var emailVerified: Bool?
    var dateCreated: String?
    var orgId: String?
    var username: String?
    var name: String?
    var type: String
    var roleId: Int
    var roleName: String?
    var isOwner: Bool?
    var idpName: String?
    var idpId: Int?
    var twoFactorEnabled: Bool?
}

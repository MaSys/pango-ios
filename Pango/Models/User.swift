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
    var isOwner: Bool?
    var idpName: String?
    var idpId: Int?
    var twoFactorEnabled: Bool?
    
    var roles: [AssociationRole]
    var roleNames: String { roles.compactMap(\.roleName).joined(separator: ", ") }
}

struct ResourceUser: Decodable {
    var userId: String?
}

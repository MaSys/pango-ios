//
//  Node.swift
//  Pango
//

struct Node: Decodable {
    var nodeId: String
    var name: String?
    var address: String?
    var status: String?
    var region: String?
    var lastSeen: String?
    var version: String?
    var online: Bool?
    var dateCreated: String?
}

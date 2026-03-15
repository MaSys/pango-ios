//
//  Blueprint.swift
//  Pango
//

struct Blueprint: Decodable {
    var blueprintId: String
    var name: String?
    var yaml: String?
    var lastApplied: String?
    var status: String?
    var resourceCount: Int?
    var dateCreated: String?
}

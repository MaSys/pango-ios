//
//  Domain.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

struct Domain: Decodable {
    var domainId: String
    var baseDomain: String
    var verified: Bool?
    var type: String
    var failed: Bool?
    var tries: Int?
    var configManaged: Bool?
}

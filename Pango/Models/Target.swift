//
//  Target.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

struct Target: Decodable {
    var targetId: Int
    var method: String?
    var ip: String
    var port: Int
    var enabled: Bool
}

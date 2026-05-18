//
//  DnsRecord.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

struct DnsRecord: Decodable {
    var type: String
    var name: String
    var value: String
}

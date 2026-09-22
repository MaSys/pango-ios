//
//  DnsRecord.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

struct DnsRecord: Decodable {
    let id: Int?
    let domainId: String?
    let recordType: String
    let baseDomain: String?
    let value: String
    let verified: Bool?

    var type: String { recordType }
    var name: String { baseDomain ?? "" }
}

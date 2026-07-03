//
//  PrivateResource.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

struct PrivateResource: Decodable {
    enum CodingKeys: String, CodingKey {
        case siteResourceId
        case orgId
        case niceId
        case name
        case mode
        case ssl
        case scheme
        case proxyPort
        case destinationPort
        case destination
        case enabled
        case alias
        case aliasAddress
        case tcpPortRangeString
        case udpPortRangeString
        case disableIcmp
        case authDaemonMode
        case authDaemonPort
        case subdomain
        case domainId
        case fullDomain
        case networkId
        case defaultNetworkId
        case siteNames
        case siteNiceIds
        case siteIds
        case siteAddresses
        case siteOnlines
    }
    
    var siteResourceId: Int
    var orgId: String
    var niceId: String
    var name: String
    var mode: String
    var ssl: Bool
    var scheme: String?
    var proxyPort: Int?
    var destinationPort: Int?
    var destination: String
    var enabled: Bool
    var alias: String?
    var aliasAddress: String?
    var tcpPortRangeString: String
    var udpPortRangeString: String
    var disableIcmp: Bool
    var authDaemonMode: String
    var authDaemonPort: Int
    var subdomain: String?
    var domainId: String?
    var fullDomain: String?
    var networkId: Int
    var defaultNetworkId: Int?
    var siteNames: [String]
    var siteNiceIds: [String]
    var siteIds: [Int]
    var siteAddresses: [String]
    var siteOnlines: [Bool]
}

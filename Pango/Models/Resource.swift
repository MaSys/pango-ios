//
//  Resource.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

struct Resource: Decodable {
    enum CodingKeys: String, CodingKey {
        case resourceId
        case name
        case ssl
        case fullDomain
        case passwordId
        case sso
        case pincodeId
        case whitelist
        case http
        case protocolString = "protocol"
        case proxyPort
        case enabled
        case domainId
        case isPrivate
        case host
        case cidr
        case ports
        case securityKeyId
        case shareableLinkCount
    }

    var resourceId: Int
    var name: String
    var ssl: Bool
    var fullDomain: String?
    var passwordId: Int?
    var sso: Bool
    var pincodeId: Int?
    var whitelist: Bool
    var http: Bool
    var protocolString: String
    var proxyPort: Int?
    var enabled: Bool
    var domainId: String?
    var isPrivate: Bool?
    var host: String?
    var cidr: String?
    var ports: String?
    var securityKeyId: Int?
    var shareableLinkCount: Int?

    var protected: Bool {
        if passwordId != nil { return true }
        if pincodeId != nil { return true }
        if securityKeyId != nil { return true }
        if shareableLinkCount ?? 0 > 0 { return true }

        return sso
    }

    var resourceType: ResourceType {
        if isPrivate == true { return .privateResource }
        if http { return .http }
        return .rawTcpUdp
    }
}

enum ResourceType: String, CaseIterable {
    case http
    case rawTcpUdp
    case privateResource

    var displayName: String {
        switch self {
        case .http: return "HTTPS"
        case .rawTcpUdp: return "TCP/UDP"
        case .privateResource: return "Private"
        }
    }
}

extension Resource {
    public static func fake() -> Resource {
        return Resource(
            resourceId: 1,
            name: "Resource Name",
            ssl: true,
            fullDomain: "resou.example.com",
            passwordId: nil,
            sso: false,
            pincodeId: nil,
            whitelist: false,
            http: true,
            protocolString: "tcp",
            enabled: true
        )
    }
}

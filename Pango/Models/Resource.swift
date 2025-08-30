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
    
    var protected: Bool {
        if passwordId != nil { return true }
        if pincodeId != nil { return true }
        
        return sso
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

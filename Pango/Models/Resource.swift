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
        case uptimePercent
        case certStatus
        case wildcard
        case mode
        case headerAuthId
        case health
    }
    
    var resourceId: Int
    var name: String
    var ssl: Bool
    var fullDomain: String?
    var passwordId: Int?
    var sso: Int
    var pincodeId: Int?
    var whitelist: Int
    var http: Bool
    var protocolString: String
    var proxyPort: Int?
    var enabled: Bool
    var domainId: String?
    var uptimePercent: Float?
    var certStatus: String?
    var wildcard: Bool
    var mode: String
    var headerAuthId: Int?
    var health: String
    
    var protected: Bool {
        if passwordId != nil { return true }
        if pincodeId != nil { return true }
        
        return sso == 1
    }
}

extension Resource {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        resourceId = try container.decode(Int.self, forKey: .resourceId)
        name = try container.decode(String.self, forKey: .name)
        ssl = try container.decode(Bool.self, forKey: .ssl)
        fullDomain = try container.decodeIfPresent(String.self, forKey: .fullDomain)
        passwordId = try container.decodeIfPresent(Int.self, forKey: .passwordId)
        sso = try container.decodeIntOrBoolIfPresent(forKey: .sso) ?? 0
        pincodeId = try container.decodeIfPresent(Int.self, forKey: .pincodeId)
        whitelist = try container.decodeIntOrBoolIfPresent(forKey: .whitelist) ?? 0
        proxyPort = try container.decodeIfPresent(Int.self, forKey: .proxyPort)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        domainId = try container.decodeIfPresent(String.self, forKey: .domainId)
        uptimePercent = try container.decodeIfPresent(Float.self, forKey: .uptimePercent)
        certStatus = try container.decodeIfPresent(String.self, forKey: .certStatus)
        wildcard = try container.decodeIfPresent(Bool.self, forKey: .wildcard) ?? false
        mode = try container.decodeIfPresent(String.self, forKey: .mode) ?? "http"
        headerAuthId = try container.decodeIfPresent(Int.self, forKey: .headerAuthId)
        health = try container.decodeIfPresent(String.self, forKey: .health) ?? "unknown"
        http = try container.decodeIfPresent(Bool.self, forKey: .http) ?? (mode == "http")
        protocolString = try container.decodeIfPresent(String.self, forKey: .protocolString) ?? (http ? "tcp" : mode)
    }
}

private extension KeyedDecodingContainer where Key == Resource.CodingKeys {
    func decodeIntOrBoolIfPresent(forKey key: Key) throws -> Int? {
        if let value = try decodeIfPresent(Int.self, forKey: key) {
            return value
        }

        if let value = try decodeIfPresent(Bool.self, forKey: key) {
            return value ? 1 : 0
        }

        return nil
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
            sso: 0,
            pincodeId: nil,
            whitelist: 0,
            http: true,
            protocolString: "tcp",
            enabled: true,
            wildcard: false,
            mode: "http",
            health: "unknown"
        )
    }
}

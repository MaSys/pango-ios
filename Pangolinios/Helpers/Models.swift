//
//  Models.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 04/08/25.
//

// Responses -----------------------------------

struct MainResponse<T: Decodable>: Decodable {
    var data: T?
    var success: Bool
    var error: Bool
    var message: String
    var status: Int
}

struct HealthCheckResponse: Decodable {
    var message: String
}

struct OrganizationsResponse: Decodable {
    var orgs: [Organization]
}

struct SitesResponse: Decodable {
    var sites: [Site]
}

struct ResourcesResponse: Decodable {
    var resources: [Resource]
}

struct DomainsResponse: Decodable {
    var domains: [Domain]
}

struct TargetsResponse: Decodable {
    var targets: [Target]
}

struct EmptyResponse: Decodable {
}

// Models --------------------------------------

struct Organization: Decodable {
    var orgId: String
    var name: String
}

struct Site: Decodable {
    var siteId: Int
    var niceId: String
    var name: String
    var pubKey: String
    var subnet: String
    var megabytesIn: Float
    var megabytesOut: Float
    var orgName: String
    var type: String
    var online: Bool
    var address: String
    var newtVersion: String
    var newtUpdateAvailable: Bool
}

struct Resource: Decodable {
    enum CodingKeys: String, CodingKey {
        case resourceId
        case name
        case ssl
        case fullDomain
        case siteName
        case siteId
        case passwordId
        case sso
        case pincodeId
    //    case whitelist
    //    case http
        case protocolString = "protocol"
    //    case proxyPort
        case enabled
    //    case domainId
    }
    
    var resourceId: Int
    var name: String
    var ssl: Bool
    var fullDomain: String
    var siteName: String?
    var siteId: String
    var passwordId: Int?
    var sso: Bool
    var pincodeId: Int?
//    var whitelist: Bool
//    var http: Bool
    var protocolString: String
//    var proxyPort: Int?
    var enabled: Bool
//    var domainId: String
    
    var protected: Bool {
        if passwordId != nil { return true }
        if pincodeId != nil { return true }
        
        return sso
    }
}

struct Domain: Decodable {
    var domainId: String
    var baseDomain: String
    var verified: Bool
    var type: String
    var failed: Bool
    var tries: Int
    var configManaged: Bool
}

struct Target: Decodable {
    var targetId: Int
    var method: String
    var ip: String
    var port: Int
    var enabled: Bool
}

extension Site {
    public static func fake() -> Site {
        return Site(
            siteId: 1,
            niceId: "site_id",
            name: "Site Name",
            pubKey: "pubkey",
            subnet: "subnet",
            megabytesIn: 15.12145465465,
            megabytesOut: 25.45646876989,
            orgName: "OrgName",
            type: "newt",
            online: true,
            address: "",
            newtVersion: "1.4.0",
            newtUpdateAvailable: false
        )
    }
}

extension Resource {
    public static func fake() -> Resource {
        return Resource(
            resourceId: 1,
            name: "Resource Name",
            ssl: true,
            fullDomain: "resou.example.com",
            siteName: "SITE NAME",
            siteId: "site-id",
            passwordId: nil,
            sso: false,
            pincodeId: nil,
            protocolString: "tcp",
            enabled: true
        )
    }
}

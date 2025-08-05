//
//  Models.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 04/08/25.
//

// Responses -----------------------------------

struct HealthCheckResponse: Decodable {
    var message: String
}

struct OrganizationsResponse: Decodable {
    var data: OrganizationsDataResponse
}

struct OrganizationsDataResponse: Decodable {
    var orgs: [Organization]
}

struct SitesResponse: Decodable {
    var data: SitesDataResponse
}

struct SitesDataResponse: Decodable {
    var sites: [Site]
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
    var resourceId: Int
    var name: String
    var ssl: Bool
    var fullDomain: String
    var siteName: String
    var siteId: String
    var passwordId: String?
    var sso: Bool
    var pincodeId: Int
    var whitelist: Bool
    var http: Bool
    //var protocol: String
    var proxyPort: Int?
    var enabled: Bool
    var domainId: String
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

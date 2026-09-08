//
//  Site.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

struct Site: Decodable, Equatable {
    var siteId: Int
    var niceId: String?
    var name: String
    var pubKey: String?
    var subnet: String?
    var megabytesIn: Float?
    var megabytesOut: Float?
    var orgName: String?
    var type: String
    var online: Bool?
    var address: String?
    var newtVersion: String?
    var newtUpdateAvailable: Bool?
    var uptimePercent: Float?
    var pending: Bool?
    var exitNodeId: Int?
    var exitNodeName: String?
    var exitNodeEndpoint: String?
    var remoteExitNodeId: Int?
    var resourceCount: Int?
    var status: String?
    var newtId: String?
    var secret: String?
}

extension Site {
    public static func fake() -> Site {
        return Site(
            siteId: 1,
            niceId: "site_id",
            name: "Site Name",
            pubKey: "pubkey",
            subnet: "subnet",
            megabytesIn: 800.12145465465,
            megabytesOut: 18000.45646876989,
            orgName: "OrgName",
            type: "newt",
            online: true,
            address: "",
            newtVersion: "1.4.0",
            newtUpdateAvailable: false,
            uptimePercent: nil,
            pending: false,
            exitNodeId: nil,
            exitNodeName: nil,
            exitNodeEndpoint: nil,
            remoteExitNodeId: nil,
            resourceCount: 0,
            status: "approved",
            newtId: nil,
            secret: nil
        )
    }
}

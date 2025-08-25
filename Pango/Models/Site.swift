//
//  Site.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

struct Site: Decodable {
    var siteId: Int
    var niceId: String?
    var name: String
    var pubKey: String?
    var subnet: String?
    var megabytesIn: Float?
    var megabytesOut: Float?
    var orgName: String?
    var type: String
    var online: Bool
    var address: String?
    var newtVersion: String?
    var newtUpdateAvailable: Bool?
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
            newtUpdateAvailable: false
        )
    }
}

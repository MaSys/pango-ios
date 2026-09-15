//
//  Target.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

struct Target: Decodable {
    var targetId: Int
    var method: String?
    var ip: String
    var port: Int
    var enabled: Bool
    var siteType: String?
    var siteId: Int
    var healthCheck: Bool?
    var healthStatus: String?
    var healthCheckHostname: String?
    var path: String?
    var pathMatchType: String?
    var pathRewriting: String?
    var rewritePathType: String?

    private enum CodingKeys: String, CodingKey {
        case targetId, method, ip, port, enabled, siteType, siteId
        case healthCheck, healthStatus, path, pathMatchType, pathRewriting, rewritePathType
        case hcEnabled, hcHealth, hcHostname, rewritePath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        targetId = try container.decode(Int.self, forKey: .targetId)
        method = try container.decodeIfPresent(String.self, forKey: .method)
        ip = try container.decode(String.self, forKey: .ip)
        port = try container.decode(Int.self, forKey: .port)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        siteType = try container.decodeIfPresent(String.self, forKey: .siteType)
        siteId = try container.decode(Int.self, forKey: .siteId)
        healthCheck = try container.decodeIfPresent(Bool.self, forKey: .hcEnabled)
            ?? container.decodeIfPresent(Bool.self, forKey: .healthCheck)
        healthStatus = try container.decodeIfPresent(String.self, forKey: .hcHealth)
            ?? container.decodeIfPresent(String.self, forKey: .healthStatus)
        healthCheckHostname = try container.decodeIfPresent(String.self, forKey: .hcHostname)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        pathMatchType = try container.decodeIfPresent(String.self, forKey: .pathMatchType)
        pathRewriting = try container.decodeIfPresent(String.self, forKey: .rewritePath)
            ?? container.decodeIfPresent(String.self, forKey: .pathRewriting)
        rewritePathType = try container.decodeIfPresent(String.self, forKey: .rewritePathType)
    }
}

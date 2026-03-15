//
//  BlueprintsRequest.swift
//  Pango
//

import Alamofire

class BlueprintsRequest {

    static func fetch() async throws -> [Blueprint] {
        let config = try BaseRequest.config()
        let url = config.orgURL("blueprints")
        let data = try await BaseRequest.get(
            MainResponse<BlueprintsResponse>.self,
            url: url,
            headers: config.headers
        )
        return data?.blueprints ?? []
    }
}

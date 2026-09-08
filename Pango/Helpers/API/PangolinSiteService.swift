import Foundation

struct SitesPage: Decodable, Equatable {
    let sites: [Site]
    let pagination: Pagination
}

struct SiteCredentials: Equatable {
    let id: String
    let secret: String
}

struct CreatedSite: Equatable {
    let site: Site
    let credentials: SiteCredentials
}

struct PangolinSiteService: Sendable {
    private struct CreateSiteBody: Encodable {
        let name: String
        let type = "newt"
    }

    private struct RenameSiteBody: Encodable {
        let name: String
    }

    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listSites(page: Int = 1, pageSize: Int = 100) async throws -> SitesPage {
        let response: PangolinResponse<SitesPage> = try await client.send(
            .get,
            path: "/org/\(organizationId)/sites",
            queryItems: [
                URLQueryItem(name: "pageSize", value: String(pageSize)),
                URLQueryItem(name: "page", value: String(page))
            ]
        )
        return try response.requireData()
    }

    func createNewtSite(name: String) async throws -> CreatedSite {
        let response: PangolinResponse<Site> = try await client.send(
            .put,
            path: "/org/\(organizationId)/site",
            body: CreateSiteBody(name: name)
        )
        let site = try response.requireData()
        guard let id = site.newtId, let secret = site.secret else {
            throw PangolinAPIError.decoding
        }
        return CreatedSite(site: site, credentials: SiteCredentials(id: id, secret: secret))
    }

    func getSite(siteId: Int) async throws -> Site {
        let response: PangolinResponse<Site> = try await client.send(
            .get,
            path: "/site/\(siteId)"
        )
        return try response.requireData()
    }

    func renameSite(siteId: Int, name: String) async throws -> Site {
        let response: PangolinResponse<Site> = try await client.send(
            .post,
            path: "/site/\(siteId)",
            body: RenameSiteBody(name: name)
        )
        return try response.requireData()
    }

    func deleteSite(siteId: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .delete,
            path: "/site/\(siteId)",
            queryItems: [URLQueryItem(name: "deleteResources", value: "false")]
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

private extension PangolinResponse {
    func requireData() throws -> Value {
        guard success, !error else {
            throw PangolinAPIError.serverRejected(status: status, message: message)
        }
        guard let data else {
            throw PangolinAPIError.decoding
        }
        return data
    }
}

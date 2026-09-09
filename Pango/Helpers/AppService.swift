//
//  AppService.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

class AppService: ObservableObject {
    
    public static var shared = AppService()
    
    @AppStorage("pangolin_server_url") var pangolinServerUrl: String = ""
    @AppStorage("pangolin_api_key") var pangolinApiKey: String = ""
    @AppStorage("pangolin_organization_id") var pangolinOrganizationId: String = ""
    
    @Published var organizations: [Organization] = []
    @Published var sites: [Site] = []
    @Published var resources: [Resource] = []
    @Published var domains: [Domain] = []
    @Published var roles: [Role] = []
    @Published var users: [User] = []
    
    public func fetchOrgs(completionHandler: @escaping (_ success: Bool, _ orgs: [Organization]) -> Void) {
        OrgsRequest.fetch { success, orgs in
            self.organizations = orgs
            if let org = orgs.first {
                self.pangolinOrganizationId = org.orgId
            }
            completionHandler(success, orgs)
        }
    }
    
    public func fetchSites(completionHandler: @escaping (_ success: Bool, _ sites: [Site]) -> Void) {
        Task {
            do {
                let sites = try await fetchSites()
                completionHandler(true, sites)
            } catch {
                completionHandler(false, [])
            }
        }
    }

    public func fetchSites() async throws -> [Site] {
        let page = try await siteService().listSites()
        sites = page.sites
        return page.sites
    }

    public func createNewtSite(name: String) async throws -> CreatedSite {
        try await createSite(name: name, type: .newt)
    }

    public func createSite(name: String, type: SiteType) async throws -> CreatedSite {
        let created = try await siteService().createSite(name: name, type: type)
        var site = created.site
        site.secret = nil
        sites.append(site)
        return created
    }

    public func getSite(siteId: Int) async throws -> Site {
        try await siteService().getSite(siteId: siteId)
    }

    public func renameSite(siteId: Int, name: String) async throws -> Site {
        let site = try await siteService().renameSite(siteId: siteId, name: name)
        if let index = sites.firstIndex(where: { $0.siteId == siteId }) {
            sites[index] = site
        }
        return site
    }

    public func deleteSite(siteId: Int) async throws {
        try await siteService().deleteSite(siteId: siteId)
        sites.removeAll { $0.siteId == siteId }
    }

    private func siteService() throws -> PangolinSiteService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(
                baseURLString: pangolinServerUrl,
                apiKey: pangolinApiKey
            )
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinSiteService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: pangolinOrganizationId
        )
    }
    
    public func fetchResources() {
        ResourcesRequest.fetch { success, resources in
            self.resources = resources
        }
    }
    
    public func fetchDomains() {
        DomainsRequest.fetch { success, domains in
            self.domains = domains
        }
    }
    
    public func fetchRoles() {
        RolesRequest.fetch { success, roles in
            self.roles = roles
        }
    }
    
    public func fetchUsers() {
        UsersRequest.fetch { success, users in
            self.users = users
        }
    }
}

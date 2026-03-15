//
//  AppService.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

@MainActor
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
    @Published var clients: [Client] = []

    // MARK: - Legacy callback methods (existing views)

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
        SitesRequest.fetch { success, sites in
            self.sites = sites
            completionHandler(success, sites)
        }
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

    // MARK: - Async methods (new features)

    public func fetchClientsAsync() async {
        do {
            clients = try await ClientsRequest.fetch()
        } catch {}
    }

    public func fetchSitesAsync() async {
        await withCheckedContinuation { continuation in
            SitesRequest.fetch { _, sites in
                Task { @MainActor in
                    self.sites = sites
                    continuation.resume()
                }
            }
        }
    }

    public func fetchResourcesAsync() async {
        await withCheckedContinuation { continuation in
            ResourcesRequest.fetch { _, resources in
                Task { @MainActor in
                    self.resources = resources
                    continuation.resume()
                }
            }
        }
    }

    public func fetchDomainsAsync() async {
        await withCheckedContinuation { continuation in
            DomainsRequest.fetch { _, domains in
                Task { @MainActor in
                    self.domains = domains
                    continuation.resume()
                }
            }
        }
    }
}

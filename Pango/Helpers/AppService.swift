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
    @Published var pangolinOrganizationId = UserDefaults.standard.string(forKey: "pangolin_organization_id") ?? "" {
        didSet {
            guard oldValue != pangolinOrganizationId else { return }
            UserDefaults.standard.set(pangolinOrganizationId, forKey: "pangolin_organization_id")
            organizationRevision = UUID()
            sites = []
            resources = []
            domains = []
            roles = []
            users = []
            guard !pangolinOrganizationId.isEmpty else { return }
            fetchSites { _, _ in }
            fetchResources()
            fetchDomains()
        }
    }

    // Distinguishes requests even when switching A → B → A.
    private(set) var organizationRevision = UUID()
    
    @Published var organizations: [Organization] = []
    @Published var sites: [Site] = []
    @Published var resources: [Resource] = []
    @Published var domains: [Domain] = []
    @Published var roles: [Role] = []
    @Published var users: [User] = []
    
    public func fetchOrgs(completionHandler: @escaping (_ success: Bool, _ orgs: [Organization]) -> Void) {
        Task {
            do {
                let orgs = try await listOrganizations()
                organizations = orgs
                if !orgs.contains(where: { $0.orgId == pangolinOrganizationId }), let first = orgs.first {
                    pangolinOrganizationId = first.orgId
                }
                completionHandler(true, orgs)
            } catch {
                organizations = []
                completionHandler(false, [])
            }
        }
    }

    public func listOrganizations() async throws -> [Organization] {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: pangolinServerUrl, apiKey: pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        return try await PangolinConnectionService(client: PangolinAPIClient(configuration: configuration)).listOrganizations()
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
        let revision = organizationRevision
        let page = try await siteService().listSites()
        guard revision == organizationRevision else { throw CancellationError() }
        sites = page.sites
        return page.sites
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
        let revision = organizationRevision
        Task {
            do {
                _ = try await fetchResources()
            } catch {
                guard revision == organizationRevision else { return }
                resources = []
            }
        }
    }

    public func fetchResources() async throws -> [Resource] {
        let revision = organizationRevision
        let fetchedResources = try await publicResourceService().listAllResources()
        guard revision == organizationRevision else { throw CancellationError() }
        resources = fetchedResources
        return fetchedResources
    }

    private func publicResourceService() throws -> PangolinPublicResourceService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: pangolinServerUrl, apiKey: pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw PangolinAPIError.organizationRequired }
        return PangolinPublicResourceService(client: PangolinAPIClient(configuration: configuration), organizationId: pangolinOrganizationId)
    }

    public func fetchDomains() {
        let revision = organizationRevision
        Task {
            do {
                _ = try await fetchDomains()
            } catch {
                guard revision == organizationRevision else { return }
                domains = []
            }
        }
    }

    public func fetchDomains() async throws -> [Domain] {
        let revision = organizationRevision
        let fetchedDomains = try await domainService().listAllDomains()
        guard revision == organizationRevision else { throw CancellationError() }
        domains = fetchedDomains
        return fetchedDomains
    }

    private func domainService() throws -> PangolinDomainService {
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
        return PangolinDomainService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: pangolinOrganizationId
        )
    }
    
    public func fetchRoles() {
        let revision = organizationRevision
        Task {
            do {
                _ = try await fetchRoles()
            } catch {
                guard revision == organizationRevision else { return }
                roles = []
            }
        }
    }

    public func fetchRoles() async throws -> [Role] {
        let revision = organizationRevision
        let fetchedRoles = try await roleService().listAllRoles()
        guard revision == organizationRevision else { throw CancellationError() }
        roles = fetchedRoles
        return fetchedRoles
    }

    private func roleService() throws -> PangolinRoleService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: pangolinServerUrl, apiKey: pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinRoleService(client: PangolinAPIClient(configuration: configuration), organizationId: pangolinOrganizationId)
    }

    public func fetchUsers() {
        let revision = organizationRevision
        Task {
            do {
                _ = try await fetchUsers()
            } catch {
                guard revision == organizationRevision else { return }
                users = []
            }
        }
    }

    public func fetchUsers() async throws -> [User] {
        let revision = organizationRevision
        let fetchedUsers = try await userService().listAllUsers()
        guard revision == organizationRevision else { throw CancellationError() }
        users = fetchedUsers
        return fetchedUsers
    }

    private func userService() throws -> PangolinUserService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: pangolinServerUrl, apiKey: pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinUserService(client: PangolinAPIClient(configuration: configuration), organizationId: pangolinOrganizationId)
    }
}

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
    private var organizationRevision = UUID()
    
    @Published var organizations: [Organization] = []
    @Published var sites: [Site] = []
    @Published var resources: [Resource] = []
    @Published var domains: [Domain] = []
    @Published var roles: [Role] = []
    @Published var users: [User] = []
    
    public func fetchOrgs(completionHandler: @escaping (_ success: Bool, _ orgs: [Organization]) -> Void) {
        OrgsRequest.fetch { success, orgs in
            self.organizations = orgs
            if success, !orgs.contains(where: { $0.orgId == self.pangolinOrganizationId }),
               let org = orgs.first {
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
        let revision = organizationRevision
        let page = try await siteService().listSites()
        guard revision == organizationRevision else { throw CancellationError() }
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

    public func createHTTPResource(name: String, subdomain: String, domainId: String) async throws {
        resources.append(try await publicResourceService().createHTTP(name: name, subdomain: subdomain, domainId: domainId))
    }

    public func createRawResource(name: String, protocol rawProtocol: PublicResourceRawProtocol, proxyPort: Int) async throws {
        resources.append(try await publicResourceService().createRaw(name: name, protocol: rawProtocol, proxyPort: proxyPort))
    }

    public func updateResource(resourceId: Int, name: String? = nil, enabled: Bool? = nil, ssl: Bool? = nil) async throws -> Resource {
        let resource = try await publicResourceService().update(resourceId: resourceId, name: name, enabled: enabled, ssl: ssl)
        if let index = resources.firstIndex(where: { $0.resourceId == resourceId }) { resources[index] = resource }
        return resource
    }

    public func deleteResource(resourceId: Int) async throws {
        try await publicResourceService().delete(resourceId: resourceId)
        resources.removeAll { $0.resourceId == resourceId }
    }

    public func setResourcePassword(resourceId: Int, password: String?) async throws {
        let service = try publicResourceAuthService()
        let policy = try await service.getDefaultPolicy(resourceId: resourceId)
        try await service.setPassword(policyId: policy.resourcePolicyId, password: password)
        Task { try? await fetchResources() }
    }

    public func setResourcePinCode(resourceId: Int, pinCode: String?) async throws {
        let service = try publicResourceAuthService()
        let policy = try await service.getDefaultPolicy(resourceId: resourceId)
        try await service.setPinCode(policyId: policy.resourcePolicyId, pinCode: pinCode)
        Task { try? await fetchResources() }
    }

    public func setResourceSSO(resourceId: Int, enabled: Bool) async throws {
        try await publicResourceAuthService().setSSO(resourceId: resourceId, enabled: enabled)
        Task { try? await fetchResources() }
    }

    public func getResourcePolicy(resourceId: Int) async throws -> PublicResourcePolicy {
        try await publicResourceAuthService().getDefaultPolicy(resourceId: resourceId)
    }

    public func setResourceUsers(resourceId: Int, userIds: [String]) async throws {
        try await publicResourceAuthService().setUsers(resourceId: resourceId, userIds: userIds)
    }

    public func setResourceRoles(resourceId: Int, roleIds: [Int]) async throws {
        try await publicResourceAuthService().setRoles(resourceId: resourceId, roleIds: roleIds)
    }

    private func publicResourceService() throws -> PangolinPublicResourceService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: pangolinServerUrl, apiKey: pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL { throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey { throw PangolinAPIError.missingAPIKey }
        guard !pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw PangolinAPIError.organizationRequired }
        return PangolinPublicResourceService(client: PangolinAPIClient(configuration: configuration), organizationId: pangolinOrganizationId)
    }

    private func publicResourceAuthService() throws -> PangolinPublicResourceAuthService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: pangolinServerUrl, apiKey: pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        return PangolinPublicResourceAuthService(client: PangolinAPIClient(configuration: configuration))
    }

    public func fetchPrivateResources() async throws -> [PrivateResource] {
        try await privateResourceService().listAllResources()
    }

    public func createPrivateResource(configuration: PrivateResourceConfiguration) async throws {
        try await privateResourceService().create(configuration: configuration)
    }

    public func updatePrivateResource(
        resourceId: Int,
        configuration: PrivateResourceConfiguration
    ) async throws {
        try await privateResourceService().update(resourceId: resourceId, configuration: configuration)
    }

    public func deletePrivateResource(resourceId: Int) async throws {
        try await privateResourceService().delete(resourceId: resourceId)
    }

    private func privateResourceService() throws -> PangolinPrivateResourceService {
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
        return PangolinPrivateResourceService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: pangolinOrganizationId
        )
    }

    public func fetchTargets(resourceId: Int) async throws -> [Target] {
        try await publicTargetService().listAllTargets(resourceId: resourceId)
    }

    public func createTarget(resourceId: Int, configuration: PublicTargetConfiguration) async throws -> Target {
        try await publicTargetService().createTarget(resourceId: resourceId, configuration: configuration)
    }

    public func updateTarget(targetId: Int, configuration: PublicTargetConfiguration) async throws -> Target {
        try await publicTargetService().updateTarget(targetId: targetId, configuration: configuration)
    }

    public func deleteTarget(targetId: Int) async throws {
        try await publicTargetService().deleteTarget(targetId: targetId)
    }

    private func publicTargetService() throws -> PangolinPublicTargetService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: pangolinServerUrl, apiKey: pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        return PangolinPublicTargetService(client: PangolinAPIClient(configuration: configuration))
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

    public func fetchDNSRecords(domainId: String) async throws -> [DnsRecord] {
        try await domainService().listDNSRecords(domainId: domainId)
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
        RolesRequest.fetch { success, roles in
            guard revision == self.organizationRevision else { return }
            self.roles = roles
        }
    }
    
    public func fetchUsers() {
        let revision = organizationRevision
        UsersRequest.fetch { success, users in
            guard revision == self.organizationRevision else { return }
            self.users = users
        }
    }
}

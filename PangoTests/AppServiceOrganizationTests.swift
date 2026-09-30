import Foundation
import Testing
@testable import Pango

@Suite("Organization switching", .serialized)
@MainActor
struct AppServiceOrganizationTests {
    @Test("startup preserves a valid selection and otherwise selects the first organization", arguments: ["b", "missing", ""])
    func loadsOrganizations(selection: String) async {
        let previous = UserDefaults.standard.object(forKey: "pangolin_organization_id")
        defer { UserDefaults.standard.set(previous, forKey: "pangolin_organization_id") }
        let service = OrganizationListingService()
        service.pangolinOrganizationId = selection
        service.result = .success([Organization(orgId: "a", name: "A"), Organization(orgId: "b", name: "B")])
        var callbacks = 0
        let (success, organizations) = await withCheckedContinuation { continuation in
            service.fetchOrgs { success, organizations in
                callbacks += 1
                continuation.resume(returning: (success, organizations))
            }
        }
        #expect(success)
        #expect(callbacks == 1)
        #expect(organizations.map(\.orgId) == ["a", "b"])
        #expect(service.organizations.map(\.orgId) == ["a", "b"])
        #expect(service.pangolinOrganizationId == (selection == "b" ? "b" : "a"))
    }

    @Test("empty startup results clear cached organizations without selecting one")
    func loadsEmptyOrganizations() async {
        let previous = UserDefaults.standard.object(forKey: "pangolin_organization_id")
        defer { UserDefaults.standard.set(previous, forKey: "pangolin_organization_id") }
        let service = OrganizationListingService()
        service.pangolinOrganizationId = ""
        service.organizations = [Organization(orgId: "stale", name: "Stale")]
        let (success, organizations) = await withCheckedContinuation { continuation in
            service.fetchOrgs { continuation.resume(returning: ($0, $1)) }
        }
        #expect(success)
        #expect(organizations.isEmpty)
        #expect(service.organizations.isEmpty)
        #expect(service.pangolinOrganizationId.isEmpty)
    }

    @Test("startup failure calls back once and clears stale organizations")
    func failsOrganizationLoading() async {
        let service = OrganizationListingService()
        let selection = service.pangolinOrganizationId
        service.organizations = [Organization(orgId: "stale", name: "Stale")]
        service.result = .failure(.forbidden)
        var callbacks = 0
        let (success, organizations) = await withCheckedContinuation { continuation in
            service.fetchOrgs { success, organizations in
                callbacks += 1
                continuation.resume(returning: (success, organizations))
            }
        }
        #expect(!success)
        #expect(callbacks == 1)
        #expect(organizations.isEmpty)
        #expect(service.organizations.isEmpty)
        #expect(service.pangolinOrganizationId == selection)
    }

    @Test("startup fails safely with missing API configuration", arguments: [true, false])
    func failsMissingConfiguration(missingKey: Bool) async {
        let defaults = UserDefaults.standard
        let previousURL = defaults.object(forKey: "pangolin_server_url")
        let previousKey = defaults.object(forKey: "pangolin_api_key")
        defer {
            defaults.set(previousURL, forKey: "pangolin_server_url")
            defaults.set(previousKey, forKey: "pangolin_api_key")
        }
        let service = RefreshRecordingService()
        service.pangolinServerUrl = missingKey ? "https://api.example.com" : ""
        service.pangolinApiKey = missingKey ? "" : "synthetic-key"
        await #expect(throws: missingKey ? PangolinAPIError.missingAPIKey : .invalidBaseURL) {
            try await service.listOrganizations()
        }
        let (success, organizations) = await withCheckedContinuation { continuation in
            service.fetchOrgs { continuation.resume(returning: ($0, $1)) }
        }
        #expect(!success)
        #expect(organizations.isEmpty)
    }

    @Test("switching clears cached organization data and refreshes the new organization")
    func switchesOrganization() {
        let previous = UserDefaults.standard.object(forKey: "pangolin_organization_id")
        defer { UserDefaults.standard.set(previous, forKey: "pangolin_organization_id") }
        let service = RefreshRecordingService()
        service.pangolinOrganizationId = "org-a"
        service.refreshes = []
        service.sites = [.fake()]
        service.resources = [.fake()]
        service.domains = [Domain(domainId: "a", baseDomain: "a.example", type: "wildcard")]
        service.roles = [Role(roleId: 1)]
        service.users = [User(id: "a", email: "a@example.com", type: "user", roles: [])]

        service.pangolinOrganizationId = "org-b"

        #expect(service.sites.isEmpty)
        #expect(service.resources.isEmpty)
        #expect(service.domains.isEmpty)
        #expect(service.roles.isEmpty)
        #expect(service.users.isEmpty)
        #expect(service.refreshes == ["sites:org-b", "resources:org-b", "domains:org-b"])
        #expect(UserDefaults.standard.string(forKey: "pangolin_organization_id") == "org-b")
    }

    @Test("organization revision rejects stale results after switching away and back")
    func changesRevisionOnRoundTrip() {
        let previous = UserDefaults.standard.object(forKey: "pangolin_organization_id")
        defer { UserDefaults.standard.set(previous, forKey: "pangolin_organization_id") }
        let service = RefreshRecordingService()
        service.pangolinOrganizationId = "org-a"
        let initialRevision = service.organizationRevision

        service.pangolinOrganizationId = "org-b"
        service.pangolinOrganizationId = "org-a"

        #expect(service.organizationRevision != initialRevision)
        let currentRevision = service.organizationRevision
        service.pangolinOrganizationId = "org-a"
        #expect(service.organizationRevision == currentRevision)
    }

    @Test("selecting the same organization preserves loaded data")
    func keepsCurrentOrganization() {
        let previous = UserDefaults.standard.object(forKey: "pangolin_organization_id")
        defer { UserDefaults.standard.set(previous, forKey: "pangolin_organization_id") }
        let service = RefreshRecordingService()
        service.pangolinOrganizationId = "org-a"
        service.refreshes = []
        service.sites = [.fake()]

        service.pangolinOrganizationId = "org-a"

        #expect(service.sites.count == 1)
        #expect(service.refreshes.isEmpty)
    }
}

private final class RefreshRecordingService: AppService {
    var refreshes: [String] = []

    override func fetchSites(completionHandler: @escaping (Bool, [Site]) -> Void) {
        refreshes.append("sites:\(pangolinOrganizationId)")
        completionHandler(true, [])
    }

    override func fetchResources() {
        refreshes.append("resources:\(pangolinOrganizationId)")
    }

    override func fetchDomains() {
        refreshes.append("domains:\(pangolinOrganizationId)")
    }
}

private final class OrganizationListingService: AppService {
    var result: Result<[Organization], PangolinAPIError> = .success([])

    override func listOrganizations() async throws -> [Organization] {
        try result.get()
    }

    override func fetchSites(completionHandler: @escaping (Bool, [Site]) -> Void) {
        completionHandler(true, [])
    }

    override func fetchResources() {}
    override func fetchDomains() {}
}

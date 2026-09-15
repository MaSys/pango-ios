import Foundation
import Testing
@testable import Pango

@Suite("Organization switching", .serialized)
@MainActor
struct AppServiceOrganizationTests {
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

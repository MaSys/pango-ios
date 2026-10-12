import Foundation
import Testing
@testable import Pango

@MainActor
struct ResourceAuthenticationTests {
    @Test("details use policy PIN even when the resource omits it")
    func policyPIN() throws {
        let policy = try decodePolicy(pin: "4")
        let view = ResourceView(resource: .fake(), authenticationPolicy: policy)

        #expect(view.authenticationResource.pincodeId == 4)
        #expect(view.authenticationResource.protected)
    }

    @Test("policy removal overrides stale resource authentication")
    func removedAuthentication() throws {
        var resource = Resource.fake()
        resource.pincodeId = 4
        resource.passwordId = 3
        resource.sso = 1
        let view = ResourceView(resource: resource, authenticationPolicy: try decodePolicy(pin: "null"))

        #expect(!view.authenticationResource.protected)
    }

    @Test("resource authentication remains available before policy loads")
    func resourceFallback() {
        var resource = Resource.fake()
        resource.pincodeId = 4

        #expect(ResourceView(resource: resource).authenticationResource.pincodeId == 4)
    }

    private func decodePolicy(pin: String) throws -> PublicResourcePolicy {
        try JSONDecoder().decode(PublicResourcePolicy.self, from: Data("""
        {"resourcePolicyId":8,"sso":false,"passwordId":null,"pincodeId":\(pin),"roles":[],"users":[]}
        """.utf8))
    }
}

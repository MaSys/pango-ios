import Foundation
import Testing
@testable import Pango

@Suite("Pangolin public resource authentication service", .serialized)
struct PangolinPublicResourceAuthServiceTests {
    private func makeService() throws -> PangolinPublicResourceAuthService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinPublicResourceAuthService(
            client: PangolinAPIClient(
                configuration: try PangolinAPIConfiguration(
                    baseURLString: "https://api.example.com",
                    apiKey: "synthetic-key"
                ),
                session: URLSession(configuration: configuration)
            )
        )
    }

    @Test("loads the default public resource policy")
    func loadsDefaultPolicy() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/public-resource/4/policies")
            #expect(request.httpMethod == "GET")
            return .init(
                statusCode: 200,
                data: Data(#"{"data":{"defaultPolicy":{"resourcePolicyId":8,"sso":true,"applyRules":false,"emailWhitelistEnabled":false,"idpId":2,"niceId":"default","name":"Default","passwordId":3,"pincodeId":4,"headerAuth":{"id":null,"extendedCompability":null},"roles":[{"roleId":6,"name":"Member"}],"users":[{"userId":"user-1","email":"user@example.com","name":"User","username":"user","type":"internal","idpName":null}],"emailWhiteList":[],"rules":[]},"sharedPolicy":null},"success":true,"error":false,"message":"","status":200}"#.utf8)
            )
        }

        let policy = try await makeService().getDefaultPolicy(resourceId: 4)

        #expect(policy.resourcePolicyId == 8)
        #expect(policy.sso)
        #expect(policy.passwordId == 3)
        #expect(policy.pincodeId == 4)
        #expect(policy.roleIds == [6])
        #expect(policy.userIds == ["user-1"])
        #expect(policy.idpId == 2)
    }

    @Test("sets a password on the default policy")
    func setsPassword() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/public-resource-policy/8/password")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["password"] as? String == "four words")
            return .init(statusCode: 200, data: Self.emptyResponse)
        }

        try await makeService().setPassword(policyId: 8, password: "four words")
    }

    @Test("removes a password by sending null")
    func removesPassword() async throws {
        URLProtocolStub.handler = { request in
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json.keys.contains("password"))
            #expect(json["password"] is NSNull)
            return .init(statusCode: 200, data: Self.emptyResponse)
        }

        try await makeService().setPassword(policyId: 8, password: nil)
    }

    @Test("sets a six-digit PIN on the default policy")
    func setsPinCode() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/public-resource-policy/8/pincode")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["pincode"] as? String == "123456")
            return .init(statusCode: 200, data: Self.emptyResponse)
        }

        try await makeService().setPinCode(policyId: 8, pinCode: "123456")
    }

    @Test("removes a PIN by sending null")
    func removesPinCode() async throws {
        URLProtocolStub.handler = { request in
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json.keys.contains("pincode"))
            #expect(json["pincode"] is NSNull)
            return .init(statusCode: 200, data: Self.emptyResponse)
        }

        try await makeService().setPinCode(policyId: 8, pinCode: nil)
    }

    @Test("toggles SSO without clearing existing policy assignments")
    func togglesSSO() async throws {
        URLProtocolStub.handler = { request in
            if request.url?.path == "/v1/public-resource/4/policies" {
                return .init(statusCode: 200, data: Self.policyResponse)
            }

            #expect(request.url?.path == "/v1/public-resource-policy/8/access-control")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["sso"] as? Bool == false)
            #expect(json["userIds"] as? [String] == ["user-1"])
            #expect(json["roleIds"] as? [Int] == [6])
            #expect(json["skipToIdpId"] as? Int == 2)
            return .init(statusCode: 200, data: Self.emptyResponse)
        }

        try await makeService().setSSO(resourceId: 4, enabled: false)
    }

    @Test("sets users without clearing roles or SSO settings")
    func setsUsers() async throws {
        URLProtocolStub.handler = { request in
            if request.url?.path == "/v1/public-resource/4/policies" {
                return .init(statusCode: 200, data: Self.policyResponse)
            }

            #expect(request.url?.path == "/v1/public-resource-policy/8/access-control")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["sso"] as? Bool == true)
            #expect(json["userIds"] as? [String] == ["user-2"])
            #expect(json["roleIds"] as? [Int] == [6])
            #expect(json["skipToIdpId"] as? Int == 2)
            return .init(statusCode: 200, data: Self.emptyResponse)
        }

        try await makeService().setUsers(resourceId: 4, userIds: ["user-2"])
    }

    @Test("sets roles without clearing users or SSO settings")
    func setsRoles() async throws {
        URLProtocolStub.handler = { request in
            if request.url?.path == "/v1/public-resource/4/policies" {
                return .init(statusCode: 200, data: Self.policyResponse)
            }

            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["sso"] as? Bool == true)
            #expect(json["userIds"] as? [String] == ["user-1"])
            #expect(json["roleIds"] as? [Int] == [6, 7])
            #expect(json["skipToIdpId"] as? Int == 2)
            return .init(statusCode: 200, data: Self.emptyResponse)
        }

        try await makeService().setRoles(resourceId: 4, roleIds: [6, 7])
    }

    private static let emptyResponse = Data(
        #"{"data":{},"success":true,"error":false,"message":"","status":200}"#.utf8
    )

    private static let policyResponse = Data(
        #"{"data":{"defaultPolicy":{"resourcePolicyId":8,"sso":true,"applyRules":false,"emailWhitelistEnabled":false,"idpId":2,"niceId":"default","name":"Default","passwordId":3,"pincodeId":4,"headerAuth":{"id":null,"extendedCompability":null},"roles":[{"roleId":6,"name":"Member"}],"users":[{"userId":"user-1","email":"user@example.com","name":"User","username":"user","type":"internal","idpName":null}],"emailWhiteList":[],"rules":[]},"sharedPolicy":null},"success":true,"error":false,"message":"","status":200}"#.utf8
    )
}

private extension URLRequest {
    var bodyData: Data? {
        if let httpBody { return httpBody }
        guard let httpBodyStream else { return nil }
        httpBodyStream.open()
        defer { httpBodyStream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1_024)
        defer { buffer.deallocate() }
        while httpBodyStream.hasBytesAvailable {
            let count = httpBodyStream.read(buffer, maxLength: 1_024)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

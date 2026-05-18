//
//  Models.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

// Responses -----------------------------------

struct MainResponse<T: Decodable>: Decodable {
    var data: T?
    var success: Bool
    var error: Bool
    var message: String
    var status: Int
}

struct HealthCheckResponse: Decodable {
    var message: String
}

struct OrganizationsResponse: Decodable {
    var orgs: [Organization]
}

struct SitesResponse: Decodable {
    var sites: [Site]
}

struct ResourcesResponse: Decodable {
    var resources: [Resource]
}

struct DomainsResponse: Decodable {
    var domains: [Domain]
}

struct TargetsResponse: Decodable {
    var targets: [Target]
}

struct RolesResponse: Decodable {
    var roles: [Role]
}

struct UsersResponse: Decodable {
    var users: [User]
}

struct ResourceUsersResponse: Decodable {
    var users: [ResourceUser]
}

struct InvitationsResponse: Decodable {
    var invitations: [Invitation]
}

struct DomainDetailResponse: Decodable {
    var records: [DnsRecord]
}

struct PrivateResourcesResponse: Decodable {
    var resources: [PrivateResource]
}

struct HealthChecksResponse: Decodable {
    var healthChecks: [HealthCheck]
}

struct AlertRulesResponse: Decodable {
    var alerts: [AlertRule]
}

struct IdentityProvidersResponse: Decodable {
    var idps: [IdentityProvider]
}

struct EmptyResponse: Decodable {
}

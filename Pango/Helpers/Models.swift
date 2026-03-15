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

struct EmptyResponse: Decodable {
}

// New response types -----------------------------------

struct ClientsResponse: Decodable {
    var clients: [Client]
}

struct AccessLogsResponse: Decodable {
    var logs: [AccessLog]
}

struct ActionLogsResponse: Decodable {
    var logs: [ActionLog]
}

struct RequestLogsResponse: Decodable {
    var logs: [RequestLog]
}

struct RulesResponse: Decodable {
    var rules: [Rule]
}

struct ShareableLinksResponse: Decodable {
    var links: [ShareableLink]
}

struct IdentityProvidersResponse: Decodable {
    var idps: [IdentityProvider]
}

struct DeviceApprovalsResponse: Decodable {
    var approvals: [DeviceApproval]
}

struct NodesResponse: Decodable {
    var nodes: [Node]
}

struct BlueprintsResponse: Decodable {
    var blueprints: [Blueprint]
}

struct HealthCheckConfigResponse: Decodable {
    var enabled: Bool?
    var endpoint: String?
    var interval: Int?
    var timeout: Int?
    var unhealthyThreshold: Int?
    var healthyThreshold: Int?
    var lastChecked: String?
    var status: String?
}

struct MaintenanceResponse: Decodable {
    var enabled: Bool?
    var title: String?
    var message: String?
}

struct SecuritySettingsResponse: Decodable {
    var mfaRequired: Bool?
    var sessionLength: Int?
    var passwordRotationDays: Int?
}

struct GeoBlockingResponse: Decodable {
    var enabled: Bool?
    var countries: [String]?
    var mode: String?
}

struct ASNBlockingResponse: Decodable {
    var enabled: Bool?
    var asns: [String]?
    var mode: String?
}

struct BrandingResponse: Decodable {
    var logoUrl: String?
    var primaryColor: String?
    var accentColor: String?
    var loginTitle: String?
    var loginMessage: String?
    var footerText: String?
}

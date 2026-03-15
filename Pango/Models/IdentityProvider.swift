//
//  IdentityProvider.swift
//  Pango
//

struct IdentityProvider: Decodable {
    var idpId: Int
    var name: String?
    var type: String?
    var clientId: String?
    var clientSecret: String?
    var issuerUrl: String?
    var authUrl: String?
    var tokenUrl: String?
    var enabled: Bool?
    var autoProvision: Bool?
    var orgId: String?
    var dateCreated: String?

    var displayType: String {
        switch type?.lowercased() {
        case "azure": return "Azure Entra ID"
        case "google": return "Google SSO"
        case "oidc": return "OAuth2/OIDC"
        case "pocketid": return "Pocket ID"
        case "zitadel": return "Zitadel"
        default: return type?.capitalized ?? "Unknown"
        }
    }
}

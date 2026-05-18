//
//  IdentityProvider.swift
//  Pango
//

struct IdentityProvider: Decodable {
    var idpId: Int
    var orgId: String
    var name: String
    var type: String
    var variant: String
    var tags: String?
}

struct IdentityProviderDetail: Decodable {
    var idp: IdpFields
    var idpOidcConfig: IdpOidcConfig?
    var redirectUrl: String
}

struct IdpFields: Decodable {
    var idpId: Int
    var name: String
    var type: String
    var autoProvision: Bool?
    var tags: String?
}

struct IdpOidcConfig: Decodable {
    var clientId: String
    var clientSecret: String
    var authUrl: String
    var tokenUrl: String
    var identifierPath: String
    var emailPath: String?
    var namePath: String?
    var scopes: String
    var variant: String?
}

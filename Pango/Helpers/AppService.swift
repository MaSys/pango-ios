//
//  AppService.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

class AppService: ObservableObject {
    
    public static var shared = AppService()
    
    @AppStorage("pangolin_server_url") var pangolinServerUrl: String = ""
    @AppStorage("pangolin_api_key") var pangolinApiKey: String = ""
    @AppStorage("pangolin_organization_id") var pangolinOrganizationId: String = ""
    
    @Published var organizations: [Organization] = []
    @Published var sites: [Site] = []
    @Published var resources: [Resource] = []
    @Published var domains: [Domain] = []
    @Published var roles: [Role] = []
    @Published var users: [User] = []
    
    public func fetchOrgs(completionHandler: @escaping (_ success: Bool, _ orgs: [Organization]) -> Void) {
        Request.fetchOrgs { success, orgs in
            self.organizations = orgs
            if let org = orgs.first {
                self.pangolinOrganizationId = org.orgId
            }
            completionHandler(success, orgs)
        }
    }
    
    public func fetchSites(completionHandler: @escaping (_ success: Bool, _ sites: [Site]) -> Void) {
        Request.fetchSites { success, sites in
            self.sites = sites
            completionHandler(success, sites)
        }
    }
    
    public func fetchResources() {
        ResourcesRequest.fetch { success, resources in
            self.resources = resources
        }
    }
    
    public func fetchDomains() {
        Request.fetchDomains { success, domains in
            self.domains = domains
        }
    }
    
    public func fetchRoles() {
        RolesRequest.fetch { success, roles in
            self.roles = roles
        }
    }
    
    public func fetchUsers() {
        UsersRequest.fetch { success, users in
            self.users = users
        }
    }
}

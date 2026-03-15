//
//  ResourceView.swift
//  Pango
//
//  Created by Yaser Almasri on 05/08/25.
//

import SwiftUI

struct ResourceView: View {

    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    var resource: Resource

    @State private var ssl: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        List {
            detailsGroup

            if resource.resourceType == .privateResource {
                privateResourceSection
            } else {
                domain
            }

            if self.resource.http {
                authenticationSection
            }

            if resource.resourceType != .privateResource {
                monitoringSection
            }

            rulesSection

            HStack {
                Spacer()
                Button("DELETE") {
                    self.showDeleteConfirmation = true
                }
                .confirmationDialog(
                    "DELETE_RESOURCE_CONFIRMATION_MESSAGE",
                    isPresented: $showDeleteConfirmation
                ) {
                    Button("DELETE", role: .destructive) {
                        self.delete()
                    }
                    Button("CANCEL", role: .cancel) {
                    }
                }
                Spacer()
            }
        }
        .navigationTitle(self.resource.name)
        .onAppear {
            self.ssl = self.resource.ssl
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    NavigationLink {
                        ResourceNameView(resource: self.resource)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .tint(.accentColor)
                    }

                    Button {
                        self.toggleStatus()
                    } label: {
                        Image(systemName: self.resource.enabled ? "power.circle.fill" : "power.circle")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .tint(.accentColor)
                    }
                }
            }
        }
    }

    private func toggleStatus() {
        ResourcesRequest.toggleStatus(id: self.resource.resourceId, enabled: !self.resource.enabled) { success, response in
            if let res = response {
                print(res.message)
            }
            self.appService.fetchResources()
        }
    }

    private func toggleSSL() {
        ResourcesRequest.toggleSSL(id: self.resource.resourceId, ssl: self.ssl) { success, response in
            if let res = response, res.success {
                self.appService.fetchResources()
            }
        }
    }

    private func delete() {
        ResourcesRequest.delete(id: self.resource.resourceId) { success, response in
            if let res = response, res.success {
                self.appService.fetchResources()
                self.dismiss()
            }
        }
    }
}

extension ResourceView {
    var detailsGroup: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if resource.resourceType == .privateResource {
                        VStack(alignment: .leading) {
                            Text("TYPE")
                                .font(.system(size: 14))
                                .fontWeight(.semibold)
                            Text("PRIVATE")
                                .font(.system(size: 14))
                                .foregroundStyle(.purple)
                        }
                    } else if self.resource.http {
                        VStack(alignment: .leading) {
                            Text("AUTHENTICATION")
                                .font(.system(size: 14))
                                .fontWeight(.semibold)
                            HStack {
                                ShieldView(resource: resource, showText: true)
                            }
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("PORT")
                                .font(.system(size: 14))
                                .fontWeight(.semibold)
                            Text(String(self.resource.proxyPort ?? 0))
                                .font(.system(size: 14))
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("VISIBILITY")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                        Text(self.resource.enabled ? "ENABLED" : "DISABLED")
                            .font(.system(size: 14))
                            .foregroundStyle(self.resource.enabled ? .green : .red)
                    }
                }

                if self.resource.http {
                    HStack {
                        Text("URL")
                            .fontWeight(.semibold)
                            .font(.system(size: 14))
                        Spacer()
                        Link(
                            destination: URL(
                                string: fullURL(from: resource.fullDomain ?? "", ssl: resource.ssl)
                            )!
                        ) {
                            Text(fullURL(from: resource.fullDomain ?? "", ssl: resource.ssl))
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .contentShape(Rectangle())
                    .padding(.top)
                }

                if resource.resourceType == .privateResource {
                    if let host = resource.host {
                        HStack {
                            Text("HOST")
                                .fontWeight(.semibold)
                                .font(.system(size: 14))
                            Spacer()
                            Text(host)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    if let cidr = resource.cidr {
                        HStack {
                            Text("CIDR")
                                .fontWeight(.semibold)
                                .font(.system(size: 14))
                            Spacer()
                            Text(cidr)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .textCase(nil)
        .listRowSeparator(.hidden)
    }

    var privateResourceSection: some View {
        Section {
            NavigationLink {
                ResourcePrivateConfigView(resource: self.resource)
                    .environmentObject(self.appService)
            } label: {
                Text("PRIVATE_CONFIGURATION")
            }
            NavigationLink {
                ResourceTargetsView(resource: self.resource)
            } label: {
                Text("TARGETS")
            }
        }
    }

    var domain: some View {
        Section {
            if self.resource.http {
                Toggle(isOn: $ssl) {
                    Text("ENABLE_SSL_HTTPS")
                }
                .onChange(of: ssl) { oldValue, newValue in
                    self.toggleSSL()
                }
                NavigationLink {
                    ResourceDomainView(resource: self.resource)
                } label: {
                    Text("DOMAIN")
                }
            }
            NavigationLink {
                ResourceTargetsView(resource: self.resource)
            } label: {
                Text("TARGETS")
            }
        }
    }

    var authenticationSection: some View {
        Section {
            NavigationLink {
                ResourceSSOView(resource: self.resource)
                    .environmentObject(self.appService)
            } label: {
                HStack {
                    Text("USERS_AND_ROLES")
                    Spacer()
                    if self.resource.sso == false {
                        Text("DISABLED").foregroundStyle(.gray)
                    } else {
                        Text("ENABLED").foregroundStyle(.green)
                    }
                }
            }

            NavigationLink {
                ResourcePasswordView(resource: self.resource)
                    .environmentObject(self.appService)
            } label: {
                HStack {
                    Text("PASSWORD_PROTECTION")
                    Spacer()
                    if self.resource.passwordId == nil {
                        Text("DISABLED").foregroundStyle(.gray)
                    } else {
                        Text("ENABLED").foregroundStyle(.green)
                    }
                }
            }

            NavigationLink {
                ResourcePinCodeView(resource: self.resource)
            } label: {
                HStack {
                    Text("PIN_CODE_PROTECTION")
                    Spacer()
                    if self.resource.pincodeId == nil {
                        Text("DISABLED").foregroundStyle(.gray)
                    } else {
                        Text("ENABLED").foregroundStyle(.green)
                    }
                }
            }

            NavigationLink {
                ResourceSecurityKeysView(resource: self.resource)
            } label: {
                HStack {
                    Text("SECURITY_KEYS")
                    Spacer()
                    if self.resource.securityKeyId == nil {
                        Text("DISABLED").foregroundStyle(.gray)
                    } else {
                        Text("ENABLED").foregroundStyle(.green)
                    }
                }
            }

            NavigationLink {
                ResourceShareableLinksView(resource: self.resource)
                    .environmentObject(self.appService)
            } label: {
                HStack {
                    Text("SHAREABLE_LINKS")
                    Spacer()
                    if let count = self.resource.shareableLinkCount, count > 0 {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    var rulesSection: some View {
        Section {
            NavigationLink {
                ResourceRulesView(resource: self.resource)
            } label: {
                Text("RULES")
            }
        }
    }

    var monitoringSection: some View {
        Section(header: Text("MONITORING")) {
            NavigationLink {
                ResourceHealthCheckView(resource: self.resource)
            } label: {
                Text("HEALTH_CHECK")
            }
            NavigationLink {
                ResourceMaintenanceView(resource: self.resource)
            } label: {
                Text("MAINTENANCE")
            }
        }
        .textCase(nil)
    }
}

#Preview {
    ResourceView(resource: Resource.fake())
}

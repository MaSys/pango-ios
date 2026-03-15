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

            rulesSection

            Section {
                NavigationLink {
                    AnalyticsView(resourceId: resource.resourceId, resourceName: resource.name)
                } label: {
                    Label("ANALYTICS", systemImage: "chart.bar.xaxis")
                }
            }

            Section {
                Button("DELETE_RESOURCE", role: .destructive) {
                    self.showDeleteConfirmation = true
                }
                .frame(maxWidth: .infinity)
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
                    .accessibilityLabel("Edit name")

                    Button {
                        self.toggleStatus()
                    } label: {
                        Image(systemName: self.resource.enabled ? "power.circle.fill" : "power.circle")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .tint(.accentColor)
                    }
                    .accessibilityLabel(self.resource.enabled ? "Disable resource" : "Enable resource")
                }
            }
        }
    }

    private func toggleStatus() {
        ResourcesRequest.toggleStatus(id: self.resource.resourceId, enabled: !self.resource.enabled) { success, response in
            if let res = response {
                print(res.message ?? "")
            }
            hapticLight()
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
                hapticSuccess()
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
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("PRIVATE")
                                .font(.subheadline)
                                .foregroundStyle(.indigo)
                        }
                    } else if self.resource.http {
                        VStack(alignment: .leading) {
                            Text("AUTHENTICATION")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            HStack {
                                ShieldView(resource: resource, showText: true)
                            }
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("PORT")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(String(self.resource.proxyPort ?? 0))
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("VISIBILITY")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(self.resource.enabled ? "ENABLED" : "DISABLED")
                            .font(.subheadline)
                            .foregroundStyle(self.resource.enabled ? Color(.systemGreen) : Color(.systemRed))
                    }
                }

                if self.resource.http {
                    HStack {
                        Text("URL")
                            .fontWeight(.semibold)
                            .font(.subheadline)
                        Spacer()
                        Link(
                            destination: URL(
                                string: fullURL(from: resource.fullDomain ?? "", ssl: resource.ssl)
                            )!
                        ) {
                            Text(fullURL(from: resource.fullDomain ?? "", ssl: resource.ssl))
                                .font(.subheadline)
                                .foregroundStyle(.tint)
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
                                .font(.subheadline)
                            Spacer()
                            Text(host)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    if let cidr = resource.cidr {
                        HStack {
                            Text("CIDR")
                                .fontWeight(.semibold)
                                .font(.subheadline)
                            Spacer()
                            Text(cidr)
                                .font(.caption.monospaced())
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
                        Text("DISABLED").foregroundStyle(.secondary)
                    } else {
                        Text("ENABLED").foregroundStyle(Color(.systemGreen))
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
                        Text("DISABLED").foregroundStyle(.secondary)
                    } else {
                        Text("ENABLED").foregroundStyle(Color(.systemGreen))
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
                        Text("DISABLED").foregroundStyle(.secondary)
                    } else {
                        Text("ENABLED").foregroundStyle(Color(.systemGreen))
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

}

#Preview {
    ResourceView(resource: Resource.fake())
}

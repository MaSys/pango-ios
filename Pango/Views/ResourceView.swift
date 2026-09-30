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
    
    @State var resource: Resource
    
    @State private var ssl: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var errorKey: String?
    
    var body: some View {
        List {
            detailsGroup
            
            domain
            
            if self.resource.http {
                authenticationSection
            }
            
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
        .onReceive(appService.$resources) { resources in
            if let updated = resources.first(where: { $0.resourceId == resource.resourceId }) {
                resource = updated
            }
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
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func toggleStatus() {
        Task {
            do {
                let revision = appService.organizationRevision
                let updated = try await publicResourceService().update(resourceId: resource.resourceId, enabled: !resource.enabled)
                guard revision == appService.organizationRevision else { return }
                resource = updated
                if let index = appService.resources.firstIndex(where: { $0.resourceId == updated.resourceId }) {
                    appService.resources[index] = updated
                }
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
            }
        }
    }
    
    private func toggleSSL() {
        Task {
            do {
                let revision = appService.organizationRevision
                let updated = try await publicResourceService().update(resourceId: resource.resourceId, ssl: ssl)
                guard revision == appService.organizationRevision else { return }
                resource = updated
                if let index = appService.resources.firstIndex(where: { $0.resourceId == updated.resourceId }) {
                    appService.resources[index] = updated
                }
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
                ssl = resource.ssl
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
                ssl = resource.ssl
            }
        }
    }
    
    private func delete() {
        Task {
            do {
                let revision = appService.organizationRevision
                try await publicResourceService().delete(resourceId: resource.resourceId)
                guard revision == appService.organizationRevision else { return }
                appService.resources.removeAll { $0.resourceId == resource.resourceId }
                self.dismiss()
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
            }
        }
    }
}

extension ResourceView {
    var detailsGroup: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if self.resource.http {
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
                        .buttonStyle(.plain) // Ensures only the text is tappable
                    }
                    .contentShape(Rectangle()) // Limits the tappable area to the HStack
                    .padding(.top)
                }
            }
            .padding(.vertical, 2)
        }
        .textCase(nil)
        .listRowSeparator(.hidden)
    }//detailsGroup
    
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
    }//domain
    
    var authenticationSection: some View {
        Section {
            NavigationLink {
                ResourceSSOView(resource: self.resource)
                    .environmentObject(self.appService)
            } label: {
                HStack {
                    Text("USERS_AND_ROLES")
                    Spacer()
                    if self.resource.sso == 0 {
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
        }//Section
    }//authenticationSection
}

#Preview {
    ResourceView(resource: Resource.fake())
}

private extension ResourceView {
    func publicResourceService() throws -> PangolinPublicResourceService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: appService.pangolinServerUrl, apiKey: appService.pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinPublicResourceService(client: PangolinAPIClient(configuration: configuration), organizationId: appService.pangolinOrganizationId)
    }
}

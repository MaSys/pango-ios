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
                let updated = try await appService.updateResource(resourceId: resource.resourceId, enabled: !resource.enabled)
                resource = updated
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            }
        }
    }
    
    private func toggleSSL() {
        Task {
            do {
                resource = try await appService.updateResource(resourceId: resource.resourceId, ssl: ssl)
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
                ssl = resource.ssl
            }
        }
    }
    
    private func delete() {
        Task {
            do {
                try await appService.deleteResource(resourceId: resource.resourceId)
                self.dismiss()
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
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

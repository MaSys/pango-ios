//
//  ResourceView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 05/08/25.
//

import SwiftUI

struct ResourceView: View {
    
    @EnvironmentObject var appService: AppService
    
    var resource: Resource
    
    @State private var ssl: Bool = false
    
    var body: some View {
        List {
            detailsGroup
            
            domain
            
            authenticationSection
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
}

extension ResourceView {
    var detailsGroup: some View {
        Section {
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("AUTHENTICATION")
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                        HStack {
                            ShieldView(resource: resource, showText: true)
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("SITE")
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                        Text(self.resource.siteName ?? "")
                            .font(.system(size: 14))
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("VISIBILITY")
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                        Text(self.resource.enabled ? "ENABLED" : "DISABLED")
                            .font(.system(size: 14))
                            .foregroundStyle(self.resource.enabled ? .green : .red)
                    }
                }
                .padding(.bottom)
                
                Text("URL")
                    .fontWeight(.bold)
                Text(fullURL(from: resource.fullDomain, ssl: resource.ssl))
            }
        }//Section
        .textCase(nil)
    }//detailsGroup
    
    var domain: some View {
        Section {
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
                ResourcePasswordView(resource: self.resource)
            } label: {
                HStack {
                    if self.resource.passwordId == nil {
                        Text("PASSWORD_PROTECTION_DISABLED")
                            .foregroundStyle(.gray)
                    } else {
                        Text("PASSWORD_PROTECTION_ENABLED")
                            .foregroundStyle(.green)
                    }
                    Spacer()
                }
            }
            
            NavigationLink {
                ResourcePinCodeView(resource: self.resource)
            } label: {
                HStack {
                    if self.resource.pincodeId == nil {
                        Text("PIN_CODE_PROTECTION_DISABLED")
                            .foregroundStyle(.gray)
                    } else {
                        Text("PIN_CODE_PROTECTION_ENABLED")
                            .foregroundStyle(.green)
                    }
                    Spacer()
                }
            }
        }//Section
    }//authenticationSection
}

#Preview {
    ResourceView(resource: Resource.fake())
}

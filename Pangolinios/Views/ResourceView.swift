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
    
    var body: some View {
        List {
            detailsGroup
            
            authenticationSection
        }
        .navigationTitle(self.resource.name)
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
}

extension ResourceView {
    var title: some View {
        HStack {
//            Text(resource.name)
//                .font(.title)
//                .fontWeight(.bold)
//                .foregroundStyle(.primary)
            Spacer()

        }
        .padding(.bottom, 25)
    }//title
    
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

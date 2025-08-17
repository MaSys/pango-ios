//
//  InstanceView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI
import Alamofire

struct InstanceView: View {
    
    @EnvironmentObject var appService: AppService
    
    @AppStorage("pangolin_server_url") var pangolinServerUrl: String = ""
    @AppStorage("pangolin_api_key") var pangolinApiKey: String = ""
    @AppStorage("pangolin_organization_id") var pangolinOrganizationId: String = ""
    @Environment(\.dismiss) var dismiss
    
    @State private var serverUrl = ""
    @State private var apiKey = ""
    @State private var organizationId = ""
    @State private var connectionError: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("SERVER_URL")
                    TextField("SERVER_URL", text: $serverUrl)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.none)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                HStack {
                    Text("API_KEY")
                    SecureField("API_KEY", text: $apiKey)
                        .multilineTextAlignment(.trailing)
                }
                
                if connectionError == true {
                    Text("ERROR_CONNECTING_TO_SERVER")
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                }
            }
            
            Section(footer: Text("ORGANIZATION_ID_HINT")) {
                HStack {
                    Text("ORGANIZATION_ID")
                    TextField("ORGANIZATION_ID", text: $organizationId)
                        .multilineTextAlignment(.trailing)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
        }
        .onAppear {
            self.serverUrl = self.pangolinServerUrl
            self.apiKey = self.pangolinApiKey
            self.organizationId = self.pangolinOrganizationId
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if self.isLoading == false {
                        self.save()
                    }
                } label: {
                    Text("SAVE")
                }
            }
        }
    }
    
    private func save() {
        if self.serverUrl.isEmpty || self.apiKey.isEmpty {
            return
        }
        
        self.isLoading = true
        self.connectionError = false
        self.pangolinServerUrl = self.serverUrl
        self.pangolinApiKey = self.apiKey
        self.pangolinOrganizationId = self.organizationId
        
        if self.pangolinOrganizationId.isEmpty {
            self.appService.fetchOrgs { success, orgs in
                self.isLoading = false
                if success {
                    self.dismiss()
                } else {
                    self.connectionError = true
                }
            }
        } else {
            self.appService.fetchOrgs { _, _ in }
            self.appService.fetchSites { success, sites in
                self.isLoading = false
                if success {
                    self.dismiss()
                } else {
                    self.connectionError = true
                }
            }
        }
    }
}

#Preview {
    InstanceView()
}

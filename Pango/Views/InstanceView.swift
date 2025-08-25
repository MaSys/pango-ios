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
    @State private var authError: Bool = false
    @State private var isLoading: Bool = false
        
    var body: some View {
        Form {
            Section(footer: Text("SERVER_HINT")) {
                HStack {
                    Text("SERVER_URL")
                    TextField(String("https://api.pangolin.mydomain.com"), text: $serverUrl)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.none)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                HStack {
                    Text("API_KEY")
                    SecureField("abc123", text: $apiKey)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.trailing)
                }
                
                if connectionError == true {
                    Text("ERROR_CONNECTING_TO_SERVER")
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                }
                if authError == true {
                    Text("ERROR_API_KEY")
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                }
            }
            
            Section(footer: Text("ORGANIZATION_ID_HINT")) {
                HStack {
                    Text("ORGANIZATION_ID")
                    TextField("ORGANIZATION_ID", text: $organizationId)
                        .font(.system(size: 14))
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
                    self.save()
                } label: {
                    Text("SAVE")
                }
                .disabled(self.isLoading)
            }
        }
    }
    
    private func save() {
        if self.serverUrl.isEmpty || self.apiKey.isEmpty {
            print("empty")
            return
        }
        self.serverUrl = baseDomain(from: self.serverUrl)
        
        self.connectionError = false
        self.authError = false
        self.isLoading = true
        
        self.pangolinServerUrl = self.serverUrl
        self.pangolinApiKey = self.apiKey
        self.pangolinOrganizationId = self.organizationId

        Request.healthCheck { healthSuccess in
            if healthSuccess {
                self.authenticate()
            } else {
                self.isLoading = false
                self.connectionError = true
            }
        }
    }
    
    private func authenticate() {
        if self.pangolinOrganizationId.isEmpty {
            self.appService.fetchOrgs { success, orgs in
                self.isLoading = false
                if success {
                    self.dismiss()
                } else {
                    self.authError = true
                }
            }
        } else {
            self.appService.fetchOrgs { _, _ in }
            self.appService.fetchSites { success, sites in
                self.isLoading = false
                if success {
                    self.dismiss()
                } else {
                    self.authError = true
                }
            }
        }
    }
}

#Preview {
    InstanceView()
}

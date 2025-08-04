//
//  InstanceView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

struct InstanceView: View {
    
    @AppStorage("pangolin_server_url") var pangolinServerUrl: String = ""
    @AppStorage("pangolin_api_key") var pangolinApiKey: String = ""
    @AppStorage("pangolin_organization_id") var pangolinOrganizationId: String = ""
    @Environment(\.dismiss) var dismiss
    
    @State private var serverUrl = ""
    @State private var apiKey = ""
    @State private var organizationId = ""
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("SERVER_URL")
                    TextField("SERVER_URL", text: $serverUrl)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("API_KEY")
                    SecureField("API_KEY", text: $apiKey)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section(footer: Text("ORGANIZATION_ID_HINT")) {
                HStack {
                    Text("ORGANIZATION_ID")
                    TextField("ORGANIZATION_ID", text: $organizationId)
                        .multilineTextAlignment(.trailing)
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
            }
        }
    }
    
    private func save() {
        if self.serverUrl.isEmpty || self.apiKey.isEmpty {
            return
        }
        
        self.pangolinServerUrl = self.serverUrl
        self.pangolinApiKey = self.apiKey
        self.pangolinOrganizationId = self.organizationId
        
        // TODO: Test server before save.
        self.dismiss()
    }
}

#Preview {
    InstanceView()
}

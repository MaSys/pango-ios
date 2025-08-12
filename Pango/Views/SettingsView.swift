//
//  SettingsView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("pangolin_server_url") var pangolinServerUrl: String = ""
    @AppStorage("pangolin_api_key") var pangolinApiKey: String = ""
    @AppStorage("pangolin_organization_id") var pangolinOrganizationId: String = ""
    @AppStorage("selectedTab") private var selectedTab: DefaultTab = .sites
    
    @EnvironmentObject var appService: AppService
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("")) {
                    NavigationLink(destination: InstanceView()) {
                        VStack(alignment: .leading) {
                            Text("INSTANCE")
                            if !self.pangolinServerUrl.isEmpty {
                                Text(self.pangolinServerUrl)
                                    .foregroundStyle(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }//Link
                    
                    if self.appService.organizations.count > 0 {
                        Picker("ORGANIZATION", selection: $pangolinOrganizationId) {
                            ForEach(self.appService.organizations, id: \.orgId) { org in
                                Text(org.name)
                                    .tag(org.orgId)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }//Section
                
                Section {
                    Picker("DEFAULT_TAB", selection: $selectedTab) {
                        ForEach(DefaultTab.allCases, id: \.self) { tab in
                            Text(LocalizedStringResource(stringLiteral: tab.rawValue.capitalized))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }//List
            .navigationTitle(Text("SETTINGS"))
        }//NavStack
    }
}

#Preview {
    SettingsView()
}

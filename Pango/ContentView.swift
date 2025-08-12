//
//  ContentView.swift
//  Pango
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

enum DefaultTab: String, CaseIterable {
    case sites
    case resources
    case domains
}

struct ContentView: View {
    
    @AppStorage("selectedTab") private var defaultTab: DefaultTab = .sites
    
    @EnvironmentObject var appService: AppService
    
    @State private var selectedTab: String = "sites"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SitesView()
                .environmentObject(appService)
                .tabItem {
                    Label("SITES", systemImage: "server.rack")
                }
                .tag("sites")
            
            ResourcesView()
                .environmentObject(appService)
                .tabItem {
                    Label("RESOURCES", systemImage: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                }
                .tag("resources")
            
            DomainsView()
                .environmentObject(appService)
                .tabItem {
                    Label("DOMAINS", systemImage: "globe")
                }
                .tag("domains")
            
            SettingsView()
                .environmentObject(appService)
                .tabItem {
                    Label("SETTINGS", systemImage: "gear")
                }
                .tag("settings")
        }
        .onAppear {
            self.selectedTab = self.defaultTab.rawValue
            self.appService.fetchOrgs { _, _ in }
        }
    }
}

#Preview {
    ContentView()
}

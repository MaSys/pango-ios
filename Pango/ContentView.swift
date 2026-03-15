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
    case logs
}

struct ContentView: View {

    @AppStorage("selectedTab") private var selectedTab: DefaultTab = .sites

    @EnvironmentObject var appService: AppService

    var body: some View {
        TabView(selection: $selectedTab) {
            SitesView()
                .environmentObject(appService)
                .tabItem {
                    Label("SITES", systemImage: "server.rack")
                }
                .tag(DefaultTab.sites)

            ResourcesView()
                .environmentObject(appService)
                .tabItem {
                    Label("RESOURCES", systemImage: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                }
                .tag(DefaultTab.resources)

            DomainsView()
                .environmentObject(appService)
                .tabItem {
                    Label("DOMAINS", systemImage: "globe")
                }
                .tag(DefaultTab.domains)

            LogsView()
                .tabItem {
                    Label("LOGS", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(DefaultTab.logs)

            SettingsView()
                .environmentObject(appService)
                .tabItem {
                    Label("SETTINGS", systemImage: "gear")
                }
                .tag("settings")
        }
        .onAppear {
            self.appService.fetchOrgs { _, _ in }
            self.appService.fetchDomains()
            self.appService.fetchSites { _, _ in }
        }
    }
}

#Preview {
    ContentView()
}

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
    case analytics
    case settings
}

struct ContentView: View {

    @AppStorage("defaultTab") private var defaultTab: DefaultTab = .sites
    @State private var selectedTab: DefaultTab = .sites

    @EnvironmentObject var appService: AppService

    var body: some View {
        TabView(selection: $selectedTab) {
            SitesView()
                .environmentObject(appService)
                .tabItem {
                    Label("Sites", systemImage: "server.rack")
                }
                .tag(DefaultTab.sites)

            ResourcesView()
                .environmentObject(appService)
                .tabItem {
                    Label("Resources", systemImage: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                }
                .tag(DefaultTab.resources)

            DomainsView()
                .environmentObject(appService)
                .tabItem {
                    Label("Domains", systemImage: "globe")
                }
                .tag(DefaultTab.domains)

            NavigationStack {
                AnalyticsView(sites: appService.sites)
            }
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
                .tag(DefaultTab.analytics)

            SettingsView()
                .environmentObject(appService)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(DefaultTab.settings)
        }
        .onAppear {
            selectedTab = defaultTab
            self.appService.fetchOrgs { _, _ in }
            self.appService.fetchDomains()
            self.appService.fetchSites { _, _ in }
        }
    }
}

#Preview {
    ContentView()
}

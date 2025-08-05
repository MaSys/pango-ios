//
//  ContentView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var appService: AppService
    
    var body: some View {
        TabView {
            SitesView()
                .environmentObject(appService)
                .tabItem {
                    Label("SITES", systemImage: "server.rack")
                }
            
            ResourcesView()
                .environmentObject(appService)
                .tabItem {
                    Label("RESOURCES", systemImage: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                }
            
            DomainsView()
                .environmentObject(appService)
                .tabItem {
                    Label("DOMAINS", systemImage: "globe")
                }
            
            SettingsView()
                .environmentObject(appService)
                .tabItem {
                    Label("SETTINGS", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}

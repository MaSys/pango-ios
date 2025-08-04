//
//  ContentView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            SitesView()
                .tabItem {
                    Label("SITES", systemImage: "server.rack")
                }
            
            ResourcesView()
                .tabItem {
                    Label("RESOURCES", systemImage: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                }
            
            DomainsView()
                .tabItem {
                    Label("DOMAINS", systemImage: "globe")
                }
            
            SettingsView()
                .tabItem {
                    Label("SETTINGS", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}

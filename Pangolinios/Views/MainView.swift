//
//  MainView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            SitesView()
                .tabItem {
                    Image("sites")
                }
            
            ResourcesView()
                .tabItem {
                    Image("resources")
                }
            
            DomainsView()
                .tabItem {
                    Image("domains")
                }
        }
    }
}

#Preview {
    MainView()
}

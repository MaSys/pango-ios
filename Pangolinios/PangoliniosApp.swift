//
//  PangoliniosApp.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

@main
struct PangoliniosApp: App {
    
    @StateObject var appService = AppService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.appService)
        }
    }
}

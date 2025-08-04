//
//  ContentView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("pangolin_server_url") var pangolinServerUrl: String = ""
    @AppStorage("pangolin_api_key") var pangolinApiKey: String = ""
    
    @State private var serverUrl = ""
    @State private var apiKey = ""
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Text("Pangolinios")
                    .font(.system(size: 50))
                Spacer()
            }
            
            Text("SERVER_URL")
                .padding(.top, 50)
            TextField("", text: $serverUrl)
                .textFieldStyle(.roundedBorder)
            Text("API_KEY")
            SecureField("", text: $apiKey)
                .textFieldStyle(.roundedBorder)
            
            Button {
                self.login()
            } label: {
                HStack {
                    Spacer()
                    Text("LOGIN")
                    Spacer()
                }
            }
            .padding(.top, 25)
        }
        .padding(.horizontal, 50)
        .fullScreenCover(isPresented: $isLoggedIn) {
            MainView()
        }
    }
    
    private func login() {
        if self.serverUrl.isEmpty || self.apiKey.isEmpty {
            return
        }
        
        self.pangolinServerUrl = self.serverUrl
        self.pangolinApiKey = self.apiKey
        
        self.isLoggedIn = true
    }
}

#Preview {
    ContentView()
}

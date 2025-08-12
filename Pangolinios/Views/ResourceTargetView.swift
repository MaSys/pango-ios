//
//  ResourceNewTargetView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 11/08/25.
//

import SwiftUI

struct ResourceTargetView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    var target: Target?
    
    @State private var method: String = "http"
    @State private var ipHostname: String = ""
    @State private var port: String = ""
    @State private var enabled: Bool = true
    
    var body: some View {
        Form {
            Picker("METHOD", selection: $method) {
                Text("http")
                    .tag("http")
                Text("https")
                    .tag("https")
                Text("h2c")
                    .tag("h2c")
            }.pickerStyle(.segmented)
            
            HStack {
                TextField("IP_HOSTNAME", text: $ipHostname)
                    .keyboardType(.numbersAndPunctuation)
            }
            
            HStack {
                TextField("PORT", text: $port)
                    .keyboardType(.numberPad)
            }
            
            HStack {
                Toggle("ENABLED", isOn: $enabled)
            }
        }
        .onAppear {
            if let target = self.target {
                self.method = target.method
                self.ipHostname = target.ip
                self.port = String(target.port)
                self.enabled = target.enabled
            }
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
        if self.target == nil {
            self.create()
        } else {
            self.update()
        }
    }
    
    private func create() {
        TargetsRequest.create(
            resourceId: self.resource.resourceId,
            method: self.method,
            ip: self.ipHostname,
            port: self.port,
            enabled: self.enabled) { success, response in
                if success {
                    self.dismiss()
                }
            }
    }
    
    private func update() {
        TargetsRequest.update(
            id: self.target!.targetId,
            method: self.method,
            ip: self.ipHostname,
            port: self.port,
            enabled: self.enabled) { success, response in
                if success {
                    self.dismiss()
                }
            }
    }
}

#Preview {
    ResourceTargetView(resource: Resource.fake())
}

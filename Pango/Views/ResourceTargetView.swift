//
//  ResourceNewTargetView.swift
//  Pango
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
    @State private var siteId: Int = 0
    
    var validForm: Bool {
        if self.siteId == 0 { return false }
        if self.port.isEmpty { return false }
        if self.ipHostname.isEmpty { return false }
        
        return true
    }
    
    var body: some View {
        Form {
            Picker("SITE", selection: $siteId) {
                ForEach(self.appService.sites, id: \.siteId) { site in
                    Text(site.name)
                        .tag(site.siteId)
                }
            }.pickerStyle(.menu)
            
            if self.resource.http {
                Picker("METHOD", selection: $method) {
                    Text("http")
                        .tag("http")
                    Text("https")
                        .tag("https")
                    Text("h2c")
                        .tag("h2c")
                }.pickerStyle(.segmented)
            }
            
            HStack {
                TextField("IP_HOSTNAME", text: $ipHostname)
                    .keyboardType(.numbersAndPunctuation)
                    .autocapitalization(.none)
            }
            
            HStack {
                TextField("PORT", text: $port)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
            }
            
            HStack {
                Toggle("ENABLED", isOn: $enabled)
            }
        }
        .onAppear {
            if let target = self.target {
                self.method = target.method ?? ""
                self.ipHostname = target.ip
                self.port = String(target.port)
                self.enabled = target.enabled
                self.siteId = target.siteId
            } else {
                if let site = self.appService.sites.first {
                    self.siteId = site.siteId
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.save()
                } label: {
                    Text("SAVE")
                }
                .disabled(!self.validForm)
            }
        }
    }
    
    private func save() {
        if !self.validForm { return }
        
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
            enabled: self.enabled,
            siteId: self.siteId
        ) { success, response in
            if success {
                self.dismiss()
            }
        }
    }
    
    private func update() {
        TargetsRequest.update(
            id: self.target!.targetId,
            method: self.resource.http ? self.method : nil,
            ip: self.ipHostname,
            port: self.port,
            enabled: self.enabled,
            siteId: self.siteId
        ) { success, response in
            if success {
                self.dismiss()
            }
        }
    }
}

#Preview {
    ResourceTargetView(resource: Resource.fake())
}

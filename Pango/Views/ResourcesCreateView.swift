//
//  ResourcesCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 12/08/25.
//

import SwiftUI

struct ResourcesCreateView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var siteId: Int = 0
    @State private var resourceHttp: Bool = true
    
    @State private var subdomain: String = ""
    @State private var selectedDomain: String = ""
    
    @State private var protocolString: String = "tcp"
    @State private var proxyPort: String = ""
    
    @State private var errorMessage: String = ""
    
    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
                
                Picker("SITE", selection: $siteId) {
                    ForEach(self.appService.sites, id: \.siteId) { site in
                        Text(site.name)
                            .tag(site.siteId)
                    }
                }.pickerStyle(.menu)
            }//Section
            
            Section {
                resourceHttpPicker
                
                if self.resourceHttp {
                    httpsResourceType
                } else {
                    rawResourceType
                }
            }//Section
            
            if !self.errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .onChange(of: self.resourceHttp, { oldValue, newValue in
            if newValue {
                self.protocolString = "tcp"
                self.proxyPort = ""
            } else {
                self.subdomain = ""
                self.selectedDomain = ""
            }
        })
        .onAppear {
            if let site = self.appService.sites.first {
                self.siteId = site.siteId
            }
            if let domain = self.appService.domains.first {
                self.selectedDomain = domain.domainId
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
        ResourcesRequest.create(
            name: self.name,
            siteId: self.siteId,
            http: self.resourceHttp,
            subdomain: self.subdomain,
            domainId: self.selectedDomain.isEmpty ? nil : self.selectedDomain,
            protocolString: self.protocolString,
            proxyPort: self.proxyPort.isEmpty ? nil : Int(self.proxyPort)
        ) { success, response in
            if success {
                self.dismiss()
            } else {
                if let msg = response?.message {
                    self.errorMessage = msg
                }
            }
        }
    }
}

extension ResourcesCreateView {
    var resourceHttpPicker: some View {
        Picker("RESOURCE_TYPE", selection: $resourceHttp) {
            Text("HTTPS_RESOURCE")
                .tag(true)
            
            Text("RAW_TCP_UDP_RESOURCE")
                .tag(false)
        }.pickerStyle(.segmented)
    }//resourceHttpPicker
    
    var httpsResourceType: some View {
        Group {
            TextField("SUBDOMAIN", text: $subdomain)
            List {
                ForEach(self.appService.domains, id: \.domainId) { domain in
                    Button {
                        self.selectedDomain = domain.domainId
                    } label: {
                        HStack {
                            Text(domain.baseDomain)
                                .foregroundStyle(.white)
                            Spacer()
                            if self.selectedDomain == domain.domainId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }//Loop
            }//List
        }//Group
    }//httpsResourceType
    
    var rawResourceType: some View {
        Group {
            Picker("PROTOCOL", selection: $protocolString) {
                Text("TCP")
                    .tag("tcp")
                Text("UDP")
                    .tag("udp")
            }.pickerStyle(.menu)
            
            TextField("PORT_NUMBER", text: $proxyPort)
        }//Group
    }//rawResourceType
}

#Preview {
    ResourcesCreateView()
}

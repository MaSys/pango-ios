//
//  PrivateResourceCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct PrivateResourceCreateView: View {

    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var selectedSiteId: Int = 0
    @State private var resourceType: String = "host"
    @State private var ip: String = ""
    @State private var subnet: String = ""
    @State private var alias: String = ""
    @State private var errorMessage: String = ""

    var validForm: Bool {
        if name.isEmpty { return false }
        if selectedSiteId == 0 { return false }
        if resourceType == "host" && ip.isEmpty { return false }
        if resourceType == "cidr" && subnet.isEmpty { return false }
        return true
    }

    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
            }

            Section {
                Picker("SITE", selection: $selectedSiteId) {
                    ForEach(appService.sites, id: \.siteId) { site in
                        Text(site.name).tag(site.siteId)
                    }
                }.pickerStyle(.menu)

                Picker("TYPE", selection: $resourceType) {
                    Text("HOST").tag("host")
                    Text("CIDR").tag("cidr")
                }.pickerStyle(.segmented)
            }

            Section {
                if resourceType == "host" {
                    TextField("IP_HOSTNAME", text: $ip)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                } else {
                    TextField("SUBNET", text: $subnet)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                }
            }

            Section("ALIAS") {
                TextField("ALIAS", text: $alias)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .onAppear {
            if let site = appService.sites.first {
                selectedSiteId = site.siteId
            }
        }
        .navigationTitle("NEW_PRIVATE_RESOURCE")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") { self.save() }
                    .disabled(!validForm)
            }
        }
    }

    private func save() {
        PrivateResourcesRequest.create(
            name: name,
            siteId: selectedSiteId,
            type: resourceType,
            ip: resourceType == "host" ? ip : nil,
            subnet: resourceType == "cidr" ? subnet : nil,
            alias: alias.isEmpty ? nil : alias
        ) { success, response in
            if success {
                self.dismiss()
            } else {
                self.errorMessage = response?.message ?? ""
            }
        }
    }
}

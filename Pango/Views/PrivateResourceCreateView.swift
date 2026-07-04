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
    @State private var mode: String = "host"
    @State private var scheme: String = "http"
    @State private var destination: String = ""
    @State private var destinationPort: String = "80"
    @State private var alias: String = ""
    @State private var tcpPortRangeString: String = "*"
    @State private var udpPortRangeString: String = "*"
    @State private var icmpEnabled: Bool = true
    @State private var subdomain: String = ""
    @State private var domainId: String = ""
    @State private var ssl: Bool = false
    @State private var errorMessage: String = ""

    var validForm: Bool {
        if name.isEmpty { return false }
        if selectedSiteId == 0 { return false }
        if destination.isEmpty { return false }
        if mode == "cidr" && alias.isEmpty { return false }

        if mode == "http" {
            if Int(destinationPort) == nil { return false }
            if subdomain.isEmpty { return false }
            if domainId.isEmpty { return false }
        }

        return true
    }

    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)

                Picker("SITE", selection: $selectedSiteId) {
                    ForEach(appService.sites, id: \.siteId) { site in
                        Text(site.name).tag(site.siteId)
                    }
                }.pickerStyle(.menu)

                Picker("MODE", selection: $mode) {
                    Text("HOST").tag("host")
                    Text("CIDR").tag("cidr")
                    Text("HTTP").tag("http")
                }.pickerStyle(.segmented)
            }

            if mode == "http" {
                httpFields
            } else {
                networkFields
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
            if appService.domains.isEmpty {
                appService.fetchDomains()
            } else if domainId.isEmpty, let domain = appService.domains.first {
                domainId = domain.domainId
            }
        }
        .onChange(of: appService.domains.count) {
            if domainId.isEmpty, let domain = appService.domains.first {
                domainId = domain.domainId
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

    var networkFields: some View {
        Group {
            Section {
                TextField("DESTINATION", text: $destination)
                    .keyboardType(.numbersAndPunctuation)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
            }

            if mode == "host" || mode == "cidr" {
                Section("ALIAS") {
                    TextField("ALIAS", text: $alias)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                }
            }

            Section("PORTS") {
                TextField("TCP", text: $tcpPortRangeString)
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                TextField("UDP", text: $udpPortRangeString)
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                Toggle("ICMP", isOn: $icmpEnabled)
            }
        }
    }

    var httpFields: some View {
        Group {
            Section {
                Picker("SCHEME", selection: $scheme) {
                    Text("HTTP").tag("http")
                    Text("HTTPS").tag("https")
                }.pickerStyle(.segmented)

                TextField("DESTINATION", text: $destination)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)

                TextField("PORT", text: $destinationPort)
                    .keyboardType(.numberPad)
            }

            Section {
                TextField("SUBDOMAIN", text: $subdomain)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)

                Picker("BASE_DOMAIN", selection: $domainId) {
                    Text("SELECT").tag("")
                    ForEach(appService.domains, id: \.domainId) { domain in
                        Text(domain.baseDomain).tag(domain.domainId)
                    }
                }.pickerStyle(.menu)
            }

            Section {
                Toggle("ENABLE_TLS", isOn: $ssl)
            }
        }
    }

    private func save() {
        PrivateResourcesRequest.create(
            name: name,
            siteId: selectedSiteId,
            mode: mode,
            ssl: mode == "http" && ssl,
            scheme: mode == "http" ? scheme : nil,
            destinationPort: mode == "http" ? Int(destinationPort) : nil,
            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
            alias: mode == "host" && !alias.isEmpty ? alias : nil,
            tcpPortRangeString: mode == "http" ? nil : tcpPortRangeString,
            udpPortRangeString: mode == "http" ? nil : udpPortRangeString,
            disableIcmp: mode == "http" ? nil : !icmpEnabled,
            domainId: mode == "http" ? domainId : nil,
            subdomain: mode == "http" ? subdomain : nil
        ) { success, response in
            if success {
                self.dismiss()
            } else {
                self.errorMessage = response?.message ?? ""
            }
        }
    }
}

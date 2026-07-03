//
//  PrivateResourceView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct PrivateResourceView: View {

    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    var resource: PrivateResource

    @State private var name: String = ""
    @State private var mode: String = "host"
    @State private var scheme: String = "http"
    @State private var destination: String = ""
    @State private var destinationPort: String = ""
    @State private var alias: String = ""
    @State private var tcpPortRangeString: String = "*"
    @State private var udpPortRangeString: String = "*"
    @State private var icmpEnabled: Bool = true
    @State private var subdomain: String = ""
    @State private var domainId: String = ""
    @State private var ssl: Bool = false
    @State private var errorMessage: String = ""
    @State private var showDeleteConfirmation: Bool = false

    var validForm: Bool {
        if name.isEmpty { return false }
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

            Section {
                HStack {
                    Spacer()
                    Button("DELETE") {
                        self.showDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
                    .confirmationDialog(
                        "DELETE_RESOURCE_CONFIRMATION_MESSAGE",
                        isPresented: $showDeleteConfirmation
                    ) {
                        Button("DELETE", role: .destructive) { self.delete() }
                        Button("CANCEL", role: .cancel) {}
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle(resource.name)
        .onAppear {
            self.name = resource.name
            self.mode = resource.mode
            self.scheme = resource.scheme ?? "http"
            self.destination = resource.destination
            self.destinationPort = resource.destinationPort.map(String.init) ?? ""
            self.alias = resource.alias ?? ""
            self.tcpPortRangeString = resource.tcpPortRangeString
            self.udpPortRangeString = resource.udpPortRangeString
            self.icmpEnabled = !resource.disableIcmp
            self.subdomain = resource.subdomain ?? ""
            self.domainId = resource.domainId ?? ""
            self.ssl = resource.ssl

            if appService.domains.isEmpty {
                appService.fetchDomains()
            }
        }
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
                    if domainIdIsMissing {
                        Text(resource.fullDomain ?? domainId).tag(domainId)
                    }
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

    var domainIdIsMissing: Bool {
        !domainId.isEmpty && !appService.domains.contains { $0.domainId == domainId }
    }

    private func save() {
        PrivateResourcesRequest.update(
            id: resource.siteResourceId,
            name: name,
            siteIds: resource.siteIds,
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

    private func delete() {
        PrivateResourcesRequest.delete(id: resource.siteResourceId) { success in
            if success { self.dismiss() }
        }
    }
}

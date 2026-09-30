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
    @State private var siteSelection = PrivateResourceSiteSelection()
    @State private var hasInitializedSites = false
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
    @State private var isSaving = false
    @State private var errorMessage: String?

    var validForm: Bool {
        if name.isEmpty { return false }
        if siteSelection.siteIds.isEmpty { return false }
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

            PrivateResourceSitesSection(selection: $siteSelection)
                .disabled(isSaving)

            if mode == "http" {
                httpFields
            } else {
                networkFields
            }

        }
        .onAppear {
            if !hasInitializedSites {
                hasInitializedSites = true
                siteSelection = PrivateResourceSiteSelection(siteIds: appService.sites.first.map { [$0.siteId] } ?? [])
            }
            if appService.domains.isEmpty {
                appService.fetchDomains()
            } else if domainId.isEmpty, let domain = appService.domains.first {
                domainId = domain.domainId
            }
        }
        .onChange(of: appService.organizationRevision) {
            siteSelection = PrivateResourceSiteSelection()
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
                    .disabled(!validForm || isSaving)
            }
        }
        .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let errorMessage { Text(errorMessage) }
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
        guard validForm, !isSaving else { return }
        let revision = appService.organizationRevision
        let configuration = configuration
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                guard revision == appService.organizationRevision else { return }
                try await privateResourceService().create(configuration: configuration)
                guard revision == appService.organizationRevision else { return }
                dismiss()
            } catch {
                guard revision == appService.organizationRevision else { return }
                errorMessage = (error as? PangolinAPIError)?.localizedMessage() ?? PangolinAPIError.transport.localizedMessage()
            }
        }
    }

    private var configuration: PrivateResourceConfiguration {
        PrivateResourceConfiguration(
            name: name,
            siteIds: siteSelection.siteIds,
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
        )
    }
}

private extension PrivateResourceCreateView {
    func privateResourceService() throws -> PangolinPrivateResourceService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(
                baseURLString: appService.pangolinServerUrl,
                apiKey: appService.pangolinApiKey
            )
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinPrivateResourceService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: appService.pangolinOrganizationId
        )
    }
}

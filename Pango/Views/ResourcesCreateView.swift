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
            }
        })
        .onAppear {
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
        Task {
            do {
                let revision = appService.organizationRevision
                let service = try publicResourceService()
                let created: Resource
                if resourceHttp {
                    created = try await service.createHTTP(name: name, subdomain: subdomain, domainId: selectedDomain)
                } else if let port = Int(proxyPort), let rawProtocol = PublicResourceRawProtocol(rawValue: protocolString) {
                    created = try await service.createRaw(name: name, protocol: rawProtocol, proxyPort: port)
                } else {
                    throw PangolinAPIError.serverRejected(status: 400, message: "INVALID_PORT")
                }
                guard revision == appService.organizationRevision else { return }
                appService.resources.append(created)
                dismiss()
            } catch let error as PangolinAPIError {
                errorMessage = String(localized: String.LocalizationValue(error.localizationKey))
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
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
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

private extension ResourcesCreateView {
    func publicResourceService() throws -> PangolinPublicResourceService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: appService.pangolinServerUrl, apiKey: appService.pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinPublicResourceService(client: PangolinAPIClient(configuration: configuration), organizationId: appService.pangolinOrganizationId)
    }
}

//
//  ResourceDomainView.swift
//  Pango
//
//  Created by Yaser Almasri on 09/08/25.
//

import SwiftUI

struct ResourceDomainView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var subdomain: String = ""
    @State private var selectedDomain: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
                List {
                    Section {
                        TextField("SUBDOMAIN", text: self.$subdomain)
                            .textInputAutocapitalization(.none)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    Section {
                        ForEach(self.appService.domains, id: \.domainId) { domain in
                            Button {
                                self.selectedDomain = domain.domainId
                            } label: {
                                HStack {
                                    Text(domain.baseDomain)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if self.selectedDomain == domain.domainId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                        }
                    }
                }
            Spacer()
        }
        .onAppear {
            self.appService.fetchDomains()
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
        .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
    }
    
    private func save() {
        if self.subdomain.isEmpty || self.selectedDomain.isEmpty {
            errorMessage = String(localized: "ERROR_RESOURCE_DOMAIN_REQUIRED")
            return
        }
        
        Task {
            do {
                try await publicResourceService().updateDomain(
                    resourceId: resource.resourceId,
                    domainId: selectedDomain,
                    subdomain: subdomain
                )
                refreshAndDismiss()
            } catch is CancellationError {
                return
            } catch {
                errorMessage = (error as? PangolinAPIError)?.localizedMessage() ?? PangolinAPIError.transport.localizedMessage()
            }
        }
    }

    private func refreshAndDismiss() {
        appService.fetchResources()
        dismiss()
    }
}

#Preview {
    ResourceDomainView(resource: Resource.fake())
}

private extension ResourceDomainView {
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

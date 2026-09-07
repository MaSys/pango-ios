//
//  InstanceView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

struct InstanceView: View {
    
    @EnvironmentObject var appService: AppService
    
    @AppStorage("pangolin_server_url") var pangolinServerUrl: String = ""
    @AppStorage("pangolin_api_key") var pangolinApiKey: String = ""
    @AppStorage("pangolin_organization_id") var pangolinOrganizationId: String = ""
    @Environment(\.dismiss) var dismiss
    
    @State private var serverUrl = ""
    @State private var apiKey = ""
    @State private var organizationId = ""
    @State private var errorKey: String?
    @State private var isLoading: Bool = false
        
    var body: some View {
        Form {
            Section(footer: Text("SERVER_HINT")) {
                HStack {
                    Text("SERVER_URL")
                    TextField(String("https://api.pangolin.mydomain.com"), text: $serverUrl)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.none)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                HStack {
                    Text("API_KEY")
                    SecureField("abc123", text: $apiKey)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.trailing)
                }
                
                if let errorKey {
                    Text(LocalizedStringKey(errorKey))
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                }
            }
            
            Section(footer: Text("ORGANIZATION_ID_HINT")) {
                HStack {
                    Text("ORGANIZATION_ID")
                    TextField("ORGANIZATION_ID", text: $organizationId)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.trailing)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
        }
        .onAppear {
            self.serverUrl = self.pangolinServerUrl
            self.apiKey = self.pangolinApiKey
            self.organizationId = self.pangolinOrganizationId
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.save()
                } label: {
                    Text("SAVE")
                }
                .disabled(self.isLoading)
            }
        }
    }
    
    private func save() {
        errorKey = nil
        do {
            let configuration = try PangolinAPIConfiguration(
                baseURLString: serverUrl,
                apiKey: apiKey
            )
            isLoading = true
            Task {
                do {
                    let service = PangolinConnectionService(
                        client: PangolinAPIClient(configuration: configuration)
                    )
                    let organizations = try await service.validate(organizationId: organizationId)
                    guard let selectedOrganization = selectedOrganization(from: organizations) else {
                        throw PangolinAPIError.forbidden
                    }

                    serverUrl = configuration.baseURL.absoluteString
                    organizationId = selectedOrganization.orgId
                    pangolinServerUrl = serverUrl
                    pangolinApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    pangolinOrganizationId = organizationId
                    appService.organizations = organizations
                    isLoading = false
                    dismiss()
                } catch let error as PangolinAPIError {
                    isLoading = false
                    errorKey = error.localizationKey
                } catch {
                    isLoading = false
                    errorKey = PangolinAPIError.transport.localizationKey
                }
            }
        } catch let error as PangolinAPIConfiguration.Error {
            switch error {
            case .invalidBaseURL:
                errorKey = PangolinAPIError.invalidBaseURL.localizationKey
            case .missingAPIKey:
                errorKey = PangolinAPIError.missingAPIKey.localizationKey
            }
        } catch {
            errorKey = PangolinAPIError.invalidBaseURL.localizationKey
        }
    }

    private func selectedOrganization(from organizations: [Organization]) -> Organization? {
        let requestedOrganizationId = organizationId.trimmingCharacters(in: .whitespacesAndNewlines)
        if requestedOrganizationId.isEmpty {
            return organizations.first
        }
        return organizations.first { $0.orgId == requestedOrganizationId }
    }
}

#Preview {
    InstanceView()
}

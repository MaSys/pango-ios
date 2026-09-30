//
//  ResourceNameView.swift
//  Pango
//
//  Created by Yaser Almasri on 07/08/25.
//

import SwiftUI

struct ResourceNameView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var name: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
                    .autocapitalization(.words)
            }
        }
        .onAppear {
            self.name = self.resource.name
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
        if self.name.isEmpty { return }
        
        Task {
            do {
                let revision = appService.organizationRevision
                let updated = try await publicResourceService().update(resourceId: resource.resourceId, name: name)
                guard revision == appService.organizationRevision else { return }
                if let index = appService.resources.firstIndex(where: { $0.resourceId == updated.resourceId }) {
                    appService.resources[index] = updated
                }
                self.dismiss()
            } catch let error as PangolinAPIError {
                errorMessage = error.localizedMessage()
            } catch {
                errorMessage = String(localized: "ERROR_CONNECTING_TO_SERVER")
            }
        }
    }
}

#Preview {
    ResourceNameView(resource: Resource.fake())
}

private extension ResourceNameView {
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

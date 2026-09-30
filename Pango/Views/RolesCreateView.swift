//
//  RolesCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

import SwiftUI

struct RolesCreateView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isSaving = false
    @State private var errorKey: String?
    
    var body: some View {
        Form {
            HStack {
                Text("NAME")
                Spacer()
                TextField("NAME", text: $name)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .autocapitalization(.words)
            }
            
            HStack {
                Text("DESCRIPTION")
                Spacer()
                TextField("DESCRIPTION", text: $description)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .autocapitalization(.words)
            }
        }//form
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    self.save()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func save() {
        guard !isSaving, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let revision = appService.organizationRevision
                let role = try await roleService().create(name: name, description: description)
                guard revision == appService.organizationRevision else { return }
                appService.roles.append(role)
                dismiss()
            } catch is CancellationError {
                return
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_API_RESPONSE"
            }
        }
    }
}

#Preview {
    RolesCreateView()
}

private extension RolesCreateView {
    func roleService() throws -> PangolinRoleService {
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
        return PangolinRoleService(client: PangolinAPIClient(configuration: configuration), organizationId: appService.pangolinOrganizationId)
    }
}

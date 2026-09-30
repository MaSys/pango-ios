//
//  RolesView.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

import SwiftUI

struct RolesView: View {
    
    @EnvironmentObject var appService: AppService
    
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.appService.roles, id: \.roleId) { role in
                    VStack(alignment: .leading) {
                        Text(role.name ?? "")
                            .fontWeight(.semibold)
                        
                        Text(role.description ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        NavigationLink {
                            DeleteRoleView(roleToDelete: role)
                            .environmentObject(self.appService)
                            .presentationDetents([.medium])
                        } label: {
                            Label("DELETE", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .navigationTitle("ROLES")
            .task {
                do {
                    _ = try await appService.fetchRoles()
                } catch is CancellationError {
                    return
                } catch let error as PangolinAPIError {
                    errorMessage = error.localizedMessage()
                } catch {
                    errorMessage = String(localized: "ERROR_API_RESPONSE")
                }
            }
            .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let errorMessage { Text(errorMessage) }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        RolesCreateView()
                            .environmentObject(self.appService)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

}

#Preview {
    RolesView()
}

struct DeleteRoleView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var roleToDelete: Role
    
    @State private var selectedRoleForTransfer: Role?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        if self.roleToDelete.isAdmin == true {
            Text("YOU_CANNOT_DELETE_ADMIN_ROLE")
        } else {
            List {
                Section(header: VStack {
                    HStack {
                        Spacer()
                        Text("TRANSFER_USERS")
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text("SELECT_A_ROLE_TO_TRANSFER_USERS_FROM_**\(roleToDelete.name ?? "")**:")
                        Spacer()
                    }
                }) {
                    ForEach(self.appService.roles.filter { $0.roleId != roleToDelete.roleId }, id: \.roleId) { role in
                        Button {
                            self.selectedRoleForTransfer = role
                        } label: {
                            HStack {
                                Text(role.name ?? "")
                                Spacer()
                                if let rol = self.selectedRoleForTransfer, rol.roleId == role.roleId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }//hstack
                        }
                        .tint(.primary)
                    }
                }//section
                .textCase(.none)
            }//list
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("SAVE") {
                        self.save()
                    }
                    .disabled(self.selectedRoleForTransfer == nil || isSaving)
                }
            }
            .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let errorMessage { Text(errorMessage) }
            }
        }
    }
    
    private func save() {
        guard !isSaving, roleToDelete.isAdmin != true,
              let selectedRoleForTransfer,
              selectedRoleForTransfer.roleId != roleToDelete.roleId else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let revision = appService.organizationRevision
                try await roleService().delete(roleId: roleToDelete.roleId, transferRoleId: selectedRoleForTransfer.roleId)
                guard revision == appService.organizationRevision else { return }
                appService.roles.removeAll { $0.roleId == roleToDelete.roleId }
                dismiss()
            } catch is CancellationError {
                return
            } catch let error as PangolinAPIError {
                errorMessage = error.localizedMessage()
            } catch {
                errorMessage = String(localized: "ERROR_API_RESPONSE")
            }
        }
    }
}

private extension DeleteRoleView {
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

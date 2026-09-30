//
//  InvitationCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/10/25.
//

import SwiftUI

struct InvitationCreateView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    @State private var email: String = ""
    @State private var validHours: Int = 24
    @State private var roleId: Int = 0
    @State private var isSaving = false
    @State private var errorKey: String?
    @State private var createdInvitation: CreatedInvitation?
    
    var validForm: Bool {
        if self.email.isEmpty { return false }
        if self.validHours == 0 { return false }
        if self.roleId == 0 { return false }
        
        return true
    }
    
    var body: some View {
        Form {
            if let createdInvitation {
                Section {
                    Text(createdInvitation.inviteLink)
                        .textSelection(.enabled)
                    ShareLink(item: createdInvitation.inviteLink)
                }
            } else {
                HStack {
                    Text("EMAIL")
                    TextField("EMAIL", text: $email)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                }
                HStack {
                    Text("VALID_FOR")
                    Picker("", selection: $validHours) {
                        ForEach(1..<8) { i in
                            Text("\(i)_DAY").tag(24 * i)
                        }
                    }
                }
                Picker("ROLE", selection: $roleId) {
                    Text("ROLE").tag(0)
                    ForEach(self.appService.roles, id: \.roleId) { role in
                        Text(role.name ?? "")
                            .tag(role.roleId)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }//form
        .navigationTitle("INVITE_USER")
        .task {
            do {
                _ = try await appService.fetchRoles()
            } catch is CancellationError {
                return
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_API_RESPONSE"
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if createdInvitation != nil {
                    Button("DONE") { dismiss() }
                } else {
                    Button("SAVE") { save() }
                        .disabled(!validForm || isSaving)
                }
            }
        }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func save() {
        guard validForm, !isSaving else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let revision = appService.organizationRevision
                let result = try await invitationService().create(email: email, validHours: validHours, roleId: roleId)
                guard revision == appService.organizationRevision else { return }
                createdInvitation = result
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
    InvitationCreateView()
}

private extension InvitationCreateView {
    func invitationService() throws -> PangolinInvitationService {
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
        return PangolinInvitationService(client: PangolinAPIClient(configuration: configuration), organizationId: appService.pangolinOrganizationId)
    }
}

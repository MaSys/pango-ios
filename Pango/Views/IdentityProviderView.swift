//
//  IdentityProviderView.swift
//  Pango
//

import SwiftUI

struct IdentityProviderView: View {

    @Environment(\.dismiss) var dismiss

    var idpId: Int?
    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var variant: String = "oidc"
    @State private var clientId: String = ""
    @State private var clientSecret: String = ""
    @State private var authUrl: String = ""
    @State private var tokenUrl: String = ""
    @State private var scopes: String = ""
    @State private var identifierPath: String = ""
    @State private var emailPath: String = ""
    @State private var namePath: String = ""
    @State private var autoProvision: Bool = false
    @State private var redirectUrl: String = ""
    @State private var errorMessage: String = ""
    @State private var isSaving: Bool = false

    var isEditing: Bool { idpId != nil }

    var validForm: Bool {
        !name.isEmpty &&
        !clientId.isEmpty &&
        !clientSecret.isEmpty &&
        !authUrl.isEmpty &&
        !tokenUrl.isEmpty &&
        !scopes.isEmpty &&
        !identifierPath.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
                    .autocorrectionDisabled(true)
                Picker("VARIANT", selection: $variant) {
                    Text("OIDC").tag("oidc")
                    Text("GOOGLE").tag("google")
                    Text("AZURE").tag("azure")
                }.pickerStyle(.menu)
                .disabled(isEditing)
            }

            Section(header: Text("OIDC")) {
                TextField("CLIENT_ID", text: $clientId)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                SecureField("CLIENT_SECRET", text: $clientSecret)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                TextField("AUTH_URL", text: $authUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                TextField("TOKEN_URL", text: $tokenUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                TextField("SCOPES", text: $scopes)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                TextField("IDENTIFIER_PATH", text: $identifierPath)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                TextField("EMAIL_PATH", text: $emailPath)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                TextField("NAME_PATH", text: $namePath)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
            }

            Section {
                Toggle("AUTO_PROVISION", isOn: $autoProvision)
            }

            if isEditing && !redirectUrl.isEmpty {
                Section(header: Text("REDIRECT_URL")) {
                    HStack {
                        Text(redirectUrl)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = redirectUrl
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle(isEditing ? "EDIT_IDENTITY_PROVIDER" : "NEW_IDENTITY_PROVIDER")
        .onAppear {
            if let id = idpId { self.load(id: id) }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") { self.save() }
                    .disabled(!validForm || isSaving)
            }
        }
    }

    private func load(id: Int) {
        IdentityProvidersRequest.get(id: id) { success, detail in
            guard success, let detail = detail else { return }
            self.name = detail.idp.name
            self.autoProvision = detail.idp.autoProvision ?? false
            self.redirectUrl = detail.redirectUrl
            if let config = detail.idpOidcConfig {
                self.variant = config.variant ?? "oidc"
                self.clientId = config.clientId
                self.clientSecret = config.clientSecret
                self.authUrl = config.authUrl
                self.tokenUrl = config.tokenUrl
                self.scopes = config.scopes
                self.identifierPath = config.identifierPath
                self.emailPath = config.emailPath ?? ""
                self.namePath = config.namePath ?? ""
            }
        }
    }

    private func save() {
        errorMessage = ""
        isSaving = true
        if let id = idpId {
            IdentityProvidersRequest.update(
                id: id,
                name: name,
                clientId: clientId,
                clientSecret: clientSecret,
                authUrl: authUrl,
                tokenUrl: tokenUrl,
                scopes: scopes,
                identifierPath: identifierPath,
                emailPath: emailPath,
                namePath: namePath,
                autoProvision: autoProvision
            ) { success, response in
                isSaving = false
                if success {
                    onSaved()
                    dismiss()
                } else {
                    errorMessage = response?.message ?? ""
                }
            }
        } else {
            IdentityProvidersRequest.create(
                name: name,
                clientId: clientId,
                clientSecret: clientSecret,
                authUrl: authUrl,
                tokenUrl: tokenUrl,
                scopes: scopes,
                identifierPath: identifierPath,
                emailPath: emailPath,
                namePath: namePath,
                autoProvision: autoProvision,
                variant: variant
            ) { success, response in
                isSaving = false
                if success {
                    onSaved()
                    dismiss()
                } else {
                    errorMessage = response?.message ?? ""
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        IdentityProviderView(idpId: nil) {}
    }
}

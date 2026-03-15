//
//  IdentityProvidersView.swift
//  Pango
//

import SwiftUI

struct IdentityProvidersView: View {

    @State private var idps: [IdentityProvider] = []
    @State private var isLoading: Bool = false

    var body: some View {
        List {
            ForEach(idps, id: \.idpId) { idp in
                NavigationLink {
                    IdentityProviderDetailView(idp: idp, onUpdate: { Task { await fetch() } })
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(idp.name ?? "Unnamed")
                                .fontWeight(.semibold)
                            Text(idp.displayType)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusIconView(online: idp.enabled ?? false)
                    }
                }
            }
        }
        .navigationTitle("IDENTITY_PROVIDERS")
        .task {
            await fetch()
        }
        .refreshable {
            await fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    IdentityProviderCreateView(onSave: { Task { await fetch() } })
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if !isLoading && idps.isEmpty {
                ContentUnavailableView("NO_IDENTITY_PROVIDERS", systemImage: "person.badge.key")
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            idps = try await IdentityProvidersRequest.fetch()
        } catch {
            // IDP operation failed
        }
        isLoading = false
    }
}

struct IdentityProviderDetailView: View {

    var idp: IdentityProvider
    var onUpdate: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var enabled: Bool = true
    @State private var autoProvision: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Form {
            Section(header: Text("DETAILS")) {
                HStack {
                    Text("TYPE")
                    Spacer()
                    Text(idp.displayType)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("NAME")
                    TextField("NAME", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                Toggle("ENABLED", isOn: $enabled)
                Toggle("AUTO_PROVISION", isOn: $autoProvision)
            }

            if let clientId = idp.clientId {
                Section(header: Text("CONFIGURATION")) {
                    HStack {
                        Text("CLIENT_ID")
                        Spacer()
                        Text(clientId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let issuer = idp.issuerUrl {
                        HStack {
                            Text("ISSUER_URL")
                            Spacer()
                            Text(issuer)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Section {
                Button("DELETE", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .confirmationDialog(
                    "DELETE_IDP_CONFIRMATION",
                    isPresented: $showDeleteConfirmation
                ) {
                    Button("DELETE", role: .destructive) {
                        Task { await deleteIdp() }
                    }
                    Button("CANCEL", role: .cancel) {}
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(Color(.systemRed))
                    .font(.subheadline)
            }
        }
        .navigationTitle(idp.name ?? "IDP")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = idp.name ?? ""
            enabled = idp.enabled ?? true
            autoProvision = idp.autoProvision ?? false
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    Task { await save() }
                }
            }
        }
    }

    private func save() async {
        errorMessage = ""
        do {
            _ = try await IdentityProvidersRequest.update(
                idpId: idp.idpId,
                name: name,
                enabled: enabled,
                autoProvision: autoProvision
            )
            hapticSuccess()
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteIdp() async {
        do {
            _ = try await IdentityProvidersRequest.delete(idpId: idp.idpId)
            hapticSuccess()
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct IdentityProviderCreateView: View {

    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var type: String = "oidc"
    @State private var clientId: String = ""
    @State private var clientSecret: String = ""
    @State private var issuerUrl: String = ""
    @State private var autoProvision: Bool = false
    @State private var errorMessage: String = ""

    let typeOptions = ["oidc", "azure", "google", "pocketid", "zitadel"]

    var validForm: Bool {
        !name.isEmpty && !clientId.isEmpty && !clientSecret.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)

                Picker("TYPE", selection: $type) {
                    ForEach(typeOptions, id: \.self) { option in
                        Text(IdentityProvider.displayName(for: option)).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(header: Text("CREDENTIALS")) {
                TextField("CLIENT_ID", text: $clientId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("CLIENT_SECRET", text: $clientSecret)
            }

            Section(header: Text("ENDPOINTS")) {
                TextField("ISSUER_URL", text: $issuerUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }

            Section {
                Toggle("AUTO_PROVISION", isOn: $autoProvision)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(Color(.systemRed))
                    .font(.subheadline)
            }
        }
        .navigationTitle("ADD_IDENTITY_PROVIDER")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    Task { await save() }
                }
                .disabled(!validForm)
            }
        }
    }

    private func save() async {
        errorMessage = ""
        do {
            let success = try await IdentityProvidersRequest.create(
                name: name,
                type: type,
                clientId: clientId,
                clientSecret: clientSecret,
                issuerUrl: issuerUrl.isEmpty ? nil : issuerUrl,
                authUrl: nil,
                tokenUrl: nil,
                autoProvision: autoProvision
            )
            if success {
                onSave()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        IdentityProvidersView()
    }
}

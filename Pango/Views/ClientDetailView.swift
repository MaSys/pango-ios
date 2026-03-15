//
//  ClientDetailView.swift
//  Pango
//

import SwiftUI

struct ClientDetailView: View {

    var client: Client
    var onUpdate: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        List {
            Section(header: Text("DETAILS")) {
                row("NAME", client.name ?? "-")
                row("STATUS", client.displayStatus)
                row("CLIENT_ID", client.clientId)
                if let fingerprint = client.fingerprint {
                    VStack(alignment: .leading) {
                        Text("FINGERPRINT")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(fingerprint)
                            .font(.system(size: 13, design: .monospaced))
                    }
                }
            }

            Section(header: Text("CONNECTION")) {
                row("IP", client.ip ?? "-")
                row("OS", client.os ?? "-")
                row("VERSION", client.version ?? "-")
                row("LAST_SEEN", client.lastSeen ?? "-")
            }

            if let email = client.userEmail {
                Section(header: Text("USER")) {
                    row("EMAIL", email)
                }
            }

            if let siteName = client.siteName {
                Section(header: Text("SITE")) {
                    row("SITE", siteName)
                }
            }

            Section(header: Text("ACTIONS")) {
                if client.approved == false {
                    Button("APPROVE") {
                        Task { await approve() }
                    }
                    .foregroundStyle(.green)
                }

                if client.blocked == true {
                    Button("UNBLOCK") {
                        Task { await unblock() }
                    }
                } else {
                    Button("BLOCK") {
                        Task { await block() }
                    }
                    .foregroundStyle(.orange)
                }

                if client.archived != true {
                    Button("ARCHIVE") {
                        Task { await archive() }
                    }
                    .foregroundStyle(.orange)
                }

                Button("DELETE") {
                    showDeleteConfirmation = true
                }
                .foregroundStyle(.red)
                .confirmationDialog(
                    "DELETE_CLIENT_CONFIRMATION",
                    isPresented: $showDeleteConfirmation
                ) {
                    Button("DELETE", role: .destructive) {
                        Task { await deleteClient() }
                    }
                    Button("CANCEL", role: .cancel) {}
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle(client.name ?? "CLIENT")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(LocalizedStringResource(stringLiteral: label))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    private func approve() async {
        do {
            _ = try await ClientsRequest.approve(clientId: client.clientId)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func block() async {
        do {
            _ = try await ClientsRequest.block(clientId: client.clientId)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func unblock() async {
        do {
            _ = try await ClientsRequest.unblock(clientId: client.clientId)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func archive() async {
        do {
            _ = try await ClientsRequest.archive(clientId: client.clientId)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteClient() async {
        do {
            _ = try await ClientsRequest.delete(clientId: client.clientId)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(client: Client.fake(), onUpdate: {})
    }
}

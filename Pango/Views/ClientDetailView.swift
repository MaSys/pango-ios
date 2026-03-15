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
                DetailRow(label: "NAME", value: client.name ?? "-")
                DetailRow(label: "STATUS", value: client.displayStatus)
                DetailRow(label: "CLIENT_ID", value: client.clientId)
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
                DetailRow(label: "IP", value: client.ip ?? "-")
                DetailRow(label: "OS", value: client.os ?? "-")
                DetailRow(label: "VERSION", value: client.version ?? "-")
                DetailRow(label: "LAST_SEEN", value: client.lastSeen ?? "-")
            }

            if let email = client.userEmail {
                Section(header: Text("USER")) {
                    DetailRow(label: "EMAIL", value: email)
                }
            }

            if let siteName = client.siteName {
                Section(header: Text("SITE")) {
                    DetailRow(label: "SITE", value: siteName)
                }
            }

            Section(header: Text("ACTIONS")) {
                if client.approved == false {
                    Button("APPROVE") {
                        performAction { try await ClientsRequest.approve(clientId: client.clientId) }
                    }
                    .foregroundStyle(.green)
                }

                if client.blocked == true {
                    Button("UNBLOCK") {
                        performAction { try await ClientsRequest.unblock(clientId: client.clientId) }
                    }
                } else {
                    Button("BLOCK") {
                        performAction { try await ClientsRequest.block(clientId: client.clientId) }
                    }
                    .foregroundStyle(.orange)
                }

                if client.archived != true {
                    Button("ARCHIVE") {
                        performAction { try await ClientsRequest.archive(clientId: client.clientId) }
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
                        performAction { try await ClientsRequest.delete(clientId: client.clientId) }
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

    private func performAction(_ action: @escaping () async throws -> Bool) {
        Task {
            do {
                _ = try await action()
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(client: Client.fake(), onUpdate: {})
    }
}

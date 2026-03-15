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
                DetailRow(label: "CLIENT_ID", value: client.clientIdString)
                if let niceId = client.niceId {
                    DetailRow(label: "NICE_ID", value: niceId)
                }
                if let type = client.type {
                    DetailRow(label: "TYPE", value: type)
                }
            }

            Section(header: Text("CONNECTION")) {
                DetailRow(label: "ONLINE", value: client.online == true ? "Yes" : "No")
                if let agent = client.agent {
                    DetailRow(label: "AGENT", value: agent)
                }
                DetailRow(label: "VERSION", value: client.olmVersion ?? "-")
                if let subnet = client.subnet {
                    DetailRow(label: "SUBNET", value: subnet)
                }
            }

            if let email = client.userEmail {
                Section(header: Text("USER")) {
                    DetailRow(label: "EMAIL", value: email)
                    if let username = client.username {
                        DetailRow(label: "USERNAME", value: username)
                    }
                }
            }

            Section(header: Text("ACTIONS")) {
                if client.blocked == true {
                    Button("UNBLOCK") {
                        performAction { try await ClientsRequest.unblock(clientId: client.clientIdString) }
                    }
                } else {
                    Button("BLOCK") {
                        performAction { try await ClientsRequest.block(clientId: client.clientIdString) }
                    }
                    .foregroundStyle(.orange)
                }

                if client.archived == true {
                    Button("UNARCHIVE") {
                        performAction { try await ClientsRequest.unarchive(clientId: client.clientIdString) }
                    }
                } else {
                    Button("ARCHIVE") {
                        performAction { try await ClientsRequest.archive(clientId: client.clientIdString) }
                    }
                    .foregroundStyle(.orange)
                }

                Button("DELETE", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .confirmationDialog(
                    "DELETE_CLIENT_CONFIRMATION",
                    isPresented: $showDeleteConfirmation
                ) {
                    Button("DELETE", role: .destructive) {
                        performAction { try await ClientsRequest.delete(clientId: client.clientIdString) }
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
        .navigationTitle(client.name ?? "CLIENT")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performAction(_ action: @escaping () async throws -> Bool) {
        Task {
            do {
                _ = try await action()
                hapticSuccess()
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

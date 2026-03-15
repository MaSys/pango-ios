//
//  ClientsView.swift
//  Pango
//

import SwiftUI

enum ClientFilter: String, CaseIterable {
    case all = "ALL"
    case active = "ACTIVE"
    case blocked = "BLOCKED"
    case archived = "ARCHIVED"
    case pending = "PENDING"
}

struct ClientsView: View {

    @State private var clients: [Client] = []
    @State private var filter: ClientFilter = .all
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""

    var filteredClients: [Client] {
        var result: [Client]
        switch filter {
        case .all:
            result = clients
        case .active:
            result = clients.filter { $0.isActive }
        case .blocked:
            result = clients.filter { $0.blocked == true }
        case .archived:
            result = clients.filter { $0.archived == true }
        case .pending:
            result = clients.filter { $0.isPending && $0.blocked != true }
        }
        return result
    }

    var body: some View {
        List {
            Section {
                Picker("FILTER", selection: $filter) {
                    ForEach(ClientFilter.allCases, id: \.self) { f in
                        Text(LocalizedStringResource(stringLiteral: f.rawValue))
                            .tag(f)
                    }
                }
                .pickerStyle(.menu)
            }

            if !errorMessage.isEmpty && clients.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(Color(.systemRed))
                        .font(.subheadline)
                }
            }

            Section {
                ForEach(filteredClients, id: \.clientId) { client in
                    NavigationLink {
                        ClientDetailView(client: client, onUpdate: { Task { await fetch() } })
                    } label: {
                        ClientRowView(client: client)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if isLoading && clients.isEmpty {
                ProgressView()
            } else if !isLoading && filteredClients.isEmpty {
                ContentUnavailableView("NO_CLIENTS", systemImage: "laptopcomputer")
            }
        }
        .navigationTitle("CLIENTS")
        .task {
            await fetch()
        }
        .refreshable {
            await fetch()
        }
    }

    private func fetch() async {
        if clients.isEmpty { isLoading = true }
        errorMessage = ""
        do {
            clients = try await ClientsRequest.fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct ClientRowView: View {
    var client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(client.name ?? client.niceId ?? client.clientIdString)
                    .fontWeight(.semibold)
                Spacer()
                StatusIconView(online: client.online ?? false)
            }
            HStack {
                if let agent = client.agent {
                    Text(agent)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let version = client.olmVersion {
                    Text("v\(version)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(client.displayStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let email = client.userEmail {
                Text(email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ClientsView()
    }
}

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
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""

    var filteredClients: [Client] {
        switch filter {
        case .all:
            return clients
        case .active:
            return clients.filter { $0.isActive && $0.approved != false }
        case .blocked:
            return clients.filter { $0.blocked == true }
        case .archived:
            return clients.filter { $0.archived == true }
        case .pending:
            return clients.filter { $0.approved == false && $0.blocked != true }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("FILTER", selection: $filter) {
                ForEach(ClientFilter.allCases, id: \.self) { f in
                    Text(LocalizedStringResource(stringLiteral: f.rawValue))
                        .tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if filteredClients.isEmpty {
                            VStack {
                                Spacer().frame(height: 40)
                                Text("NO_CLIENTS")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(filteredClients, id: \.clientId) { client in
                                NavigationLink {
                                    ClientDetailView(client: client, onUpdate: { Task { await fetch() } })
                                } label: {
                                    ClientRowView(client: client)
                                }
                                .tint(.primary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
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
        isLoading = true
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
                Text(client.name ?? client.clientId)
                    .fontWeight(.semibold)
                Spacer()
                StatusIconView(online: client.isActive)
            }
            HStack {
                if let os = client.os {
                    Text(os)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                if let version = client.version {
                    Text("v\(version)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(client.displayStatus)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            if let ip = client.ip {
                Text(ip)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        ClientsView()
    }
}

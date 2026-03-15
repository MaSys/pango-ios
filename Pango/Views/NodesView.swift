//
//  NodesView.swift
//  Pango
//

import SwiftUI

struct NodesView: View {

    @State private var nodes: [Node] = []
    @State private var isLoading: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var nodeToDelete: Node?

    var body: some View {
        List {
            ForEach(nodes, id: \.nodeId) { node in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(node.name ?? node.nodeId)
                            .fontWeight(.semibold)
                        Spacer()
                        StatusIconView(online: node.online ?? false)
                    }
                    HStack {
                        if let address = node.address {
                            Text(address)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let region = node.region {
                            Text(region)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let version = node.version {
                        Text("v\(version)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        nodeToDelete = node
                        showDeleteConfirmation = true
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("NODES")
        .task {
            await fetch()
        }
        .refreshable {
            await fetch()
        }
        .confirmationDialog(
            "DELETE_NODE_CONFIRMATION",
            isPresented: $showDeleteConfirmation
        ) {
            Button("DELETE", role: .destructive) {
                if let node = nodeToDelete {
                    Task { await deleteNode(node) }
                }
            }
            Button("CANCEL", role: .cancel) {}
        }
        .overlay {
            if !isLoading && nodes.isEmpty {
                ContentUnavailableView("NO_NODES", systemImage: "point.3.connected.trianglepath.dotted")
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            nodes = try await NodesRequest.fetch()
        } catch {}
        isLoading = false
    }

    private func deleteNode(_ node: Node) async {
        do {
            _ = try await NodesRequest.delete(nodeId: node.nodeId)
            await fetch()
        } catch {}
    }
}

#Preview {
    NavigationStack {
        NodesView()
    }
}

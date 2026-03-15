//
//  ResourceShareableLinksView.swift
//  Pango
//

import SwiftUI

struct ResourceShareableLinksView: View {

    var resource: Resource

    @EnvironmentObject var appService: AppService

    @State private var links: [ShareableLink] = []
    @State private var isLoading: Bool = false
    @State private var showCreateSheet: Bool = false

    var body: some View {
        List {
            ForEach(links, id: \.linkId) { link in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(link.linkId.prefix(12) + "...")
                            .font(.system(size: 14, design: .monospaced))
                        Spacer()
                        if link.isExpired {
                            Text("EXPIRED")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                    }
                    HStack {
                        if let uses = link.usageCount, let max = link.maxUses {
                            Text("\(uses)/\(max) uses")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let expires = link.formattedExpiresAt {
                            Text(expires)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await deleteLink(link) }
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    if let url = link.url {
                        ShareLink(item: url) {
                            Label("SHARE", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("SHAREABLE_LINKS")
        .task {
            await fetch()
        }
        .refreshable {
            await fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateShareableLinkView(resource: resource, onSave: { Task { await fetch() } })
        }
        .overlay {
            if !isLoading && links.isEmpty {
                ContentUnavailableView("NO_SHAREABLE_LINKS", systemImage: "link")
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            links = try await ShareableLinksRequest.fetch(resourceId: resource.resourceId)
        } catch {}
        isLoading = false
    }

    private func deleteLink(_ link: ShareableLink) async {
        do {
            _ = try await ShareableLinksRequest.delete(linkId: link.linkId)
            await fetch()
        } catch {}
    }
}

struct CreateShareableLinkView: View {

    var resource: Resource
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var maxUses: String = ""
    @State private var expiresInHours: String = "24"
    @State private var errorMessage: String = ""
    @State private var createdLink: ShareableLink?

    var body: some View {
        NavigationStack {
            Form {
                if let link = createdLink {
                    Section(header: Text("CREATED_LINK")) {
                        if let url = link.url {
                            Text(url)
                                .font(.system(size: 13, design: .monospaced))
                                .textSelection(.enabled)
                            ShareLink(item: url) {
                                Label("SHARE_LINK", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                } else {
                    Section {
                        TextField("MAX_USES_OPTIONAL", text: $maxUses)
                            .keyboardType(.numberPad)
                        TextField("EXPIRES_IN_HOURS", text: $expiresInHours)
                            .keyboardType(.numberPad)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("NEW_LINK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("CLOSE") { dismiss() }
                }
                if createdLink == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("CREATE") {
                            Task { await create() }
                        }
                    }
                }
            }
        }
    }

    private func create() async {
        errorMessage = ""
        do {
            let link = try await ShareableLinksRequest.create(
                resourceId: resource.resourceId,
                maxUses: maxUses.isEmpty ? nil : Int(maxUses),
                expiresInHours: expiresInHours.isEmpty ? nil : Int(expiresInHours)
            )
            if let link = link {
                createdLink = link
                onSave()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ResourceShareableLinksView(resource: Resource.fake())
    }
}

//
//  PrivateResourcesView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct PrivateResourcesView: View {

    @EnvironmentObject var appService: AppService
    @State private var resources: [PrivateResource] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading && resources.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    LazyVStack(spacing: 8) {
                    ForEach(resources, id: \.siteResourceId) { resource in
                        NavigationLink {
                            PrivateResourceView(resource: resource)
                                .environmentObject(appService)
                        } label: {
                            HStack {
                                StatusIconView(online: resource.enabled)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resource.name)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Text(resource.fullDomain ?? resource.aliasAddress ?? resource.destination)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !resource.siteNames.isEmpty {
                                        Text(resource.siteNames.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(resource.mode.uppercased())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2))
                                    .foregroundStyle(.accent)
                                    .clipShape(Capsule())
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                                    .shadow(color: .gray.opacity(0.2), radius: 2, y: 1)
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(Text("PRIVATE_RESOURCES"))
            .task { await self.fetch() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        PrivateResourceCreateView()
                            .environmentObject(appService)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let errorMessage { Text(errorMessage) }
            }
        }
    }

    private func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            resources = try await privateResourceService().listAllResources()
        } catch {
            errorMessage = (error as? PangolinAPIError)?.localizedMessage() ?? PangolinAPIError.transport.localizedMessage()
        }
    }
}

private extension PrivateResourcesView {
    func privateResourceService() throws -> PangolinPrivateResourceService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(
                baseURLString: appService.pangolinServerUrl,
                apiKey: appService.pangolinApiKey
            )
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinPrivateResourceService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: appService.pangolinOrganizationId
        )
    }
}

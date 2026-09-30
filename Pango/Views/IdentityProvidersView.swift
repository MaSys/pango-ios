//
//  IdentityProvidersView.swift
//  Pango
//

import SwiftUI

struct IdentityProvidersView: View {

    @EnvironmentObject var appService: AppService
    @State private var idps: [IdentityProvider] = []

    var body: some View {
        List {
            ForEach(idps, id: \.idpId) { idp in
                NavigationLink {
                    IdentityProviderView(idpId: idp.idpId) { self.fetch() }
                } label: {
                    HStack {
                        Text(idp.name)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(idp.variant.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundStyle(.accent)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        self.delete(idp)
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(Text("IDENTITY_PROVIDERS"))
        .onAppear { self.fetch() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    IdentityProviderView(idpId: nil) { self.fetch() }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func fetch() {
        Task {
            do {
                let service = try identityProviderService()
                idps = try await service.listIdentityProviders()
            } catch {
                idps = []
            }
        }
    }

    private func identityProviderService() throws -> PangolinIdentityProviderService {
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
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
        return PangolinIdentityProviderService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: appService.pangolinOrganizationId
        )
    }

    private func delete(_ idp: IdentityProvider) {
        Task {
            do {
                try await identityProviderService().deleteIdentityProvider(idpId: idp.idpId)
                fetch()
            } catch {
                // Preserve the existing behavior: only refresh after a successful deletion.
            }
        }
    }
}

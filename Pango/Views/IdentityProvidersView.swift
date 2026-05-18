//
//  IdentityProvidersView.swift
//  Pango
//

import SwiftUI

struct IdentityProvidersView: View {

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
        IdentityProvidersRequest.fetch { success, idps in
            self.idps = idps
        }
    }

    private func delete(_ idp: IdentityProvider) {
        IdentityProvidersRequest.delete(id: idp.idpId) { success in
            if success { self.fetch() }
        }
    }
}

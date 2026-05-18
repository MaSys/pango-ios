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

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(resources, id: \.resourceId) { resource in
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
                                    if let alias = resource.alias {
                                        Text(alias)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(resource.type.uppercased())
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
            .navigationTitle(Text("PRIVATE_RESOURCES"))
            .onAppear { self.fetch() }
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
        }
    }

    private func fetch() {
        PrivateResourcesRequest.fetch { success, resources in
            self.resources = resources
        }
    }
}

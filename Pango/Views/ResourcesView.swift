//
//  ResourcesView.swift
//  Pango
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

enum ResourceSort: String {
    case name
    case status
    case protection
}
enum ResourceFilter: String {
    case none
    case enabled
    case disabled
    case protected
    case notProtected
}
enum ResourceSection {
    case `public`
    case `private`
}

struct ResourcesView: View {

    @EnvironmentObject var appService: AppService

    @State private var section: ResourceSection = .public
    @State private var sort: ResourceSort = .name
    @State private var sortDesc: Bool = false
    @State private var filteredBy: ResourceFilter = .none
    @State private var privateResources: [PrivateResource] = []

    var sortedResources: [Resource] {
        switch sort {
        case .name:
            return appService.resources.sorted(by: sortDesc ? { $0.name > $1.name } : { $0.name < $1.name })
        case .status:
            return appService.resources.sorted(by: sortDesc ? { $1.enabled && !$0.enabled } : { $0.enabled && !$1.enabled })
        case .protection:
            return appService.resources.sorted(by: sortDesc ? { $1.protected && !$0.protected } : { $0.protected && !$1.protected })
        }
    }

    var filteredResources: [Resource] {
        switch filteredBy {
        case .none: return sortedResources
        case .enabled: return sortedResources.filter { $0.enabled }
        case .disabled: return sortedResources.filter { !$0.enabled }
        case .protected: return sortedResources.filter { $0.protected }
        case .notProtected: return sortedResources.filter { !$0.protected }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $section) {
                    Text("PUBLIC_RESOURCES").tag(ResourceSection.public)
                    Text("PRIVATE_RESOURCES").tag(ResourceSection.private)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if section == .public {
                    publicContent
                } else {
                    privateContent
                }
            }
            .navigationTitle(Text("RESOURCES"))
            .onAppear { self.fetchAll() }
            .toolbar {
                if section == .public {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack {
                            filterMenu
                            sortMenu
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if section == .public {
                        NavigationLink {
                            ResourcesCreateView()
                        } label: {
                            Image(systemName: "plus")
                        }
                    } else {
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
    }

    private func fetchAll() {
        appService.fetchResources()
        PrivateResourcesRequest.fetch { _, resources in
            self.privateResources = resources
        }
    }
}

extension ResourcesView {
    var publicContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredResources, id: \.resourceId) { resource in
                    ResourceRowView(resource: resource)
                }
            }
            .padding(.vertical, 8)
        }
    }

    var privateContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(privateResources, id: \.resourceId) { resource in
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
    }
}

extension ResourcesView {
    var filterMenu: some View {
        Menu {
            Button {
                self.filteredBy = .none
            } label: {
                HStack {
                    Text("ALL")
                    Spacer()
                    if self.filteredBy == .none {
                        Image(systemName: "checkmark")
                            .tint(Color.accent)
                    }
                }
            }
            Button {
                self.filteredBy = .enabled
            } label: {
                HStack {
                    Text("ENABLED")
                    Spacer()
                    if self.filteredBy == .enabled {
                        Image(systemName: "checkmark")
                            .tint(Color.accent)
                    }
                }
            }
            Button {
                self.filteredBy = .disabled
            } label: {
                HStack {
                    Text("DISABLED")
                    Spacer()
                    if self.filteredBy == .disabled {
                        Image(systemName: "checkmark")
                            .tint(Color.accent)
                    }
                }
            }
            Button {
                self.filteredBy = .protected
            } label: {
                HStack {
                    Text("PROTECTED")
                    Spacer()
                    if self.filteredBy == .protected {
                        Image(systemName: "checkmark")
                            .tint(Color.accent)
                    }
                }
            }
            Button {
                self.filteredBy = .notProtected
            } label: {
                HStack {
                    Text("NOT_PROTECTED")
                    Spacer()
                    if self.filteredBy == .notProtected {
                        Image(systemName: "checkmark")
                            .tint(Color.accent)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
        }
    }//filterMenu
    
    var sortMenu: some View {
        Menu {
            Button {
                if self.sort == .name {
                    self.sortDesc.toggle()
                } else {
                    self.sort = .name
                    self.sortDesc = false
                }
            } label: {
                Text("NAME")
                if self.sort == .name {
                    Image(systemName: self.sortDesc ? "chevron.down" : "chevron.up")
                        .tint(Color.accent)
                }
            }
            Button {
                if self.sort == .status {
                    self.sortDesc.toggle()
                } else {
                    self.sort = .status
                    self.sortDesc = false
                }
            } label: {
                Text("STATUS")
                if self.sort == .status {
                    Image(systemName: self.sortDesc ? "chevron.down" : "chevron.up")
                        .tint(Color.accent)
                }
            }
            Button {
                if self.sort == .protection {
                    self.sortDesc.toggle()
                } else {
                    self.sort = .protection
                    self.sortDesc = false
                }
            } label: {
                Text("PROTECTION")
                if self.sort == .protection {
                    Image(systemName: self.sortDesc ? "chevron.down" : "chevron.up")
                        .tint(Color.accent)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }//sortMenu
}

#Preview {
    AppService.shared.resources.append(Resource.fake())
    AppService.shared.resources.append(Resource.fake())
    return ResourcesView()
        .environmentObject(AppService.shared)
}

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
struct ResourcesView: View {

    @EnvironmentObject var appService: AppService

    @State private var sort: ResourceSort = .name
    @State private var sortDesc: Bool = false
    @State private var filteredBy: ResourceFilter = .none
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false

    var sortedResources: [Resource] {
        switch sort {
        case .name:
            if self.sortDesc {
                return self.appService.resources.sorted(by: { $0.name > $1.name })
            } else {
                return self.appService.resources.sorted(by: { $0.name < $1.name })
            }
        case .status:
            if self.sortDesc {
                return self.appService.resources.sorted(by: { $1.enabled && !$0.enabled })
            } else {
                return self.appService.resources.sorted(by: { $0.enabled && !$1.enabled })
            }
        case .protection:
            if self.sortDesc {
                return self.appService.resources.sorted(by: { $1.protected && !$0.protected })
            } else {
                return self.appService.resources.sorted(by: { $0.protected && !$1.protected })
            }
        }
    }

    var filteredResources: [Resource] {
        var result: [Resource]
        switch filteredBy {
        case .none:
            result = self.sortedResources
        case .enabled:
            result = self.sortedResources.filter({ $0.enabled })
        case .disabled:
            result = self.sortedResources.filter({ !$0.enabled })
        case .protected:
            result = self.sortedResources.filter({ $0.protected })
        case .notProtected:
            result = self.sortedResources.filter({ !$0.protected })
        }
        if searchText.isEmpty {
            return result
        }
        return result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.filteredResources, id: \.resourceId) { resource in
                    ResourceRowView(resource: resource)
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "SEARCH_RESOURCES")
            .navigationTitle(Text("RESOURCES"))
            .overlay {
                if !isLoading && appService.resources.isEmpty {
                    ContentUnavailableView("NO_RESOURCES", systemImage: "point.bottomleft.forward.to.point.topright.filled.scurvepath",
                        description: Text("CREATE_A_RESOURCE_TO_GET_STARTED"))
                }
            }
            .onAppear {
                self.fetch()
            }
            .refreshable {
                await self.appService.fetchResourcesAsync()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        filterMenu

                        sortMenu
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ResourcesCreateView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func fetch() {
        isLoading = true
        Task {
            await self.appService.fetchResourcesAsync()
            isLoading = false
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
    }

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
    }
}

#Preview {
    AppService.shared.resources.append(Resource.fake())
    AppService.shared.resources.append(Resource.fake())
    return ResourcesView()
        .environmentObject(AppService.shared)
}

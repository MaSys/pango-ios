//
//  ResourcesView.swift
//  Pangolinios
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
        switch filteredBy {
        case .none:
            return self.sortedResources
        case .enabled:
            return self.sortedResources.filter({ $0.enabled })
        case .disabled:
            return self.sortedResources.filter({ !$0.enabled })
        case .protected:
            return self.sortedResources.filter({ $0.protected })
        case .notProtected:
            return self.sortedResources.filter({ !$0.protected })
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(self.filteredResources, id: \.resourceId) { resource in
                    ResourceRowView(resource: resource)
                }
            }
            .navigationTitle(Text("RESOURCES"))
            .onAppear {
                self.fetch()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        filterMenu
                        
                        sortMenu
                    }
                }
            }
        }
    }
    
    private func fetch() {
        self.appService.fetchResources()
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

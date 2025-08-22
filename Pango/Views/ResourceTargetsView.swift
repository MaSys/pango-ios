//
//  ResourceTargetsView.swift
//  Pango
//
//  Created by Yaser Almasri on 11/08/25.
//

import SwiftUI

struct ResourceTargetsView: View {
    
    @EnvironmentObject var appService: AppService
    
    var resource: Resource
    
    @State private var targets: [Target] = []
    @State private var schema: String = ""
    @State private var ipAddress: String = ""
    @State private var port: String = ""
    
    var body: some View {
        List {
            ForEach(targets, id: \.targetId) { target in
                NavigationLink {
                    ResourceTargetView(resource: self.resource, target: target)
                } label: {
                    HStack {
                        StatusIconView(online: target.enabled)
                        if target.method == nil {
                            Text("\(target.ip):\(String(target.port))")
                        } else {
                            Text("\(target.method!)://\(target.ip):\(String(target.port))")
                        }
                        Spacer()
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        self.delete(target)
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            }
        }
        .onAppear {
            self.fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ResourceTargetView(resource: self.resource)
                } label: {
                    Image(systemName: "plus")
                }

            }
        }
    }
    
    private func fetch() {
        TargetsRequest.fetch(id: self.resource.resourceId) { success, targets in
            self.targets = targets
        }
    }
    
    private func delete(_ target: Target) {
        TargetsRequest.delete(id: target.targetId) { success, response in
            self.fetch()
        }
    }
}

#Preview {
    ResourceTargetsView(resource: Resource.fake())
}

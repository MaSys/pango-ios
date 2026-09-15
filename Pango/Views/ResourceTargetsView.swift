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
    @State private var targetToDelete: Target?
    @State private var errorKey: String?
    
    var body: some View {
        List {
            ForEach(targets, id: \.targetId) { target in
                NavigationLink {
                    ResourceTargetView(resource: self.resource, target: target)
                } label: {
                    HStack {
                        StatusIconView(online: target.enabled)
                        if let method = target.method {
                            Text("\(method)://\(target.ip):\(String(target.port))")
                        } else {
                            Text("\(target.ip):\(String(target.port))")
                        }
                        Spacer()
                        if let status = target.healthStatus {
                            Text(status)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(status == "healthy" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .foregroundStyle(status == "healthy" ? .green : .red)
                                .clipShape(Capsule())
                        }
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        targetToDelete = target
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("TARGETS")
        .onAppear { Task { await fetch() } }
        .refreshable { await fetch() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ResourceTargetView(resource: self.resource)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog(
            "DELETE_TARGET_CONFIRMATION_MESSAGE",
            isPresented: Binding(
                get: { targetToDelete != nil },
                set: { if !$0 { targetToDelete = nil } }
            )
        ) {
            Button("DELETE", role: .destructive) {
                guard let targetToDelete else { return }
                Task { await delete(targetToDelete) }
            }
            Button("CANCEL", role: .cancel) { targetToDelete = nil }
        }
        .alert("ERROR", isPresented: Binding(
            get: { errorKey != nil },
            set: { if !$0 { errorKey = nil } }
        )) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func fetch() async {
        do {
            targets = try await appService.fetchTargets(resourceId: resource.resourceId)
        } catch let error as PangolinAPIError {
            errorKey = error.localizationKey
        } catch {
            errorKey = "ERROR_CONNECTING_TO_SERVER"
        }
    }
    
    private func delete(_ target: Target) async {
        do {
            try await appService.deleteTarget(targetId: target.targetId)
            targetToDelete = nil
            await fetch()
        } catch let error as PangolinAPIError {
            errorKey = error.localizationKey
        } catch {
            errorKey = "ERROR_CONNECTING_TO_SERVER"
        }
    }
}

#Preview {
    ResourceTargetsView(resource: Resource.fake())
}

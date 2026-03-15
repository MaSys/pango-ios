//
//  ResourceMaintenanceView.swift
//  Pango
//

import SwiftUI

struct ResourceMaintenanceView: View {

    var resource: Resource

    @State private var enabled: Bool = false
    @State private var title: String = ""
    @State private var message: String = ""
    @State private var isLoading: Bool = true
    @State private var didFinishLoading: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Form {
            Section(footer: Text("MAINTENANCE_HINT")) {
                Toggle("MAINTENANCE_MODE", isOn: $enabled)
                    .onChange(of: enabled) { _, _ in
                        guard didFinishLoading else { return }
                        Task { await save() }
                    }
            }

            if enabled {
                Section(header: Text("MAINTENANCE_PAGE")) {
                    TextField("TITLE", text: $title)
                    TextField("MESSAGE", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(Color(.systemRed))
                    .font(.subheadline)
            }
        }
        .navigationTitle("MAINTENANCE")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetch()
        }
        .toolbar {
            if enabled {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("SAVE") {
                        Task { await save() }
                    }
                }
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            if let config = try await MaintenanceRequest.fetch(resourceId: resource.resourceId) {
                enabled = config.enabled ?? false
                title = config.title ?? ""
                message = config.message ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        didFinishLoading = true
    }

    private func save() async {
        errorMessage = ""
        do {
            _ = try await MaintenanceRequest.update(
                resourceId: resource.resourceId,
                enabled: enabled,
                title: title.isEmpty ? nil : title,
                message: message.isEmpty ? nil : message
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ResourceMaintenanceView(resource: Resource.fake())
    }
}

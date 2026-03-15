//
//  ResourceHealthCheckView.swift
//  Pango
//

import SwiftUI

struct ResourceHealthCheckView: View {

    var resource: Resource

    @State private var enabled: Bool = false
    @State private var endpoint: String = "/"
    @State private var interval: String = "30"
    @State private var timeout: String = "5"
    @State private var lastChecked: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = true
    @State private var didFinishLoading: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Form {
            Section {
                Toggle("ENABLED", isOn: $enabled)
                    .onChange(of: enabled) { _, _ in
                        guard didFinishLoading else { return }
                        Task { await save() }
                    }
            }

            if enabled {
                Section(header: Text("CONFIGURATION")) {
                    HStack {
                        Text("ENDPOINT")
                        TextField("/health", text: $endpoint)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Text("INTERVAL_SECONDS")
                        TextField("30", text: $interval)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("TIMEOUT_SECONDS")
                        TextField("5", text: $timeout)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }

                if !status.isEmpty || !lastChecked.isEmpty {
                    Section(header: Text("STATUS")) {
                        if !status.isEmpty {
                            HStack {
                                Text("HEALTH_STATUS")
                                Spacer()
                                Text(status.capitalized)
                                    .foregroundStyle(status == "healthy" ? Color(.systemGreen) : Color(.systemRed))
                            }
                        }
                        if !lastChecked.isEmpty {
                            HStack {
                                Text("LAST_CHECKED")
                                Spacer()
                                Text(lastChecked)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(Color(.systemRed))
                    .font(.subheadline)
            }
        }
        .navigationTitle("HEALTH_CHECK")
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
            if let config = try await HealthCheckConfigRequest.fetch(resourceId: resource.resourceId) {
                enabled = config.enabled ?? false
                endpoint = config.endpoint ?? "/"
                interval = config.interval != nil ? "\(config.interval!)" : "30"
                timeout = config.timeout != nil ? "\(config.timeout!)" : "5"
                lastChecked = config.lastChecked ?? ""
                status = config.status ?? ""
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
            _ = try await HealthCheckConfigRequest.update(
                resourceId: resource.resourceId,
                enabled: enabled,
                endpoint: endpoint.isEmpty ? nil : endpoint,
                interval: Int(interval),
                timeout: Int(timeout)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ResourceHealthCheckView(resource: Resource.fake())
    }
}

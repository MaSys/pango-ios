//
//  HealthChecksView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct HealthChecksView: View {

    @EnvironmentObject var appService: AppService

    @State private var healthChecks: [HealthCheck] = []

    var body: some View {
        List {
            ForEach(healthChecks, id: \.healthCheckId) { check in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(check.name)
                            .fontWeight(.semibold)
                        Spacer()
                        if let status = check.status {
                            Text(status.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(status == "healthy" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .foregroundStyle(status == "healthy" ? .green : .red)
                                .clipShape(Capsule())
                        }
                    }
                    HStack {
                        Text(check.type.uppercased())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%ds interval", check.interval))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let url = check.url {
                        Text(url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        self.delete(check)
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(Text("HEALTH_CHECKS"))
        .onAppear { self.fetch() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    HealthCheckCreateView { self.fetch() }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func fetch() {
        Task {
            do {
                healthChecks = try await healthCheckService().listHealthChecks()
            } catch {
                healthChecks = []
            }
        }
    }

    private func delete(_ check: HealthCheck) {
        Task {
            do {
                try await healthCheckService().deleteHealthCheck(healthCheckId: check.healthCheckId)
                fetch()
            } catch {
                // Preserve the existing behavior: leave the list unchanged on failure.
            }
        }
    }

    private func healthCheckService() throws -> PangolinHealthCheckService {
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
        return PangolinHealthCheckService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: appService.pangolinOrganizationId
        )
    }
}

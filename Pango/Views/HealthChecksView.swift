//
//  HealthChecksView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct HealthChecksView: View {

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
        HealthChecksRequest.fetch { success, checks in
            self.healthChecks = checks
        }
    }

    private func delete(_ check: HealthCheck) {
        HealthChecksRequest.delete(id: check.healthCheckId) { success in
            if success { self.fetch() }
        }
    }
}

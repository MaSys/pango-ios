//
//  LogsView.swift
//  Pango
//

import SwiftUI

struct LogsView: View {

    @State private var logs: [RequestAuditLog] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(logs) { log in
                    NavigationLink {
                        LogDetailView(log: log)
                    } label: {
                        LogRowView(log: log)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if isLoading && logs.isEmpty {
                    ProgressView()
                } else if !errorMessage.isEmpty && logs.isEmpty {
                    ContentUnavailableView("ERROR", systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage))
                } else if !isLoading && logs.isEmpty {
                    ContentUnavailableView("NO_LOGS", systemImage: "doc.text")
                }
            }
            .navigationTitle(Text("LOGS"))
            .task {
                await fetchLogs()
            }
            .refreshable {
                await fetchLogs()
            }
        }
    }

    private func fetchLogs() async {
        if logs.isEmpty { isLoading = true }
        errorMessage = ""
        do {
            logs = try await LogsRequest.fetchRequestLogs()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Row View

struct LogRowView: View {
    var log: RequestAuditLog
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.method ?? "GET")
                    .fontWeight(.semibold)
                    .font(.subheadline.monospaced())
                Text(log.path ?? "/")
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Image(systemName: log.action == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(log.action == true ? Color(.systemGreen) : Color(.systemRed))
            }
            HStack {
                if let actor = log.actor {
                    Text(actor)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(log.formattedTimestamp)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let resource = log.resourceName {
                Text(resource)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LogsView()
}

//
//  LogsView.swift
//  Pango
//

import SwiftUI

enum LogTab: String, CaseIterable {
    case access = "ACCESS"
    case action = "ACTION"
    case request = "REQUEST"
}

struct LogsView: View {

    @State private var selectedTab: LogTab = .access
    @State private var accessLogs: [AccessLog] = []
    @State private var actionLogs: [ActionLog] = []
    @State private var requestLogs: [RequestLog] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("LOG_TYPE", selection: $selectedTab) {
                    ForEach(LogTab.allCases, id: \.self) { tab in
                        Text(LocalizedStringResource(stringLiteral: tab.rawValue))
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if !errorMessage.isEmpty {
                    Spacer()
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                } else {
                    logList
                }
            }
            .navigationTitle(Text("LOGS"))
            .task {
                await fetchLogs()
            }
            .refreshable {
                await fetchLogs()
            }
            .onChange(of: selectedTab) { _, _ in
                Task { await fetchLogs() }
            }
        }
    }

    @ViewBuilder
    var logList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                switch selectedTab {
                case .access:
                    if accessLogs.isEmpty {
                        emptyState("NO_ACCESS_LOGS")
                    } else {
                        ForEach(accessLogs, id: \.id) { log in
                            NavigationLink {
                                AccessLogDetailView(log: log)
                            } label: {
                                AccessLogRowView(log: log)
                            }
                            .tint(.primary)
                        }
                    }
                case .action:
                    if actionLogs.isEmpty {
                        emptyState("NO_ACTION_LOGS")
                    } else {
                        ForEach(actionLogs, id: \.id) { log in
                            NavigationLink {
                                ActionLogDetailView(log: log)
                            } label: {
                                ActionLogRowView(log: log)
                            }
                            .tint(.primary)
                        }
                    }
                case .request:
                    if requestLogs.isEmpty {
                        emptyState("NO_REQUEST_LOGS")
                    } else {
                        ForEach(requestLogs, id: \.id) { log in
                            NavigationLink {
                                RequestLogDetailView(log: log)
                            } label: {
                                RequestLogRowView(log: log)
                            }
                            .tint(.primary)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    func emptyState(_ key: String) -> some View {
        VStack {
            Spacer().frame(height: 40)
            Text(LocalizedStringResource(stringLiteral: key))
                .foregroundStyle(.secondary)
        }
    }

    private func fetchLogs() async {
        isLoading = true
        errorMessage = ""
        do {
            switch selectedTab {
            case .access:
                accessLogs = try await LogsRequest.fetchAccessLogs()
            case .action:
                actionLogs = try await LogsRequest.fetchActionLogs()
            case .request:
                requestLogs = try await LogsRequest.fetchRequestLogs()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Row Views

struct AccessLogRowView: View {
    var log: AccessLog
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.action ?? "Access")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: log.success == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(log.success == true ? .green : .red)
            }
            HStack {
                Text(log.userEmail ?? log.userName ?? "Unknown")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(log.formattedTimestamp)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if let resource = log.resourceName {
                Text(resource)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 2, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}

struct ActionLogRowView: View {
    var log: ActionLog
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.action ?? "Action")
                    .fontWeight(.semibold)
                Spacer()
            }
            HStack {
                Text(log.userEmail ?? log.userName ?? "System")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(log.formattedTimestamp)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if let target = log.target {
                Text(target)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 2, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}

struct RequestLogRowView: View {
    var log: RequestLog
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.method ?? "GET")
                    .fontWeight(.semibold)
                    .font(.system(size: 14, design: .monospaced))
                Text(log.path ?? "/")
                    .font(.system(size: 14))
                    .lineLimit(1)
                Spacer()
                if let code = log.statusCode {
                    Text("\(code)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(code < 400 ? .green : .red)
                }
            }
            HStack {
                if let resource = log.resourceName {
                    Text(resource)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(log.formattedTimestamp)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 2, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}

#Preview {
    LogsView()
}

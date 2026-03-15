//
//  LogDetailView.swift
//  Pango
//

import SwiftUI

struct AccessLogDetailView: View {
    var log: AccessLog

    var body: some View {
        List {
            Section {
                detailRow("ACTION", log.action ?? "-")
                detailRow("STATUS", log.success == true ? "Success" : "Failed")
                detailRow("TIMESTAMP", log.formattedTimestamp)
            }
            Section(header: Text("USER")) {
                detailRow("EMAIL", log.userEmail ?? "-")
                detailRow("NAME", log.userName ?? "-")
                detailRow("USER_ID", log.userId ?? "-")
            }
            Section(header: Text("DETAILS")) {
                detailRow("RESOURCE", log.resourceName ?? "-")
                detailRow("IP", log.ip ?? "-")
                detailRow("COUNTRY", log.country ?? "-")
                if let userAgent = log.userAgent {
                    VStack(alignment: .leading) {
                        Text("USER_AGENT")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(userAgent)
                            .font(.system(size: 13))
                    }
                }
            }
        }
        .navigationTitle("ACCESS_LOG")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActionLogDetailView: View {
    var log: ActionLog

    var body: some View {
        List {
            Section {
                detailRow("ACTION", log.action ?? "-")
                detailRow("TIMESTAMP", log.formattedTimestamp)
            }
            Section(header: Text("USER")) {
                detailRow("EMAIL", log.userEmail ?? "-")
                detailRow("NAME", log.userName ?? "-")
            }
            Section(header: Text("TARGET")) {
                detailRow("TARGET", log.target ?? "-")
                detailRow("TARGET_ID", log.targetId ?? "-")
                if let details = log.details {
                    VStack(alignment: .leading) {
                        Text("DETAILS")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(details)
                            .font(.system(size: 13))
                    }
                }
            }
        }
        .navigationTitle("ACTION_LOG")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RequestLogDetailView: View {
    var log: RequestLog

    var body: some View {
        List {
            Section {
                detailRow("METHOD", log.method ?? "-")
                detailRow("PATH", log.path ?? "-")
                detailRow("STATUS_CODE", log.statusCode != nil ? "\(log.statusCode!)" : "-")
                detailRow("TIMESTAMP", log.formattedTimestamp)
            }
            Section(header: Text("DETAILS")) {
                detailRow("RESOURCE", log.resourceName ?? "-")
                detailRow("IP", log.ip ?? "-")
                detailRow("DECISION", log.decision ?? "-")
                if let duration = log.duration {
                    detailRow("DURATION", "\(duration)ms")
                }
                if let userAgent = log.userAgent {
                    VStack(alignment: .leading) {
                        Text("USER_AGENT")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(userAgent)
                            .font(.system(size: 13))
                    }
                }
            }
        }
        .navigationTitle("REQUEST_LOG")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func detailRow(_ label: String, _ value: String) -> some View {
    HStack {
        Text(LocalizedStringResource(stringLiteral: label))
            .foregroundStyle(.secondary)
        Spacer()
        Text(value)
            .multilineTextAlignment(.trailing)
    }
}

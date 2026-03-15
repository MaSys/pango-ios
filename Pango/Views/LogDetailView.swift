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
                DetailRow(label: "ACTION", value: log.action ?? "-")
                DetailRow(label: "STATUS", value: log.success == true ? "Success" : "Failed")
                DetailRow(label: "TIMESTAMP", value: log.formattedTimestamp)
            }
            Section(header: Text("USER")) {
                DetailRow(label: "EMAIL", value: log.userEmail ?? "-")
                DetailRow(label: "NAME", value: log.userName ?? "-")
                DetailRow(label: "USER_ID", value: log.userId ?? "-")
            }
            Section(header: Text("DETAILS")) {
                DetailRow(label: "RESOURCE", value: log.resourceName ?? "-")
                DetailRow(label: "IP", value: log.ip ?? "-")
                DetailRow(label: "COUNTRY", value: log.country ?? "-")
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
                DetailRow(label: "ACTION", value: log.action ?? "-")
                DetailRow(label: "TIMESTAMP", value: log.formattedTimestamp)
            }
            Section(header: Text("USER")) {
                DetailRow(label: "EMAIL", value: log.userEmail ?? "-")
                DetailRow(label: "NAME", value: log.userName ?? "-")
            }
            Section(header: Text("TARGET")) {
                DetailRow(label: "TARGET", value: log.target ?? "-")
                DetailRow(label: "TARGET_ID", value: log.targetId ?? "-")
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
                DetailRow(label: "METHOD", value: log.method ?? "-")
                DetailRow(label: "PATH", value: log.path ?? "-")
                DetailRow(label: "STATUS_CODE", value: log.statusCode != nil ? "\(log.statusCode!)" : "-")
                DetailRow(label: "TIMESTAMP", value: log.formattedTimestamp)
            }
            Section(header: Text("DETAILS")) {
                DetailRow(label: "RESOURCE", value: log.resourceName ?? "-")
                DetailRow(label: "IP", value: log.ip ?? "-")
                DetailRow(label: "DECISION", value: log.decision ?? "-")
                if let duration = log.duration {
                    DetailRow(label: "DURATION", value: "\(duration)ms")
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

//
//  LogDetailView.swift
//  Pango
//

import SwiftUI

struct LogDetailView: View {
    var log: RequestAuditLog

    var body: some View {
        List {
            Section {
                DetailRow(label: "METHOD", value: log.method ?? "-")
                DetailRow(label: "PATH", value: log.path ?? "-")
                DetailRow(label: "ACTION", value: log.actionString)
                DetailRow(label: "TIMESTAMP", value: log.formattedTimestamp)
            }
            if let host = log.host {
                Section(header: Text("REQUEST")) {
                    DetailRow(label: "HOST", value: host)
                    if let scheme = log.scheme {
                        DetailRow(label: "SCHEME", value: scheme)
                    }
                    if let url = log.originalRequestURL {
                        VStack(alignment: .leading) {
                            Text("URL")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(url)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            Section(header: Text("DETAILS")) {
                if let resource = log.resourceName {
                    DetailRow(label: "RESOURCE", value: resource)
                }
                if let actor = log.actor {
                    DetailRow(label: "ACTOR", value: actor)
                }
                if let actorType = log.actorType {
                    DetailRow(label: "ACTOR_TYPE", value: actorType)
                }
                DetailRow(label: "IP", value: log.ip ?? "-")
                if let location = log.location {
                    DetailRow(label: "LOCATION", value: location)
                }
                if let tls = log.tls {
                    DetailRow(label: "TLS", value: tls ? "Yes" : "No")
                }
                if let userAgent = log.userAgent {
                    VStack(alignment: .leading) {
                        Text("USER_AGENT")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(userAgent)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("LOG_DETAIL")
        .navigationBarTitleDisplayMode(.inline)
    }
}

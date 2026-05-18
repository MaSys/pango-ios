//
//  AlertRulesView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct AlertRulesView: View {

    @State private var alerts: [AlertRule] = []

    var body: some View {
        List {
            ForEach(alerts, id: \.alertId) { alert in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(alert.name)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(alert.notificationMethod.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundStyle(.accent)
                            .clipShape(Capsule())
                    }
                    Text(alert.triggerType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(alert.notificationTarget)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 2)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        self.delete(alert)
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(Text("ALERT_RULES"))
        .onAppear { self.fetch() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AlertRuleCreateView { self.fetch() }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func fetch() {
        AlertRulesRequest.fetch { success, alerts in
            self.alerts = alerts
        }
    }

    private func delete(_ alert: AlertRule) {
        AlertRulesRequest.delete(id: alert.alertId) { success in
            if success { self.fetch() }
        }
    }
}

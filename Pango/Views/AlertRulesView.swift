//
//  AlertRulesView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct AlertRulesView: View {

    @EnvironmentObject var appService: AppService
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
        Task {
            do {
                alerts = try await alertRuleService().listAlertRules()
            } catch {
                alerts = []
            }
        }
    }

    private func alertRuleService() throws -> PangolinAlertRuleService {
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
        return PangolinAlertRuleService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: appService.pangolinOrganizationId
        )
    }

    private func delete(_ alert: AlertRule) {
        Task {
            do {
                try await alertRuleService().deleteAlertRule(alertId: alert.alertId)
                fetch()
            } catch {
                // Preserve the existing behavior: only refresh after a successful deletion.
            }
        }
    }
}

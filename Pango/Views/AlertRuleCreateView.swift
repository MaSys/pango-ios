//
//  AlertRuleCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct AlertRuleCreateView: View {

    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var triggerType: String = "site_down"
    @State private var notificationMethod: String = "email"
    @State private var notificationTarget: String = ""
    @State private var errorMessage: String?

    var validForm: Bool {
        !name.isEmpty && !notificationTarget.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
            }

            Section {
                Picker("TRIGGER_TYPE", selection: $triggerType) {
                    Text("SITE_DOWN").tag("site_down")
                    Text("RESOURCE_DOWN").tag("resource_down")
                    Text("HEALTH_CHECK_FAIL").tag("health_check_fail")
                }.pickerStyle(.menu)
            }

            Section {
                Picker("NOTIFICATION_METHOD", selection: $notificationMethod) {
                    Text("EMAIL").tag("email")
                    Text("WEBHOOK").tag("webhook")
                }.pickerStyle(.segmented)

                TextField(notificationMethod == "email" ? "EMAIL" : "URL", text: $notificationTarget)
                    .keyboardType(notificationMethod == "email" ? .emailAddress : .URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle("NEW_ALERT_RULE")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") { self.save() }
                    .disabled(!validForm)
            }
        }
    }

    private func save() {
        errorMessage = nil
        Task {
            do {
                try await alertRuleService().createAlertRule(
                    name: name,
                    triggerType: triggerType,
                    notificationMethod: notificationMethod,
                    notificationTarget: notificationTarget
                )
                onSaved()
                dismiss()
            } catch let error as PangolinAPIError {
                errorMessage = error.localizedMessage()
            } catch {
                errorMessage = String(localized: "ERROR_CONNECTING_TO_SERVER")
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
}

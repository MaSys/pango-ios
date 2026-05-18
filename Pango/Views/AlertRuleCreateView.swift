//
//  AlertRuleCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct AlertRuleCreateView: View {

    @Environment(\.dismiss) var dismiss

    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var triggerType: String = "site_down"
    @State private var notificationMethod: String = "email"
    @State private var notificationTarget: String = ""
    @State private var errorMessage: String = ""

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

            if !errorMessage.isEmpty {
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
        AlertRulesRequest.create(
            name: name,
            triggerType: triggerType,
            notificationMethod: notificationMethod,
            notificationTarget: notificationTarget
        ) { success, response in
            if success {
                self.onSaved()
                self.dismiss()
            } else {
                self.errorMessage = response?.message ?? ""
            }
        }
    }
}

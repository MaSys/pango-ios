//
//  OrgSecuritySettingsView.swift
//  Pango
//

import SwiftUI

struct OrgSecuritySettingsView: View {

    @State private var mfaRequired: Bool = false
    @State private var sessionLength: String = "24"
    @State private var passwordRotationDays: String = "0"
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""

    var body: some View {
        Form {
            Section(header: Text("MULTI_FACTOR_AUTH")) {
                Toggle("REQUIRE_MFA", isOn: $mfaRequired)
            }

            Section(header: Text("SESSIONS")) {
                HStack {
                    Text("SESSION_LENGTH_HOURS")
                    TextField("24", text: $sessionLength)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
            }

            Section(header: Text("PASSWORD_POLICY"), footer: Text("PASSWORD_ROTATION_HINT")) {
                HStack {
                    Text("ROTATION_DAYS")
                    TextField("0", text: $passwordRotationDays)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle("SECURITY_SETTINGS")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    Task { await save() }
                }
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            if let settings = try await SecuritySettingsRequest.fetchSecuritySettings() {
                mfaRequired = settings.mfaRequired ?? false
                sessionLength = settings.sessionLength != nil ? "\(settings.sessionLength!)" : "24"
                passwordRotationDays = settings.passwordRotationDays != nil ? "\(settings.passwordRotationDays!)" : "0"
            }
        } catch {}
        isLoading = false
    }

    private func save() async {
        errorMessage = ""
        do {
            _ = try await SecuritySettingsRequest.updateSecuritySettings(
                mfaRequired: mfaRequired,
                sessionLength: Int(sessionLength),
                passwordRotationDays: Int(passwordRotationDays)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        OrgSecuritySettingsView()
    }
}

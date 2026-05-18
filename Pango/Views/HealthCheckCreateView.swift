//
//  HealthCheckCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct HealthCheckCreateView: View {

    @Environment(\.dismiss) var dismiss

    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var type: String = "http"
    @State private var targetUrl: String = ""
    @State private var intervalMinutes: Int = 1
    @State private var errorMessage: String = ""

    var validForm: Bool {
        !name.isEmpty && !targetUrl.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
            }

            Section {
                Picker("TYPE", selection: $type) {
                    Text("HTTP").tag("http")
                    Text("TCP").tag("tcp")
                }.pickerStyle(.segmented)
            }

            Section {
                TextField("URL", text: $targetUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
            }

            Section {
                Stepper(value: $intervalMinutes, in: 1...60) {
                    HStack {
                        Text("INTERVAL")
                        Spacer()
                        Text("\(intervalMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle("NEW_HEALTH_CHECK")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") { self.save() }
                    .disabled(!validForm)
            }
        }
    }

    private func save() {
        HealthChecksRequest.create(
            name: name,
            type: type,
            url: targetUrl,
            interval: intervalMinutes * 60
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

//
//  HealthCheckCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct HealthCheckCreateView: View {

    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var type: String = "http"
    @State private var targetUrl: String = ""
    @State private var intervalMinutes: Int = 1
    @State private var errorKey: String?

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

            if let errorKey {
                Text(LocalizedStringKey(errorKey))
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
        errorKey = nil
        Task {
            do {
                try await healthCheckService().createHealthCheck(
                    name: name,
                    type: type,
                    url: targetUrl,
                    interval: intervalMinutes * 60
                )
                onSaved()
                dismiss()
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
            }
        }
    }

    private func healthCheckService() throws -> PangolinHealthCheckService {
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
        return PangolinHealthCheckService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: appService.pangolinOrganizationId
        )
    }
}

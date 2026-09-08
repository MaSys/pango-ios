import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SiteCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appService: AppService
    @State private var name = ""
    @State private var isSaving = false
    @State private var credentials: SiteCredentials?
    @State private var errorKey: String?

    var body: some View {
        NavigationStack {
            Form {
                if let credentials {
                    Section("SITE_CREDENTIALS") {
                        credentialRow(title: "NEWT_ID", value: credentials.id)
                        credentialRow(title: "SECRET", value: credentials.secret)
                    }
                    Section {
                        Text("CREDENTIALS_ONE_TIME_WARNING")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("SITE") {
                        TextField("NAME", text: $name)
                        LabeledContent("TYPE", value: "Newt")
                    }
                }
            }
            .navigationTitle(credentials == nil ? "CREATE_SITE" : "SITE_CREATED")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(credentials == nil ? "CANCEL" : "DONE") { dismiss() }
                }
                if credentials == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("CREATE") { create() }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    }
                }
            }
            .alert("ERROR", isPresented: Binding(
                get: { errorKey != nil },
                set: { if !$0 { errorKey = nil } }
            )) {
                Button("OK", role: .cancel) { errorKey = nil }
            } message: {
                if let errorKey { Text(LocalizedStringKey(errorKey)) }
            }
        }
    }

    private func credentialRow(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.body, design: .monospaced)).textSelection(.enabled)
            Button("COPY") {
                UIPasteboard.general.setItems(
                    [[UTType.plainText.identifier: value]],
                    options: [
                        .localOnly: true,
                        .expirationDate: Date().addingTimeInterval(300)
                    ]
                )
            }
        }
    }

    private func create() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                credentials = try await appService.createNewtSite(name: trimmedName).credentials
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
            }
        }
    }
}

import SwiftUI

struct ClientDetailView: View {
    @EnvironmentObject private var appService: AppService
    let clientId: Int

    @State private var client: PangolinClient?
    @State private var isLoading = false
    @State private var errorKey: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            if let client {
                Section("CLIENT_DETAILS") {
                    if let name = client.name {
                        LabeledContent("NAME", value: name)
                    }
                    LabeledContent("CLIENT_ID", value: String(client.clientId))
                    if let niceId = client.niceId {
                        LabeledContent("NICE_ID", value: niceId)
                    }
                    if let userEmail = client.userEmail {
                        LabeledContent("EMAIL", value: userEmail)
                    }
                    if let subnet = client.subnet {
                        LabeledContent("SUBNET", value: subnet)
                    }
                    LabeledContent("STATUS") {
                        Text(LocalizedStringKey(client.statusKey))
                    }
                    if let online = client.online {
                        LabeledContent("CONNECTION") {
                            Text(LocalizedStringKey(online ? "ONLINE" : "OFFLINE"))
                        }
                    }
                }

                if let fingerprint = client.fingerprint {
                    Section("DEVICE_DETAILS") {
                        if let platform = fingerprint.platform {
                            LabeledContent("PLATFORM", value: platform)
                        }
                        if let osVersion = fingerprint.osVersion {
                            LabeledContent("OS_VERSION", value: osVersion)
                        }
                        if let deviceModel = fingerprint.deviceModel {
                            LabeledContent("DEVICE_MODEL", value: deviceModel)
                        }
                    }
                }
            }
        }
        .navigationTitle("CLIENT_DETAILS")
        .task(id: appService.pangolinOrganizationId) { await fetch() }
        .refreshable { await fetch() }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }

    private func fetch() async {
        client = nil
        isLoading = true
        defer { isLoading = false }
        do {
            client = try await appService.fetchClient(clientId: clientId)
        } catch is CancellationError {
            return
        } catch let error as PangolinAPIError {
            guard !Task.isCancelled else { return }
            errorKey = error.localizationKey
        } catch {
            guard !Task.isCancelled else { return }
            errorKey = "ERROR_API_RESPONSE"
        }
    }
}

import SwiftUI

struct ClientsView: View {
    @EnvironmentObject private var appService: AppService
    @State private var machines: [PangolinClient] = []
    @State private var userDevices: [PangolinClient] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            Section("MACHINE_CLIENTS") {
                ForEach(machines, id: \.clientId) { client in
                    NavigationLink {
                        ClientDetailView(clientId: client.clientId)
                    } label: {
                        clientRow(client)
                    }
                }
            }
            Section("USER_DEVICES") {
                ForEach(userDevices, id: \.clientId) { client in
                    NavigationLink {
                        ClientDetailView(clientId: client.clientId)
                    } label: {
                        clientRow(client)
                    }
                }
            }
        }
        .navigationTitle("CLIENTS")
        .task(id: appService.pangolinOrganizationId) { await fetch() }
        .refreshable { await fetch() }
        .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
    }

    private func clientRow(_ client: PangolinClient) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.name ?? client.niceId ?? String(client.clientId))
                .fontWeight(.semibold)
            if let detail = client.userEmail ?? client.subnet {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(LocalizedStringKey(client.statusKey))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let revision = appService.organizationRevision
            let service = try clientService()
            let machines = try await service.listAllMachines()
            let userDevices = try await service.listAllUserDevices()
            guard revision == appService.organizationRevision else { return }
            self.machines = machines
            self.userDevices = userDevices
        } catch is CancellationError {
            return
        } catch let error as PangolinAPIError {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedMessage()
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = String(localized: "ERROR_API_RESPONSE")
        }
    }
}

private extension ClientsView {
    func clientService() throws -> PangolinClientService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: appService.pangolinServerUrl, apiKey: appService.pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinClientService(client: PangolinAPIClient(configuration: configuration), organizationId: appService.pangolinOrganizationId)
    }
}

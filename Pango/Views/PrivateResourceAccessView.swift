import SwiftUI

struct PrivateResourceAccessView: View {
    @EnvironmentObject private var appService: AppService
    @Environment(\.dismiss) private var dismiss

    let resourceId: Int
    let organizationId: String
    let kind: PrivateResourceAccessKind

    @State private var selection: PrivateResourceAccessSelection?
    @State private var loadedRevision: UUID?
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorKey: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if let selection {
                ForEach(selection.options) { option in
                    Button {
                        self.selection?.toggle(id: option.id)
                    } label: {
                        HStack {
                            Text(option.name)
                            Spacer()
                            if option.isReadOnly {
                                Image(systemName: "lock.fill")
                                    .accessibilityLabel(Text("ADMIN_ROLE_ACCESS_READ_ONLY"))
                            }
                            if selection.selectedIDs.contains(option.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .disabled(option.isReadOnly || isSaving)
                    .accessibilityAddTraits(selection.selectedIDs.contains(option.id) ? .isSelected : [])
                }
                if selection.options.isEmpty {
                    Text("NO_ACCESS_OPTIONS")
                        .foregroundStyle(.secondary)
                }
                if selection.options.contains(where: \.isReadOnly) {
                    Text("ADMIN_ROLE_ACCESS_READ_ONLY")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("RETRY") { Task { await load() } }
            }
        }
        .navigationTitle(LocalizedStringKey(kind.titleKey))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("SAVE") { save() }
                    .disabled(selection == nil || isLoading || isSaving || loadedRevision != appService.organizationRevision)
            }
        }
        .task(id: appService.organizationRevision) { await load() }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }

    private func load() async {
        selection = nil
        loadedRevision = nil
        errorKey = nil
        guard organizationId == appService.pangolinOrganizationId else { return }
        let revision = appService.organizationRevision
        isLoading = true
        defer { isLoading = false }
        do {
            let client = try apiClient()
            let assigned = try await PangolinPrivateResourceAccessService(client: client)
                .listAssignments(resourceId: resourceId, kind: kind)
            let available: [PrivateResourceAccessOption]
            switch kind {
            case .users:
                available = try await appService.fetchUsers().map { .init(id: $0.id, name: $0.email) }
            case .roles:
                available = try await appService.fetchRoles().map {
                    .init(id: String($0.roleId), name: $0.name ?? String($0.roleId), isReadOnly: $0.isAdmin != false)
                }
            case .clients:
                available = try await PangolinClientService(client: client, organizationId: organizationId)
                    .listAllMachines().map { .init(id: String($0.clientId), name: $0.name ?? $0.niceId ?? String($0.clientId)) }
            }
            guard !Task.isCancelled, revision == appService.organizationRevision else { return }
            selection = PrivateResourceAccessSelection(assigned: assigned, available: available)
            loadedRevision = revision
        } catch {
            guard !Task.isCancelled, revision == appService.organizationRevision else { return }
            errorKey = (error as? PangolinAPIError)?.localizationKey ?? PangolinAPIError.transport.localizationKey
        }
    }

    private func save() {
        guard let selection, let loadedRevision, loadedRevision == appService.organizationRevision,
              !isSaving, !isLoading else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                guard loadedRevision == appService.organizationRevision, organizationId == appService.pangolinOrganizationId else { return }
                try await PangolinPrivateResourceAccessService(client: apiClient())
                    .setAssignments(resourceId: resourceId, kind: kind, ids: selection.editableIDs)
                guard loadedRevision == appService.organizationRevision else { return }
                dismiss()
            } catch {
                guard loadedRevision == appService.organizationRevision else { return }
                errorKey = (error as? PangolinAPIError)?.localizationKey ?? PangolinAPIError.transport.localizationKey
            }
        }
    }

    private func apiClient() throws -> PangolinAPIClient {
        do {
            return PangolinAPIClient(configuration: try PangolinAPIConfiguration(
                baseURLString: appService.pangolinServerUrl, apiKey: appService.pangolinApiKey
            ))
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
    }
}

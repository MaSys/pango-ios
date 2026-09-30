import SwiftUI

struct SiteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appService: AppService
    @State private var site: Site
    @State private var name: String
    @State private var isSaving = false
    @State private var confirmsDeletion = false
    @State private var errorMessage: String?

    init(site: Site) {
        self._site = State(initialValue: site)
        self._name = State(initialValue: site.name)
    }

    var body: some View {
        Form {
            Section("SITE") {
                TextField("NAME", text: $name)
                LabeledContent("TYPE", value: site.type.capitalized)
                LabeledContent("STATUS", value: site.status?.capitalized ?? (site.online == true ? "Online" : "Offline"))
                if let niceId = site.niceId {
                    LabeledContent("SITE_ID", value: niceId)
                }
                if let resourceCount = site.resourceCount {
                    LabeledContent("RESOURCES", value: String(resourceCount))
                }
            }
            Section {
                Button("SAVE") { rename() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name == site.name || isSaving)
            }
            Section {
                Button("DELETE_SITE", role: .destructive) { confirmsDeletion = true }
                    .disabled(isSaving)
            } footer: {
                Text("DELETE_SITE_RESOURCE_WARNING")
            }
        }
        .navigationTitle(site.name)
        .task { await refresh() }
        .confirmationDialog("DELETE_SITE_CONFIRMATION", isPresented: $confirmsDeletion, titleVisibility: .visible) {
            Button("DELETE", role: .destructive) { delete() }
            Button("CANCEL", role: .cancel) {}
        }
        .alert("ERROR", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
    }

    private func refresh() async {
        do {
            site = try await siteService().getSite(siteId: site.siteId)
            name = site.name
        } catch let error as PangolinAPIError {
            errorMessage = error.localizedMessage()
        } catch {
            errorMessage = String(localized: "ERROR_CONNECTING_TO_SERVER")
        }
    }

    private func rename() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let revision = appService.organizationRevision
                let updated = try await siteService().renameSite(siteId: site.siteId, name: trimmedName)
                guard revision == appService.organizationRevision else { return }
                site = updated
                if let index = appService.sites.firstIndex(where: { $0.siteId == site.siteId }) {
                    appService.sites[index] = updated
                }
                name = site.name
            } catch let error as PangolinAPIError {
                errorMessage = error.localizedMessage()
            } catch {
                errorMessage = String(localized: "ERROR_CONNECTING_TO_SERVER")
            }
        }
    }

    private func delete() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let revision = appService.organizationRevision
                try await siteService().deleteSite(siteId: site.siteId)
                guard revision == appService.organizationRevision else { return }
                appService.sites.removeAll { $0.siteId == site.siteId }
                dismiss()
            } catch let error as PangolinAPIError {
                errorMessage = error.localizedMessage()
            } catch {
                errorMessage = String(localized: "ERROR_CONNECTING_TO_SERVER")
            }
        }
    }
}

private extension SiteDetailView {
    func siteService() throws -> PangolinSiteService {
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
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinSiteService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: appService.pangolinOrganizationId
        )
    }
}

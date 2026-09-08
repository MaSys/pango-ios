import SwiftUI

struct SiteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appService: AppService
    @State private var site: Site
    @State private var name: String
    @State private var isSaving = false
    @State private var confirmsDeletion = false
    @State private var errorKey: String?

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
            get: { errorKey != nil },
            set: { if !$0 { errorKey = nil } }
        )) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }

    private func refresh() async {
        do {
            site = try await appService.getSite(siteId: site.siteId)
            name = site.name
        } catch let error as PangolinAPIError {
            errorKey = error.localizationKey
        } catch {
            errorKey = "ERROR_CONNECTING_TO_SERVER"
        }
    }

    private func rename() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                site = try await appService.renameSite(siteId: site.siteId, name: trimmedName)
                name = site.name
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
            }
        }
    }

    private func delete() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await appService.deleteSite(siteId: site.siteId)
                dismiss()
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
            }
        }
    }
}

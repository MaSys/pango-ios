import SwiftUI

struct PrivateResourceSitesSection: View {
    @EnvironmentObject private var appService: AppService
    @Binding var selection: PrivateResourceSiteSelection
    var existingNames: [Int: String] = [:]

    @State private var isLoading = false
    @State private var errorKey: String?

    var body: some View {
        Section("SITES") {
            ForEach(selection.options(available: appService.sites, names: existingNames)) { option in
                Button {
                    selection.toggle(option.id)
                } label: {
                    HStack {
                        Text(option.name)
                        Spacer()
                        if selection.siteIds.contains(option.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .accessibilityAddTraits(selection.siteIds.contains(option.id) ? .isSelected : [])
            }
            if isLoading {
                ProgressView()
            }
            Text("SELECT_AT_LEAST_ONE_SITE")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let errorKey {
                Text(LocalizedStringKey(errorKey))
                    .foregroundStyle(.red)
                Button("RETRY") { Task { await fetch() } }
                    .disabled(isLoading)
            }
        }
        .task(id: appService.organizationRevision) { await fetch() }
    }

    private func fetch() async {
        let revision = appService.organizationRevision
        isLoading = true
        errorKey = nil
        defer { isLoading = false }
        do {
            _ = try await appService.fetchSites()
        } catch {
            guard !Task.isCancelled, revision == appService.organizationRevision else { return }
            errorKey = (error as? PangolinAPIError)?.localizationKey ?? PangolinAPIError.transport.localizationKey
        }
    }
}

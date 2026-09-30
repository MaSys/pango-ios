//
//  SitesView.swift
//  Pango
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

enum SiteSegment {
    case all
    case pending
}

struct SitesView: View {

    @EnvironmentObject var appService: AppService
    @State private var selectedSegment: SiteSegment = .all
    @State private var errorMessage: String?

    var pendingSites: [Site] { appService.sites.filter { $0.status == "pending" || $0.pending == true } }
    var activeSites: [Site] { appService.sites.filter { $0.status != "pending" && $0.pending != true } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedSegment) {
                    Text("ALL").tag(SiteSegment.all)
                    Text("PENDING").tag(SiteSegment.pending)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if selectedSegment == .all {
                    allSitesView
                } else {
                    pendingSitesView
                }
            }
            .navigationTitle(Text("SITES"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SiteCreateView()
                            .environmentObject(appService)
                    } label: {
                        Label("CREATE_SITE", systemImage: "plus")
                    }
                }
            }
            .alert("ERROR", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let errorMessage { Text(errorMessage) }
            }
            .task { await fetch() }
            .refreshable { await fetch() }
        }
    }

    private func fetch() async {
        do {
            _ = try await appService.fetchSites()
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = (error as? PangolinAPIError)?.localizedMessage() ?? PangolinAPIError.transport.localizedMessage()
        }
    }
}

extension SitesView {
    var allSitesView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(activeSites, id: \.siteId) { site in
                    NavigationLink {
                        SiteDetailView(site: site)
                            .environmentObject(appService)
                    } label: {
                        siteCard(site)
                    }
                    .buttonStyle(.plain)
                }//loop
            }//lazystack
            .padding(.vertical, 8)
        }//scrollview
    }

    var pendingSitesView: some View {
        List {
            ForEach(pendingSites, id: \.siteId) { site in
                VStack(alignment: .leading, spacing: 4) {
                    Text(site.name)
                        .fontWeight(.semibold)
                    Text(site.type.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        self.reject(site)
                    } label: {
                        Label("REJECT", systemImage: "xmark.circle")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        self.approve(site)
                    } label: {
                        Label("APPROVE", systemImage: "checkmark.circle")
                    }
                    .tint(.green)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if pendingSites.isEmpty {
                ContentUnavailableView("NO_PENDING_SITES", systemImage: "checkmark.circle")
            }
        }
    }

    func siteCard(_ site: Site) -> some View {
        VStack {
            HStack {
                Text(site.name)
                    .fontWeight(.semibold)
                Spacer()
                if let uptime = site.uptimePercent {
                    Text(String(format: "%.1f%%", uptime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                StatusIconView(online: site.online ?? false)
            }//HStack
            HStack {
                SiteUsageView(site: site)
                Spacer()
                NewtView(site: site)
            }
        }//VStack
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 2, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func approve(_ site: Site) {
        Task {
            do {
                try await siteService().approveSite(siteId: site.siteId)
                await fetch()
            } catch {
                // Preserve the existing behavior: only refresh after a successful action.
            }
        }
    }

    private func reject(_ site: Site) {
        Task {
            do {
                try await siteService().rejectSite(siteId: site.siteId)
                await fetch()
            } catch {
                // Preserve the existing behavior: only refresh after a successful action.
            }
        }
    }
}

#Preview {
    SitesView()
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

private extension SitesView {
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

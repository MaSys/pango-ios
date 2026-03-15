//
//  SitesView.swift
//  Pango
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI
import Alamofire

struct SitesView: View {

    @EnvironmentObject var appService: AppService
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.appService.sites, id: \.siteId) { site in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(site.name)
                                .fontWeight(.semibold)
                            Spacer()
                            StatusIconView(online: site.online)
                        }
                        HStack {
                            SiteUsageView(site: site)
                            Spacer()
                            NewtView(site: site)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("SITES"))
            .overlay {
                if !isLoading && appService.sites.isEmpty {
                    ContentUnavailableView("NO_SITES", systemImage: "server.rack",
                        description: Text("CONNECT_SITE_TO_GET_STARTED"))
                }
            }
            .onAppear {
                self.fetch()
            }
            .refreshable {
                await self.appService.fetchSitesAsync()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AnalyticsView(sites: appService.sites)
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                    .accessibilityLabel("Analytics")
                }
            }
        }
    }

    private func fetch() {
        isLoading = true
        self.appService.fetchSites { _, _ in
            isLoading = false
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

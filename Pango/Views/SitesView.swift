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

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(self.appService.sites, id: \.siteId) { site in
                        VStack {
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
                        .cardStyle(verticalPadding: 4)
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle(Text("SITES"))
            .onAppear {
                self.fetch()
            }
            .refreshable {
                await self.appService.fetchSitesAsync()
            }
        }
    }

    private func fetch() {
        self.appService.fetchSites { _, _ in }
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

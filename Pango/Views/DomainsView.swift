//
//  DomainsView.swift
//  Pango
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

struct DomainsView: View {

    @EnvironmentObject var appService: AppService
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.appService.domains, id: \.domainId) { domain in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(domain.baseDomain)
                            .fontWeight(.semibold)
                        HStack {
                            Text(domain.type.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(domain.verified == true ? "VERIFIED" : "UNVERIFIED")
                                .font(.caption)
                                .foregroundStyle(domain.verified == true ? Color(.systemGreen) : Color(.systemRed))
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("DOMAINS"))
            .overlay {
                if !isLoading && appService.domains.isEmpty {
                    ContentUnavailableView("NO_DOMAINS", systemImage: "globe",
                        description: Text("ADD_A_DOMAIN_TO_GET_STARTED"))
                }
            }
            .refreshable {
                await self.appService.fetchDomainsAsync()
            }
        }
        .task {
            isLoading = true
            await self.appService.fetchDomainsAsync()
            isLoading = false
        }
    }
}

#Preview {
    DomainsView()
}

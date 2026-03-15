//
//  DomainsView.swift
//  Pango
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI

struct DomainsView: View {

    @EnvironmentObject var appService: AppService

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(self.appService.domains, id: \.domainId) { domain in
                        VStack {
                            HStack {
                                Text(domain.baseDomain)
                                    .fontWeight(.semibold)
                                Spacer()
                            }

                            HStack {
                                Text(domain.type.capitalized)
                                    .font(.system(size: 14))
                                Spacer()
                                Text(domain.verified == true ? "VERIFIED" : "UNVERIFIED")
                                    .font(.system(size: 14))
                                    .foregroundStyle(domain.verified == true ? .green : .red)
                            }
                            .padding(.top, 5)
                        }
                        .cardStyle(verticalPadding: 4)
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle(Text("DOMAINS"))
            .refreshable {
                await self.appService.fetchDomainsAsync()
            }
        }
        .onAppear {
            self.appService.fetchDomains()
        }
    }
}

#Preview {
    DomainsView()
}

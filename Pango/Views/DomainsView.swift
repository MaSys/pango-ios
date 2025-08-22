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
            List {
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
                            Text(domain.verified ? "VERIFIED" : "UNVERIFIED")
                                .font(.system(size: 14))
                                .foregroundStyle(domain.verified ? .green : .red)
                        }
                        .padding(.top, 5)
                    }
                    
                }
            }
            .navigationTitle(Text("DOMAINS"))
        }
        .onAppear {
            self.appService.fetchDomains()
        }
    }
}

#Preview {
    DomainsView()
}

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
                        }//vstack
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                                .shadow(color: .gray.opacity(0.2), radius: 2, y: 1)
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }//loop
                }//lazy
                .padding(.vertical, 8)
            }//scrollview
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

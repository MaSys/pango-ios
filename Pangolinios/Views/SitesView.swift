//
//  SitesView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 03/08/25.
//

import SwiftUI
import Alamofire

struct SitesView: View {
    
    @EnvironmentObject var appService: AppService
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(self.appService.sites, id: \.siteId) { site in
                    VStack {
                        HStack {
                            Text(site.name)
                            Spacer()
                            StatusIconView(online: site.online)
                        }//HStack
                        HStack {
                            SiteUsageView(site: site)
                            Spacer()
                            NewtView(site: site)
                        }
                    }//VStack
                }
            }
            .navigationTitle(Text("SITES"))
            .onAppear {
                self.fetch()
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

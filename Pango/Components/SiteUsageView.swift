//
//  SiteUsageView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

struct SiteUsageView: View {
    
    var site: Site
    
    var body: some View {
        Group {
            Text("\(String(format: "%.2f", site.megabytesIn)) MB In")
                .font(.system(size: 14))
            Text("\(String(format: "%.2f", site.megabytesOut)) MB Out")
                .font(.system(size: 14))
        }
    }
}

#Preview {
//    SiteUsageView()
}

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
            HStack {
                Text(humanMegabyte(from: site.megabytesIn))
                    .font(.system(size: 14))
                Image(systemName: "arrowshape.up.fill")
                    .resizable()
                    .frame(width: 11, height: 11)
                    .foregroundStyle(.red)
            }
            
            HStack {
                Text(humanMegabyte(from: site.megabytesOut))
                    .font(.system(size: 14))
                Image(systemName: "arrowshape.down.fill")
                    .resizable()
                    .frame(width: 11, height: 11)
                    .foregroundStyle(.green)
            }
        }
    }
}

#Preview {
    SiteUsageView(site: Site.fake())
}

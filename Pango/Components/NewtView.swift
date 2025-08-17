//
//  NewtView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

struct NewtView: View {
    
    var site: Site
    
    var body: some View {
        Group {
            HStack {
                Text(site.type.capitalized)
                    .font(.system(size: 14))
                if let version = site.newtVersion {
                    Text("v\(version)")
                        .foregroundStyle(.gray)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
        }
        .background(Color.init(uiColor: UIColor(white: 0.8, alpha: 0.3)))
        .cornerRadius(15)
    }
}

#Preview {
    NewtView(site: Site.fake())
}

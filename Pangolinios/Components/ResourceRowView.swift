//
//  ResourceRowView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 05/08/25.
//

import SwiftUI

struct ResourceRowView: View {
    
    var resource: Resource
    
    var body: some View {
        NavigationLink {
            ResourceView(resource: self.resource)
        } label: {
            VStack {
                HStack {
                    ShieldView(resource: resource)
                    Text(resource.name)
                        .fontWeight(.bold)
                    Spacer()
                    Text(resource.protocolString.uppercased())
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                    StatusIconView(online: resource.enabled)
                }//HStack
                HStack {
                    Text(fullURL(from: resource.fullDomain, ssl: resource.ssl))
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(resource.siteName ?? "")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }//HStack
                .padding(.leading, 30)
            }//VStack
        }
    }
}

#Preview {
    ResourceRowView(resource: Resource.fake())
}

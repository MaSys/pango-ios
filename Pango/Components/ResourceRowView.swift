//
//  ResourceRowView.swift
//  Pango
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
                        .fontWeight(.semibold)
                    Spacer()
                    Text(resource.protocolString.uppercased())
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    StatusIconView(online: resource.enabled)
                }//HStack
                HStack {
                    if self.resource.http {
                        Text(fullURL(from: resource.fullDomain!, ssl: resource.ssl))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(self.resource.proxyPort ?? 0))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }//HStack
            }//VStack
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                    .shadow(color: .gray.opacity(0.2), radius: 2, y: 1)
            )
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .tint(.primary)
    }
}

#Preview {
    ResourceRowView(resource: Resource.fake())
}

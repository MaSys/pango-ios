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
                    if resource.resourceType == .privateResource {
                        Text("PRIVATE")
                            .font(.system(size: 14))
                            .foregroundStyle(.purple)
                    } else {
                        Text(resource.protocolString.uppercased())
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    StatusIconView(online: resource.enabled)
                }
                HStack {
                    if resource.resourceType == .privateResource {
                        Text(resource.host ?? resource.cidr ?? "Private")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    } else if self.resource.http {
                        Text(fullURL(from: resource.fullDomain ?? "", ssl: resource.ssl))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(self.resource.proxyPort ?? 0))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .cardStyle(verticalPadding: 4)
        }
        .tint(.primary)
    }
}

#Preview {
    ResourceRowView(resource: Resource.fake())
}

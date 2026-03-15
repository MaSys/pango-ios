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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    ShieldView(resource: resource)
                    Text(resource.name)
                        .fontWeight(.semibold)
                    Spacer()
                    if resource.resourceType == .privateResource {
                        Text("PRIVATE")
                            .font(.caption)
                            .foregroundStyle(.indigo)
                    } else {
                        Text(resource.protocolString.uppercased())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    StatusIconView(online: resource.enabled)
                }
                HStack {
                    if resource.resourceType == .privateResource {
                        Text(resource.host ?? resource.cidr ?? "Private")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if self.resource.http {
                        Text(fullURL(from: resource.fullDomain ?? "", ssl: resource.ssl))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(self.resource.proxyPort ?? 0))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ResourceRowView(resource: Resource.fake())
}

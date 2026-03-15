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
                    .font(.caption)
                if let version = site.newtVersion {
                    Text("v\(version)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
        }
        .background(Color(.quaternarySystemFill))
        .cornerRadius(15)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NewtView(site: Site.fake())
}

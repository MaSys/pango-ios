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
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(humanMegabyte(from: site.megabytesIn ?? 0))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Upload: \(humanMegabyte(from: site.megabytesIn ?? 0))")

            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(humanMegabyte(from: site.megabytesOut ?? 0))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Download: \(humanMegabyte(from: site.megabytesOut ?? 0))")
        }
    }
}

#Preview {
    SiteUsageView(site: Site.fake())
}

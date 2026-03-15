//
//  ASNBlockingView.swift
//  Pango
//

import SwiftUI

struct ASNBlockingView: View {
    var body: some View {
        BlockingListView(
            title: "ASN_BLOCKING",
            itemLabel: "ASN_LIST",
            hintText: "ASN_BLOCKING_HINT",
            inputPlaceholder: "ASN_NUMBER",
            keyboardType: .numberPad,
            autoCapitalization: .never,
            fetchData: {
                let config = try await SecuritySettingsRequest.fetchASNBlocking()
                return (
                    enabled: config?.enabled ?? false,
                    items: config?.asns ?? [],
                    mode: config?.mode ?? "block"
                )
            },
            saveData: { enabled, asns, mode in
                try await SecuritySettingsRequest.updateASNBlocking(
                    enabled: enabled, asns: asns, mode: mode
                )
            }
        )
    }
}

#Preview {
    NavigationStack {
        ASNBlockingView()
    }
}

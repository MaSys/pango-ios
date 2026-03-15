//
//  GeoBlockingView.swift
//  Pango
//

import SwiftUI

struct GeoBlockingView: View {
    var body: some View {
        BlockingListView(
            title: "GEO_BLOCKING",
            itemLabel: "COUNTRIES",
            hintText: "GEO_BLOCKING_HINT",
            inputPlaceholder: "COUNTRY_CODE",
            keyboardType: .default,
            autoCapitalization: .characters,
            fetchData: {
                let config = try await SecuritySettingsRequest.fetchGeoBlocking()
                return (
                    enabled: config?.enabled ?? false,
                    items: config?.countries ?? [],
                    mode: config?.mode ?? "block"
                )
            },
            saveData: { enabled, countries, mode in
                try await SecuritySettingsRequest.updateGeoBlocking(
                    enabled: enabled, countries: countries, mode: mode
                )
            }
        )
    }
}

#Preview {
    NavigationStack {
        GeoBlockingView()
    }
}

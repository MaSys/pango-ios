//
//  GeoBlockingView.swift
//  Pango
//

import SwiftUI

struct GeoBlockingView: View {

    @State private var enabled: Bool = false
    @State private var mode: String = "block"
    @State private var countries: [String] = []
    @State private var newCountry: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""

    var body: some View {
        Form {
            Section {
                Toggle("ENABLED", isOn: $enabled)
                if enabled {
                    Picker("MODE", selection: $mode) {
                        Text("BLOCK").tag("block")
                        Text("ALLOW").tag("allow")
                    }
                    .pickerStyle(.segmented)
                }
            }

            if enabled {
                Section(header: Text("COUNTRIES"), footer: Text("GEO_BLOCKING_HINT")) {
                    ForEach(countries, id: \.self) { country in
                        HStack {
                            Text(country)
                            Spacer()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                countries.removeAll { $0 == country }
                            } label: {
                                Label("REMOVE", systemImage: "trash")
                            }
                        }
                    }

                    HStack {
                        TextField("COUNTRY_CODE", text: $newCountry)
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                        Button {
                            let code = newCountry.trimmingCharacters(in: .whitespaces).uppercased()
                            if !code.isEmpty && !countries.contains(code) {
                                countries.append(code)
                                newCountry = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newCountry.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle("GEO_BLOCKING")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    Task { await save() }
                }
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            if let config = try await SecuritySettingsRequest.fetchGeoBlocking() {
                enabled = config.enabled ?? false
                countries = config.countries ?? []
                mode = config.mode ?? "block"
            }
        } catch {}
        isLoading = false
    }

    private func save() async {
        errorMessage = ""
        do {
            _ = try await SecuritySettingsRequest.updateGeoBlocking(
                enabled: enabled,
                countries: countries,
                mode: mode
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        GeoBlockingView()
    }
}

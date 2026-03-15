//
//  ASNBlockingView.swift
//  Pango
//

import SwiftUI

struct ASNBlockingView: View {

    @State private var enabled: Bool = false
    @State private var mode: String = "block"
    @State private var asns: [String] = []
    @State private var newASN: String = ""
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
                Section(header: Text("ASN_LIST"), footer: Text("ASN_BLOCKING_HINT")) {
                    ForEach(asns, id: \.self) { asn in
                        HStack {
                            Text(asn)
                            Spacer()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                asns.removeAll { $0 == asn }
                            } label: {
                                Label("REMOVE", systemImage: "trash")
                            }
                        }
                    }

                    HStack {
                        TextField("ASN_NUMBER", text: $newASN)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.numberPad)
                        Button {
                            let asn = newASN.trimmingCharacters(in: .whitespaces)
                            if !asn.isEmpty && !asns.contains(asn) {
                                asns.append(asn)
                                newASN = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newASN.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle("ASN_BLOCKING")
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
            if let config = try await SecuritySettingsRequest.fetchASNBlocking() {
                enabled = config.enabled ?? false
                asns = config.asns ?? []
                mode = config.mode ?? "block"
            }
        } catch {}
        isLoading = false
    }

    private func save() async {
        errorMessage = ""
        do {
            _ = try await SecuritySettingsRequest.updateASNBlocking(
                enabled: enabled,
                asns: asns,
                mode: mode
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ASNBlockingView()
    }
}

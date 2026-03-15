//
//  BlockingListView.swift
//  Pango
//

import SwiftUI

struct BlockingListView: View {

    var title: String
    var itemLabel: String
    var hintText: String
    var inputPlaceholder: String
    var keyboardType: UIKeyboardType
    var autoCapitalization: TextInputAutocapitalization
    var fetchData: () async throws -> (enabled: Bool, items: [String], mode: String)
    var saveData: (Bool, [String], String) async throws -> Bool

    @State private var enabled: Bool = false
    @State private var mode: String = "block"
    @State private var items: [String] = []
    @State private var newItem: String = ""
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
                Section(header: Text(LocalizedStringResource(stringLiteral: itemLabel)), footer: Text(LocalizedStringResource(stringLiteral: hintText))) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                items.removeAll { $0 == item }
                            } label: {
                                Label("REMOVE", systemImage: "trash")
                            }
                        }
                    }

                    HStack {
                        TextField(inputPlaceholder, text: $newItem)
                            .textInputAutocapitalization(autoCapitalization)
                            .autocorrectionDisabled()
                            .keyboardType(keyboardType)
                        Button {
                            let value = newItem.trimmingCharacters(in: .whitespaces)
                            let normalized = autoCapitalization == .characters ? value.uppercased() : value
                            if !normalized.isEmpty && !items.contains(normalized) {
                                items.append(normalized)
                                newItem = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle(LocalizedStringResource(stringLiteral: title))
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
            let data = try await fetchData()
            enabled = data.enabled
            items = data.items
            mode = data.mode
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        errorMessage = ""
        do {
            _ = try await saveData(enabled, items, mode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

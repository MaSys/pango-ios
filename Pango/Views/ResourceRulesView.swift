//
//  ResourceRulesView.swift
//  Pango
//

import SwiftUI

struct ResourceRulesView: View {

    var resource: Resource

    @State private var rules: [Rule] = []
    @State private var isLoading: Bool = false

    var body: some View {
        List {
            ForEach(rules, id: \.ruleId) { rule in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(rule.displayAction)
                                .fontWeight(.semibold)
                                .foregroundStyle(ruleActionColor(rule.action))
                            Text(rule.displayMatch)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let value = rule.value {
                            Text(value)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let enabled = rule.enabled {
                        StatusIconView(online: enabled)
                    }
                }
                .accessibilityElement(children: .combine)
                .swipeActions {
                    Button(role: .destructive) {
                        Task { await deleteRule(rule) }
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("RULES")
        .task {
            await fetch()
        }
        .refreshable {
            await fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ResourceRuleCreateView(resource: resource, onSave: { Task { await fetch() } })
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if !isLoading && rules.isEmpty {
                ContentUnavailableView("NO_RULES", systemImage: "shield.slash")
            }
        }
    }

    private func ruleActionColor(_ action: String) -> Color {
        switch action.lowercased() {
        case "allow": return Color(.systemGreen)
        case "deny": return Color(.systemRed)
        case "pass": return .orange
        default: return .primary
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            rules = try await RulesRequest.fetch(resourceId: resource.resourceId)
        } catch {
            // Rule operation failed
        }
        isLoading = false
    }

    private func deleteRule(_ rule: Rule) async {
        do {
            _ = try await RulesRequest.delete(resourceId: resource.resourceId, ruleId: rule.ruleId)
            hapticSuccess()
            await fetch()
        } catch {
            // Rule operation failed
        }
    }
}

struct ResourceRuleCreateView: View {

    var resource: Resource
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var action: String = "allow"
    @State private var match: String = "path"
    @State private var value: String = ""
    @State private var errorMessage: String = ""

    let actionOptions = ["allow", "deny", "pass"]
    let matchOptions = ["path", "country", "cidr", "ip", "asn"]

    var body: some View {
        Form {
            Section {
                Picker("ACTION", selection: $action) {
                    ForEach(actionOptions, id: \.self) { option in
                        Text(option.capitalized).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Picker("MATCH_TYPE", selection: $match) {
                    ForEach(matchOptions, id: \.self) { option in
                        Text(option.uppercased()).tag(option)
                    }
                }
                .pickerStyle(.menu)

                TextField("VALUE", text: $value)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(Color(.systemRed))
                    .font(.subheadline)
            }
        }
        .navigationTitle("NEW_RULE")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    Task { await save() }
                }
                .disabled(value.isEmpty)
            }
        }
    }

    private func save() async {
        errorMessage = ""
        do {
            let success = try await RulesRequest.create(
                resourceId: resource.resourceId,
                action: action,
                match: match,
                value: value
            )
            if success {
                onSave()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ResourceRulesView(resource: Resource.fake())
    }
}

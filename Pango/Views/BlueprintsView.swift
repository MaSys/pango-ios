//
//  BlueprintsView.swift
//  Pango
//

import SwiftUI

struct BlueprintsView: View {

    @State private var blueprints: [Blueprint] = []
    @State private var isLoading: Bool = false

    var body: some View {
        List {
            ForEach(blueprints, id: \.blueprintId) { blueprint in
                NavigationLink {
                    BlueprintDetailView(blueprint: blueprint)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(blueprint.name ?? blueprint.blueprintId)
                            .fontWeight(.semibold)
                        HStack {
                            if let status = blueprint.status {
                                Text(status.capitalized)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let count = blueprint.resourceCount {
                                Text("\(count) resources")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("BLUEPRINTS")
        .task {
            await fetch()
        }
        .refreshable {
            await fetch()
        }
        .overlay {
            if !isLoading && blueprints.isEmpty {
                ContentUnavailableView("NO_BLUEPRINTS", systemImage: "doc.text")
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            blueprints = try await BlueprintsRequest.fetch()
        } catch {
            // Blueprints may not be available on all instances
        }
        isLoading = false
    }
}

struct BlueprintDetailView: View {
    var blueprint: Blueprint

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let status = blueprint.status {
                    HStack {
                        Text("STATUS")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(status.capitalized)
                    }
                    .padding(.horizontal)
                }

                if let lastApplied = blueprint.lastApplied {
                    HStack {
                        Text("LAST_APPLIED")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(lastApplied)
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal)
                }

                if let yaml = blueprint.yaml {
                    VStack(alignment: .leading) {
                        Text("YAML")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(yaml)
                                .font(.system(size: 12, design: .monospaced))
                                .padding()
                                .textSelection(.enabled)
                        }
                        .background(Color(uiColor: UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(blueprint.name ?? "BLUEPRINT")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BlueprintsView()
    }
}

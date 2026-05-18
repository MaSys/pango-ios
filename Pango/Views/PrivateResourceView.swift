//
//  PrivateResourceView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct PrivateResourceView: View {

    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    var resource: PrivateResource

    @State private var name: String = ""
    @State private var icmp: Bool = true
    @State private var ports: String = "all"
    @State private var alias: String = ""
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        List {
            Section {
                TextField("NAME", text: $name)
                if let ip = resource.ip {
                    HStack {
                        Text("IP_HOSTNAME")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ip)
                    }
                }
                if let subnet = resource.subnet {
                    HStack {
                        Text("SUBNET")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(subnet)
                    }
                }
            }

            Section("ALIAS") {
                TextField("ALIAS", text: $alias)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
            }

            Section("PORTS") {
                Picker("PORTS", selection: $ports) {
                    Text("ALLOW_ALL").tag("all")
                    Text("BLOCK_ALL").tag("none")
                    Text("CUSTOM_PORTS").tag("custom")
                }
                .pickerStyle(.segmented)
                if ports == "custom" {
                    TextField("PORTS_PLACEHOLDER", text: $ports)
                        .keyboardType(.asciiCapable)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                }
            }

            Section {
                Toggle("ICMP", isOn: $icmp)
            }

            Section {
                HStack {
                    Spacer()
                    Button("DELETE") {
                        self.showDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
                    .confirmationDialog(
                        "DELETE_RESOURCE_CONFIRMATION_MESSAGE",
                        isPresented: $showDeleteConfirmation
                    ) {
                        Button("DELETE", role: .destructive) { self.delete() }
                        Button("CANCEL", role: .cancel) {}
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle(resource.name)
        .onAppear {
            self.name = resource.name
            self.icmp = resource.icmp ?? true
            self.ports = resource.ports ?? "all"
            self.alias = resource.alias ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") { self.save() }
            }
        }
    }

    private func save() {
        PrivateResourcesRequest.update(
            id: resource.resourceId,
            name: name,
            icmp: icmp,
            ports: ports,
            alias: alias.isEmpty ? nil : alias
        ) { success, _ in }
    }

    private func delete() {
        PrivateResourcesRequest.delete(id: resource.resourceId) { success in
            if success { self.dismiss() }
        }
    }
}

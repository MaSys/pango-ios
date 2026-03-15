//
//  ResourcePrivateConfigView.swift
//  Pango
//

import SwiftUI

struct ResourcePrivateConfigView: View {

    var resource: Resource

    @EnvironmentObject var appService: AppService

    var body: some View {
        List {
            Section(header: Text("PRIVATE_RESOURCE")) {
                if let host = resource.host {
                    HStack {
                        Text("HOST")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(host)
                            .font(.system(size: 14, design: .monospaced))
                    }
                }
                if let cidr = resource.cidr {
                    HStack {
                        Text("CIDR")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(cidr)
                            .font(.system(size: 14, design: .monospaced))
                    }
                }
                if let ports = resource.ports {
                    HStack {
                        Text("PORTS")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ports)
                            .font(.system(size: 14, design: .monospaced))
                    }
                }
            }

            Section(footer: Text("PRIVATE_RESOURCE_HINT")) {
                HStack {
                    Text("PROTOCOL")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(resource.protocolString.uppercased())
                }
                HStack {
                    Text("VISIBILITY")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(resource.enabled ? "ENABLED" : "DISABLED")
                        .foregroundStyle(resource.enabled ? .green : .red)
                }
            }
        }
        .navigationTitle("PRIVATE_CONFIG")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ResourcePrivateConfigView(resource: Resource.fake())
    }
}

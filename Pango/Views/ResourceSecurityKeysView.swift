//
//  ResourceSecurityKeysView.swift
//  Pango
//

import SwiftUI

struct ResourceSecurityKeysView: View {

    var resource: Resource

    @EnvironmentObject var appService: AppService

    var body: some View {
        List {
            Section(footer: Text("SECURITY_KEYS_HINT")) {
                HStack {
                    Text("STATUS")
                    Spacer()
                    if resource.securityKeyId != nil {
                        Text("ENABLED")
                            .foregroundStyle(.green)
                    } else {
                        Text("DISABLED")
                            .foregroundStyle(.gray)
                    }
                }
            }

            Section {
                Text("SECURITY_KEYS_INFO")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("SECURITY_KEYS")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ResourceSecurityKeysView(resource: Resource.fake())
    }
}

//
//  SettingsView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

struct SettingsView: View {

    @AppStorage("pangolin_server_url") var pangolinServerUrl: String = ""
    @AppStorage("pangolin_api_key") var pangolinApiKey: String = ""
    @AppStorage("pangolin_organization_id") var pangolinOrganizationId: String = ""
    @AppStorage("selectedTab") private var selectedTab: DefaultTab = .sites

    @EnvironmentObject var appService: AppService

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("")) {
                    NavigationLink {
                        InstanceView()
                            .environmentObject(self.appService)
                    } label: {
                        VStack(alignment: .leading) {
                            Text("INSTANCE")
                            if !self.pangolinServerUrl.isEmpty {
                                Text(self.pangolinServerUrl)
                                    .foregroundStyle(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }

                    if self.appService.organizations.count > 0 {
                        Picker("ORGANIZATION", selection: $pangolinOrganizationId) {
                            ForEach(self.appService.organizations, id: \.orgId) { org in
                                Text(org.name)
                                    .tag(org.orgId)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: pangolinOrganizationId) { oldValue, newValue in
                            self.appService.fetchResources()
                            self.appService.fetchDomains()
                            self.appService.fetchSites { _, _ in }
                        }
                    }
                }
                .textCase(nil)

                Section(header: Text("ACCESS_CONTROL")) {
                    NavigationLink {
                        RolesView()
                            .environmentObject(self.appService)
                    } label: {
                        Text("ROLES")
                    }

                    NavigationLink {
                        UsersView()
                            .environmentObject(self.appService)
                    } label: {
                        Text("USERS")
                    }

                    NavigationLink {
                        InvitationsView()
                            .environmentObject(self.appService)
                    } label: {
                        Text("INVITATIONS")
                    }

                    NavigationLink {
                        ClientsView()
                    } label: {
                        Text("CLIENTS")
                    }

                    NavigationLink {
                        IdentityProvidersView()
                    } label: {
                        Text("IDENTITY_PROVIDERS")
                    }

                    NavigationLink {
                        DeviceApprovalsView()
                    } label: {
                        Text("DEVICE_APPROVALS")
                    }
                }
                .textCase(nil)

                Section(header: Text("SECURITY")) {
                    NavigationLink {
                        OrgSecuritySettingsView()
                    } label: {
                        Text("SECURITY_SETTINGS")
                    }

                    NavigationLink {
                        GeoBlockingView()
                    } label: {
                        Text("GEO_BLOCKING")
                    }

                    NavigationLink {
                        ASNBlockingView()
                    } label: {
                        Text("ASN_BLOCKING")
                    }
                }
                .textCase(nil)

                Section(header: Text("INFRASTRUCTURE")) {
                    NavigationLink {
                        NodesView()
                    } label: {
                        Text("NODES")
                    }

                    NavigationLink {
                        BlueprintsView()
                    } label: {
                        Text("BLUEPRINTS")
                    }
                }
                .textCase(nil)

                Section(header: Text("APPEARANCE")) {
                    NavigationLink {
                        BrandingView()
                    } label: {
                        Text("BRANDING")
                    }
                }
                .textCase(nil)

                Section(header: Text("SETTINGS")) {
                    Picker("DEFAULT_TAB", selection: $selectedTab) {
                        ForEach(DefaultTab.allCases, id: \.self) { tab in
                            Text(LocalizedStringResource(stringLiteral: tab.rawValue.capitalized))
                        }
                    }
                    .pickerStyle(.menu)
                }
                .textCase(nil)

                Section(header: Text("SUPPORT"), footer: SettingsFooterView()) {
                    HStack {
                        Text("API Compatibility")
                        Spacer()
                        Text("Pangolin API **v2**")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        let email = "support@masys.mx"
                        let subject = "Support / Feedback"
                        let body = getDeviceAndAppInfo().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

                        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("SUPPORT_FEEDBACK")
                    }
                }
                .textCase(nil)
            }
            .navigationTitle(Text("SETTINGS"))
        }
    }
}

#Preview {
    SettingsView()
}

struct SettingsFooterView: View {
    @State private var companyName = "MaSys"
    @State private var appName = Bundle.main.infoDictionary!["CFBundleDisplayName"]!
    @State private var version = "v\((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)"
    @State private var buildNumber = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String)!

    var appDetails: String {
        return """
    \(appName) \(version) (\(buildNumber))
    """
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(self.companyName)
                    .font(.custom("Splash", size: 13))
                    .foregroundColor(.gray)
                Spacer()
            }
            Text(appDetails)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }
}

func getDeviceAndAppInfo() -> String {
    let device = UIDevice.current
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    let systemName = device.systemName
    let systemVersion = device.systemVersion
    let model = device.model

    return """
    --- Device / App Info ---
    App Version: \(appVersion)
    Build Number: \(buildNumber)
    Device Model: \(model)
    OS: \(systemName) \(systemVersion)
    """
}

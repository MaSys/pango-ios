//
//  ResourcesCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 12/08/25.
//

import SwiftUI

enum CreateResourceType: String, CaseIterable {
    case https = "HTTPS"
    case rawTcpUdp = "TCP/UDP"
    case privateResource = "PRIVATE"
}

struct ResourcesCreateView: View {

    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var resourceType: CreateResourceType = .https

    @State private var subdomain: String = ""
    @State private var selectedDomain: String = ""

    @State private var protocolString: String = "tcp"
    @State private var proxyPort: String = ""

    @State private var host: String = ""
    @State private var cidr: String = ""
    @State private var ports: String = ""

    @State private var errorMessage: String = ""

    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
            }

            Section {
                resourceTypePicker

                switch resourceType {
                case .https:
                    httpsResourceType
                case .rawTcpUdp:
                    rawResourceType
                case .privateResource:
                    privateResourceType
                }
            }

            if !self.errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .onChange(of: self.resourceType) { oldValue, newValue in
            switch newValue {
            case .https:
                protocolString = "tcp"
                proxyPort = ""
                host = ""
                cidr = ""
                ports = ""
            case .rawTcpUdp:
                subdomain = ""
                host = ""
                cidr = ""
                ports = ""
            case .privateResource:
                subdomain = ""
                proxyPort = ""
            }
        }
        .onAppear {
            if let domain = self.appService.domains.first {
                self.selectedDomain = domain.domainId
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.save()
                } label: {
                    Text("SAVE")
                }
            }
        }
    }

    private func save() {
        switch resourceType {
        case .https:
            ResourcesRequest.create(
                name: self.name,
                http: true,
                subdomain: self.subdomain,
                domainId: self.selectedDomain.isEmpty ? nil : self.selectedDomain,
                protocolString: "tcp",
                proxyPort: nil
            ) { success, response in
                if success {
                    self.dismiss()
                } else {
                    if let msg = response?.message {
                        self.errorMessage = msg
                    }
                }
            }
        case .rawTcpUdp:
            ResourcesRequest.create(
                name: self.name,
                http: false,
                subdomain: nil,
                domainId: nil,
                protocolString: self.protocolString,
                proxyPort: self.proxyPort.isEmpty ? nil : Int(self.proxyPort)
            ) { success, response in
                if success {
                    self.dismiss()
                } else {
                    if let msg = response?.message {
                        self.errorMessage = msg
                    }
                }
            }
        case .privateResource:
            ResourcesRequest.create(
                name: self.name,
                http: false,
                subdomain: nil,
                domainId: nil,
                protocolString: self.protocolString,
                proxyPort: nil
            ) { success, response in
                if success {
                    self.dismiss()
                } else {
                    if let msg = response?.message {
                        self.errorMessage = msg
                    }
                }
            }
        }
    }
}

extension ResourcesCreateView {
    var resourceTypePicker: some View {
        Picker("RESOURCE_TYPE", selection: $resourceType) {
            ForEach(CreateResourceType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }.pickerStyle(.segmented)
    }

    var httpsResourceType: some View {
        Group {
            TextField("SUBDOMAIN", text: $subdomain)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
            List {
                ForEach(self.appService.domains, id: \.domainId) { domain in
                    Button {
                        self.selectedDomain = domain.domainId
                    } label: {
                        HStack {
                            Text(domain.baseDomain)
                                .foregroundStyle(.white)
                            Spacer()
                            if self.selectedDomain == domain.domainId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    var rawResourceType: some View {
        Group {
            Picker("PROTOCOL", selection: $protocolString) {
                Text("TCP")
                    .tag("tcp")
                Text("UDP")
                    .tag("udp")
            }.pickerStyle(.menu)

            TextField("PORT_NUMBER", text: $proxyPort)
        }
    }

    var privateResourceType: some View {
        Group {
            TextField("HOST", text: $host)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
                .keyboardType(.numbersAndPunctuation)

            TextField("CIDR_OPTIONAL", text: $cidr)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)

            TextField("PORTS_OPTIONAL", text: $ports)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
                .keyboardType(.numbersAndPunctuation)

            Picker("PROTOCOL", selection: $protocolString) {
                Text("TCP")
                    .tag("tcp")
                Text("UDP")
                    .tag("udp")
            }.pickerStyle(.menu)
        }
    }
}

#Preview {
    ResourcesCreateView()
}

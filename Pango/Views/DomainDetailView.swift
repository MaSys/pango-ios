//
//  DomainDetailView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct DomainDetailView: View {

    var domain: Domain

    @EnvironmentObject var appService: AppService

    @State private var records: [DnsRecord] = []
    @State private var loading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("DNS_RECORDS") {
                if loading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                } else if records.isEmpty {
                    Text("NO_DNS_RECORDS")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(records.indices, id: \.self) { index in
                        let record = records[index]
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(record.type)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2))
                                    .foregroundStyle(.accent)
                                    .clipShape(Capsule())
                                Text(record.name)
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                            }
                            Text(record.value)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section {
                HStack {
                    Text("STATUS")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(domain.verified == true ? "VERIFIED" : "UNVERIFIED")
                        .foregroundStyle(domain.verified == true ? .green : .red)
                }
                HStack {
                    Text("TYPE")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(domain.type.capitalized)
                }
            }
        }
        .navigationTitle(domain.baseDomain)
        .task {
            await fetch()
        }
        .alert("ERROR", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func fetch() async {
        loading = true
        defer { loading = false }
        do {
            records = try await domainService().listDNSRecords(domainId: domain.domainId)
        } catch is CancellationError {
            return
        } catch let error as PangolinAPIError {
            errorMessage = error.localizedMessage()
        } catch {
            errorMessage = String(localized: "ERROR_API_RESPONSE")
        }
    }
}

private extension DomainDetailView {
    func domainService() throws -> PangolinDomainService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(
                baseURLString: appService.pangolinServerUrl,
                apiKey: appService.pangolinApiKey
            )
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinDomainService(
            client: PangolinAPIClient(configuration: configuration),
            organizationId: appService.pangolinOrganizationId
        )
    }
}

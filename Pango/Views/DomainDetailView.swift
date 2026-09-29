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
    @State private var errorKey: String?

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
            get: { errorKey != nil },
            set: { if !$0 { errorKey = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorKey {
                Text(LocalizedStringKey(errorKey))
            }
        }
    }

    private func fetch() async {
        loading = true
        defer { loading = false }
        do {
            records = try await appService.fetchDNSRecords(domainId: domain.domainId)
        } catch is CancellationError {
            return
        } catch let error as PangolinAPIError {
            errorKey = error.localizationKey
        } catch {
            errorKey = "ERROR_API_RESPONSE"
        }
    }
}

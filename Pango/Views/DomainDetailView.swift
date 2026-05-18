//
//  DomainDetailView.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

import SwiftUI

struct DomainDetailView: View {

    var domain: Domain

    @State private var records: [DnsRecord] = []
    @State private var loading: Bool = false

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
        .onAppear {
            self.fetch()
        }
    }

    private func fetch() {
        self.loading = true
        DomainsRequest.fetchDetail(domainId: domain.domainId) { success, records in
            self.loading = false
            if success {
                self.records = records
            }
        }
    }
}

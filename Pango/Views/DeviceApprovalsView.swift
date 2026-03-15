//
//  DeviceApprovalsView.swift
//  Pango
//

import SwiftUI

struct DeviceApprovalsView: View {

    @State private var approvals: [DeviceApproval] = []
    @State private var isLoading: Bool = false

    var body: some View {
        List {
            ForEach(approvals, id: \.approvalId) { approval in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(approval.deviceName ?? "Unknown Device")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(approval.status?.capitalized ?? "Pending")
                            .font(.system(size: 14))
                            .foregroundStyle(approval.isPending ? .orange : .secondary)
                    }
                    HStack {
                        if let email = approval.userEmail {
                            Text(email)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let ip = approval.ip {
                            Text(ip)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let os = approval.os {
                        Text(os)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .leading) {
                    if approval.isPending {
                        Button {
                            Task { await approve(approval) }
                        } label: {
                            Label("APPROVE", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                }
                .swipeActions(edge: .trailing) {
                    if approval.isPending {
                        Button(role: .destructive) {
                            Task { await deny(approval) }
                        } label: {
                            Label("DENY", systemImage: "xmark")
                        }
                    }
                }
            }
        }
        .navigationTitle("DEVICE_APPROVALS")
        .task {
            await fetch()
        }
        .refreshable {
            await fetch()
        }
        .overlay {
            if !isLoading && approvals.isEmpty {
                ContentUnavailableView("NO_PENDING_APPROVALS", systemImage: "checkmark.shield")
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            approvals = try await DeviceApprovalsRequest.fetchPending()
        } catch {}
        isLoading = false
    }

    private func approve(_ approval: DeviceApproval) async {
        do {
            _ = try await DeviceApprovalsRequest.approve(approvalId: approval.approvalId)
            await fetch()
        } catch {}
    }

    private func deny(_ approval: DeviceApproval) async {
        do {
            _ = try await DeviceApprovalsRequest.deny(approvalId: approval.approvalId)
            await fetch()
        } catch {}
    }
}

#Preview {
    NavigationStack {
        DeviceApprovalsView()
    }
}

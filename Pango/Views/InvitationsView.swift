//
//  InvitationsView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/10/25.
//

import SwiftUI

struct InvitationsView: View {

    @EnvironmentObject var appService: AppService

    @State private var invitations: [Invitation] = []
    @State private var isLoading: Bool = false

    var body: some View {
        List {
            ForEach(self.invitations, id: \.inviteId) { inv in
                VStack(alignment: .leading) {
                    Text(inv.email)
                    HStack {
                        Text(inv.roleName ?? "Unknown")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Spacer()
                        Text(inv.formattedExpiresAt)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .navigationTitle("INVITATIONS")
        .overlay {
            if !isLoading && invitations.isEmpty {
                ContentUnavailableView("NO_INVITATIONS", systemImage: "envelope")
            }
        }
        .onAppear {
            self.fetch()
        }
    }

    private func fetch() {
        isLoading = true
        InvitationsRequest.fetch { success, invitations in
            self.invitations = invitations
            isLoading = false
        }
    }
}

#Preview {
    InvitationsView()
}

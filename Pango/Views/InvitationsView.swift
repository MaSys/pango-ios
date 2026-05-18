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
    
    var body: some View {
        List {
            ForEach(self.invitations, id: \.inviteId) { inv in
                VStack(alignment: .leading) {
                    Text(inv.email)
                    HStack {
                        Text(inv.roleNames)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Spacer()
                        Text(inv.formattedExpiresAt)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("INVITATIONS")
        .onAppear {
            self.fetch()
        }
    }
    
    private func fetch() {
        InvitationsRequest.fetch { success, invitations in
            self.invitations = invitations
        }
    }
}

#Preview {
    InvitationsView()
}

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
    @State private var errorKey: String?
    
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
        .task {
            await fetch()
        }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func fetch() async {
        do {
            invitations = try await appService.fetchInvitations()
        } catch is CancellationError {
            return
        } catch let error as PangolinAPIError {
            errorKey = error.localizationKey
        } catch {
            errorKey = "ERROR_API_RESPONSE"
        }
    }
}

#Preview {
    InvitationsView()
}

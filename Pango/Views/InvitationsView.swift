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
    @State private var errorMessage: String?
    
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
        .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
    }
    
    private func fetch() async {
        do {
            let revision = appService.organizationRevision
            let result = try await invitationService().listAllInvitations()
            guard revision == appService.organizationRevision else { return }
            invitations = result
        } catch is CancellationError {
            return
        } catch let error as PangolinAPIError {
            errorMessage = error.localizedMessage()
        } catch {
            errorMessage = String(localized: "ERROR_API_RESPONSE")
        }
    }
}

#Preview {
    InvitationsView()
}

private extension InvitationsView {
    func invitationService() throws -> PangolinInvitationService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: appService.pangolinServerUrl, apiKey: appService.pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        guard !appService.pangolinOrganizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PangolinAPIError.organizationRequired
        }
        return PangolinInvitationService(client: PangolinAPIClient(configuration: configuration), organizationId: appService.pangolinOrganizationId)
    }
}

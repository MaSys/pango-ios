//
//  UsersView.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

import SwiftUI

struct UsersView: View {
    
    @EnvironmentObject var appService: AppService
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(self.appService.users, id: \.id) { user in
                    VStack {
                        HStack {
                            Text(user.email)
                            Spacer()
                        }//hstack
                        
                        HStack {
                            if user.isOwner == true {
                                Image(systemName: "crown")
                                    .imageScale(.small)
                                    .foregroundStyle(Color.accentColor)
                                Text("OWNER")
                            } else {
                                Text(user.roleNames.isEmpty ? user.type.capitalized : user.roleNames)
                            }

                            Spacer()
                            Text(user.type.capitalized)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                    }//vstack
                }//loop
            }//list
            .navigationTitle("USERS")
            .task {
                do {
                    _ = try await appService.fetchUsers()
                } catch is CancellationError {
                    return
                } catch let error as PangolinAPIError {
                    errorMessage = error.localizedMessage()
                } catch {
                    errorMessage = String(localized: "ERROR_API_RESPONSE")
                }
            }
            .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let errorMessage { Text(errorMessage) }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        InvitationCreateView()
                            .environmentObject(self.appService)
                    } label: {
                        Image(systemName: "plus")
                    }

                }
            }
        }
    }
}

#Preview {
    UsersView()
}

//
//  UsersView.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

import SwiftUI

struct UsersView: View {
    
    @EnvironmentObject var appService: AppService
    @State private var errorKey: String?
    
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
                    errorKey = error.localizationKey
                } catch {
                    errorKey = "ERROR_API_RESPONSE"
                }
            }
            .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
                Button("OK", role: .cancel) { errorKey = nil }
            } message: {
                if let errorKey { Text(LocalizedStringKey(errorKey)) }
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

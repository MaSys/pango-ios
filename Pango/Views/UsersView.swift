//
//  UsersView.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

import SwiftUI

struct UsersView: View {

    @EnvironmentObject var appService: AppService

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.appService.users, id: \.id) { user in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(user.email)
                            Spacer()
                        }

                        HStack {
                            if user.isOwner == true {
                                Image(systemName: "crown")
                                    .imageScale(.small)
                                    .foregroundStyle(Color.accentColor)
                                Text("OWNER")
                            } else {
                                Text(user.roleName ?? "")
                            }

                            Spacer()
                            Text((user.type ?? "user").capitalized)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .navigationTitle("USERS")
            .overlay {
                if appService.users.isEmpty {
                    ContentUnavailableView("NO_USERS", systemImage: "person.2")
                }
            }
            .onAppear {
                self.appService.fetchUsers()
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

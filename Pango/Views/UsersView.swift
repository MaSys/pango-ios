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
                                Text(user.roleName ?? "")
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
            .onAppear {
                self.appService.fetchUsers()
            }
        }
    }
}

#Preview {
    UsersView()
}

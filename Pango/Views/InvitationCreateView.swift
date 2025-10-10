//
//  InvitationCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/10/25.
//

import SwiftUI

struct InvitationCreateView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    @State private var email: String = ""
    @State private var validHours: Int = 24
    @State private var roleId: Int = 0
    
    var validForm: Bool {
        if self.email.isEmpty { return false }
        if self.validHours == 0 { return false }
        if self.roleId == 0 { return false }
        
        return true
    }
    
    var body: some View {
        Form {
            HStack {
                Text("EMAIL")
                TextField("EMAIL", text: $email)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
            }
            HStack {
                Text("VALID_FOR")
                Picker("", selection: $validHours) {
                    ForEach(1..<8) { i in
                        Text("\(i)_DAY").tag(24 * i)
                    }
                }
            }
            Picker("ROLE", selection: $roleId) {
                ForEach(self.appService.roles, id: \.roleId) { role in
                    Text(role.name ?? "")
                        .tag(role.roleId)
                }
            }
            .pickerStyle(.navigationLink)
        }//form
        .onAppear {
            self.appService.fetchRoles()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    self.save()
                }
                .disabled(!self.validForm)
            }
        }
    }
    
    private func save() {
        if !self.validForm { return }
        
        InvitationsRequest.create(email: self.email, validHours: self.validHours, roleId: self.roleId) { success in
            if success {
                self.dismiss()
            }
        }
    }
}

#Preview {
    InvitationCreateView()
}

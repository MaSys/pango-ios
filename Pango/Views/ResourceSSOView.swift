//
//  ResourceSSOView.swift
//  Pango
//
//  Created by Yaser Almasri on 05/09/25.
//

import SwiftUI

struct ResourceSSOView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var ssoEnabled: Bool = false
    @State private var isUpdating = false
    @State private var errorKey: String?
    
    var body: some View {
        Form {
            Section {
                Toggle("USE_PLATFORM_SSO", isOn: Binding(
                    get: { ssoEnabled },
                    set: { newValue in
                        let oldValue = ssoEnabled
                        ssoEnabled = newValue
                        updateSSO(enabled: newValue, rollbackValue: oldValue)
                    }
                ))
                .disabled(isUpdating)
            }
            
            Section {
                NavigationLink {
                    ResourceUsersView(resource: self.resource)
                        .environmentObject(self.appService)
                } label: {
                    Text("USERS")
                }
                .disabled(!self.ssoEnabled)
                
                NavigationLink {
                    ResourceRolesView(resource: self.resource)
                        .environmentObject(self.appService)
                } label: {
                    Text("ROLES")
                }
                .disabled(!self.ssoEnabled)
            }
        }
        .onAppear {
            self.ssoEnabled = self.resource.sso == 1
            self.appService.fetchUsers()
            self.appService.fetchRoles()
        }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func updateSSO(enabled: Bool, rollbackValue: Bool) {
        Task {
            isUpdating = true
            defer { isUpdating = false }
            do {
                try await appService.setResourceSSO(resourceId: resource.resourceId, enabled: enabled)
            } catch let error as PangolinAPIError {
                ssoEnabled = rollbackValue
                errorKey = error.localizationKey
            }
        }
    }
}

#Preview {
    ResourceSSOView(resource: Resource.fake())
        .environmentObject(AppService.shared)
}


struct ResourceUsersView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var isLoading: Bool = false
    @State private var selectedUsers: [String] = []
    
    @State private var errorMessage: String = ""
    
    var body: some View {
        List {
            Section {
                ForEach(self.appService.users, id: \.id) { user in
                    Button {
                        if selectedUsers.contains(user.id) {
                            self.selectedUsers.removeAll { id in
                                return id == user.id
                            }
                        } else {
                            self.selectedUsers.append(user.id)
                        }
                    } label: {
                        HStack {
                            Text(user.email)
                            Spacer()
                            if selectedUsers.contains(user.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .tint(.primary)
                    }
                }//loop
            }//section
            
            if !self.errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle("USERS")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            self.fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    self.save()
                }
                .disabled(self.isLoading)
            }
        }
    }
    
    private func fetch() {
        ResourcesRequest.users(id: self.resource.resourceId) { success, users in
            self.selectedUsers = users.map({ user in
                return user.userId!
            })
        }
    }
    
    private func save() {
        self.errorMessage = ""
        
        ResourcesRequest.setUser(id: self.resource.resourceId, userIds: self.selectedUsers) { success, response in
            if success && response?.success == true {
                self.appService.fetchResources()
                self.dismiss()
            } else {
                self.errorMessage = response?.message ?? ""
            }
        }
    }
}

struct ResourceRolesView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var isLoading: Bool = false
    @State private var selectedRoles: [Int] = []
    
    @State private var errorMessage: String = ""
    
    var body: some View {
        List {
            ForEach(self.appService.roles.filter({ $0.isAdmin != true }), id: \.roleId) { role in
                Button {
                    if selectedRoles.contains(role.roleId) {
                        self.selectedRoles.removeAll { id in
                            return id == role.roleId
                        }
                    } else {
                        self.selectedRoles.append(role.roleId)
                    }
                } label: {
                    HStack {
                        Text(role.name ?? "")
                        Spacer()
                        if selectedRoles.contains(role.roleId) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .tint(.primary)
                }
            }//loop
            
            if !self.errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
            }
        }
        .navigationTitle("ROLES")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            self.fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    self.save()
                }
                .disabled(self.isLoading)
            }
        }
    }
    
    private func fetch() {
        ResourcesRequest.roles(id: self.resource.resourceId) { success, roles in
            self.selectedRoles = roles.map({ role in
                return role.roleId
            })
            let admins = self.appService.roles.filter { $0.isAdmin == true }.map { $0.roleId }
            self.selectedRoles.removeAll { id in
                return admins.contains(id)
            }
        }
    }
    
    private func save() {
        self.errorMessage = ""
        
        ResourcesRequest.setRoles(id: self.resource.resourceId, roleIds: self.selectedRoles) { success, response in
            if success && response?.success == true {
                self.appService.fetchResources()
                self.dismiss()
            } else {
                self.errorMessage = response?.message ?? ""
            }
        }
    }
}

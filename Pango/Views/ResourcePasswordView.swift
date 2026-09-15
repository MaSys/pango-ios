//
//  ResourcePasswordView.swift
//  Pango
//
//  Created by Yaser Almasri on 07/08/25.
//

import SwiftUI

struct ResourcePasswordView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var password: String = ""
    @State private var isSaving = false
    @State private var errorKey: String?
    
    var body: some View {
        Form {
            Section(footer: Text("RESOURCE_PASSWORD_HINT")) {
                SecureField("PASSWORD", text: $password)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.save()
                } label: {
                    Text("SAVE")
                }
                .disabled(isSaving)

            }
        }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func save() {
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                try await appService.setResourcePassword(
                    resourceId: resource.resourceId,
                    password: password.isEmpty ? nil : password
                )
                dismiss()
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            }
        }
    }
}

#Preview {
    ResourcePasswordView(resource: Resource.fake())
}

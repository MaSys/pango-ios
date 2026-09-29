//
//  RolesCreateView.swift
//  Pango
//
//  Created by Yaser Almasri on 24/08/25.
//

import SwiftUI

struct RolesCreateView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isSaving = false
    @State private var errorKey: String?
    
    var body: some View {
        Form {
            HStack {
                Text("NAME")
                Spacer()
                TextField("NAME", text: $name)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .autocapitalization(.words)
            }
            
            HStack {
                Text("DESCRIPTION")
                Spacer()
                TextField("DESCRIPTION", text: $description)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .autocapitalization(.words)
            }
        }//form
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    self.save()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func save() {
        guard !isSaving, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await appService.createRole(name: name, description: description)
                dismiss()
            } catch is CancellationError {
                return
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_API_RESPONSE"
            }
        }
    }
}

#Preview {
    RolesCreateView()
}

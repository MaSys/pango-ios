//
//  ResourceNameView.swift
//  Pango
//
//  Created by Yaser Almasri on 07/08/25.
//

import SwiftUI

struct ResourceNameView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var name: String = ""
    @State private var errorKey: String?
    
    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
                    .autocapitalization(.words)
            }
        }
        .onAppear {
            self.name = self.resource.name
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.save()
                } label: {
                    Text("SAVE")
                }

            }
        }
        .alert("ERROR", isPresented: Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func save() {
        if self.name.isEmpty { return }
        
        Task {
            do {
                _ = try await appService.updateResource(resourceId: resource.resourceId, name: name)
                self.dismiss()
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
            }
        }
    }
}

#Preview {
    ResourceNameView(resource: Resource.fake())
}

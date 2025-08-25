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
            }
        }
    }
    
    private func save() {
        if self.name.isEmpty { return }
        
        RolesRequest.create(name: self.name, description: self.description) { success, role in
            if success {
                self.appService.fetchRoles()
                self.dismiss()
            }
        }
    }
}

#Preview {
    RolesCreateView()
}

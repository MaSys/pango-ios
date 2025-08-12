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

            }
        }
    }
    
    private func save() {
        ResourcesRequest.setPassword(id: self.resource.resourceId, password: self.password) { success, response in
            if let res = response, res.success {
                self.appService.fetchResources()
                self.dismiss()
            }
        }
    }
}

#Preview {
    ResourcePasswordView(resource: Resource.fake())
}

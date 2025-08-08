//
//  ResourceNameView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 07/08/25.
//

import SwiftUI

struct ResourceNameView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var name: String = ""
    
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
    }
    
    private func save() {
        if self.name.isEmpty { return }
        
        ResourcesRequest.updateName(id: self.resource.resourceId, name: self.name) { success, response in
            if let res = response, res.success {
                self.appService.fetchResources()
                self.dismiss()
            }
        }
    }
}

#Preview {
    ResourceNameView(resource: Resource.fake())
}

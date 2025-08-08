//
//  ResourcePinCodeView.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 07/08/25.
//

import SwiftUI

struct ResourcePinCodeView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var pinCode: String = ""
    
    var body: some View {
        Form {
            Section(footer: Text("RESOURCE_PIN_CODE_HINT")) {
                SecureField("PIN_CODE", text: $pinCode)
                    .keyboardType(.numberPad)
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
        ResourcesRequest.setPinCode(id: self.resource.resourceId, pinCode: self.pinCode) { success, response in
            if let res = response, res.success {
                self.appService.fetchResources()
                self.dismiss()
            }
        }
    }
}

#Preview {
    ResourcePinCodeView(resource: Resource.fake())
}

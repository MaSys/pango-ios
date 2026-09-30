//
//  ResourcePinCodeView.swift
//  Pango
//
//  Created by Yaser Almasri on 07/08/25.
//

import SwiftUI

struct ResourcePinCodeView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var pinCode: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
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
                .disabled(isSaving)

            }
        }
        .alert("ERROR", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
    }
    
    private func save() {
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                let newPinCode = pinCode.isEmpty ? nil : pinCode
                try PangolinPublicResourceAuthService.validatePinCode(newPinCode)
                let service = try publicResourceAuthService()
                let policy = try await service.getDefaultPolicy(resourceId: resource.resourceId)
                try await service.setPinCode(
                    policyId: policy.resourcePolicyId,
                    pinCode: newPinCode
                )
                Task { try? await appService.fetchResources() }
                dismiss()
            } catch let error as PangolinAPIError {
                errorMessage = error.localizedMessage()
            } catch {
                errorMessage = String(localized: "ERROR_CONNECTING_TO_SERVER")
            }
        }
    }
}

#Preview {
    ResourcePinCodeView(resource: Resource.fake())
}

private extension ResourcePinCodeView {
    func publicResourceAuthService() throws -> PangolinPublicResourceAuthService {
        let configuration: PangolinAPIConfiguration
        do {
            configuration = try PangolinAPIConfiguration(baseURLString: appService.pangolinServerUrl, apiKey: appService.pangolinApiKey)
        } catch PangolinAPIConfiguration.Error.invalidBaseURL {
            throw PangolinAPIError.invalidBaseURL
        } catch PangolinAPIConfiguration.Error.missingAPIKey {
            throw PangolinAPIError.missingAPIKey
        }
        return PangolinPublicResourceAuthService(client: PangolinAPIClient(configuration: configuration))
    }
}

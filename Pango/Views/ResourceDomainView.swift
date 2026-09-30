//
//  ResourceDomainView.swift
//  Pango
//
//  Created by Yaser Almasri on 09/08/25.
//

import SwiftUI

struct ResourceDomainView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    
    @State private var subdomain: String = ""
    @State private var selectedDomain: String = ""
    
    var body: some View {
        VStack {
                List {
                    Section {
                        TextField("SUBDOMAIN", text: self.$subdomain)
                            .textInputAutocapitalization(.none)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    Section {
                        ForEach(self.appService.domains, id: \.domainId) { domain in
                            Button {
                                self.selectedDomain = domain.domainId
                            } label: {
                                HStack {
                                    Text(domain.baseDomain)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if self.selectedDomain == domain.domainId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                        }
                    }
                }
            Spacer()
        }
        .onAppear {
            self.appService.fetchDomains()
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
        if self.subdomain.isEmpty || self.selectedDomain.isEmpty {
            return
        }
        
        Task {
            do {
                try await appService.updateResourceDomain(
                    resourceId: resource.resourceId,
                    domainId: selectedDomain,
                    subdomain: subdomain
                )
                refreshAndDismiss()
            } catch {
                // Keep the editor open when the update fails.
            }
        }
    }

    private func refreshAndDismiss() {
        appService.fetchResources()
        dismiss()
    }
}

#Preview {
    ResourceDomainView(resource: Resource.fake())
}

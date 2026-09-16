//
//  ResourceNewTargetView.swift
//  Pango
//
//  Created by Yaser Almasri on 11/08/25.
//

import SwiftUI

struct ResourceTargetView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    var resource: Resource
    var target: Target?
    
    @State private var method: PublicTargetMethod = .http
    @State private var ipHostname: String = ""
    @State private var port: String = ""
    @State private var enabled: Bool = true
    @State private var siteId: Int = 0
    @State private var healthCheck: Bool = false
    @State private var usesPathRouting = false
    @State private var path = ""
    @State private var pathMatchType: TargetPathMatchType = .prefix
    @State private var usesPathRewriting = false
    @State private var rewritePath = ""
    @State private var rewritePathType: TargetRewritePathType = .prefix
    @State private var isSaving = false
    @State private var errorKey: String?
    
    var validForm: Bool {
        if self.siteId == 0 { return false }
        guard let port = Int(port), (1...65_535).contains(port) else { return false }
        if self.ipHostname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        if usesPathRouting && path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        if usesPathRouting,
           usesPathRewriting,
           rewritePathType != .stripPrefix,
           rewritePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        return true
    }
    
    var body: some View {
        Form {
            Picker("SITE", selection: $siteId) {
                ForEach(self.appService.sites, id: \.siteId) { site in
                    Text(site.name)
                        .tag(site.siteId)
                }
            }.pickerStyle(.menu)
            
            if self.resource.http {
                Picker("METHOD", selection: $method) {
                    Text("http").tag(PublicTargetMethod.http)
                    Text("https").tag(PublicTargetMethod.https)
                    Text("h2c").tag(PublicTargetMethod.h2c)
                }.pickerStyle(.segmented)
            }
            
            HStack {
                TextField("IP_HOSTNAME", text: $ipHostname)
                    .keyboardType(.numbersAndPunctuation)
                    .autocapitalization(.none)
            }
            
            HStack {
                TextField("PORT", text: $port)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
            }
            
            HStack {
                Toggle("ENABLED", isOn: $enabled)
            }

            Toggle("HEALTH_CHECK", isOn: $healthCheck)

            if resource.http {
                Section("PATH_ROUTING") {
                    Toggle("ENABLED", isOn: $usesPathRouting)
                    if usesPathRouting {
                        TextField("PATH", text: $path)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        Picker("MATCH_TYPE", selection: $pathMatchType) {
                            Text("EXACT").tag(TargetPathMatchType.exact)
                            Text("PREFIX").tag(TargetPathMatchType.prefix)
                            Text("REGEX").tag(TargetPathMatchType.regex)
                        }

                        Toggle("PATH_REWRITING", isOn: $usesPathRewriting)
                        if usesPathRewriting {
                            Picker("REWRITE_TYPE", selection: $rewritePathType) {
                                Text("EXACT").tag(TargetRewritePathType.exact)
                                Text("PREFIX").tag(TargetRewritePathType.prefix)
                                Text("REGEX").tag(TargetRewritePathType.regex)
                                Text("STRIP_PREFIX").tag(TargetRewritePathType.stripPrefix)
                            }
                            TextField("REWRITE_PATH", text: $rewritePath)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let target = self.target {
                self.method = PublicTargetMethod(rawValue: target.method ?? "http") ?? .http
                self.ipHostname = target.ip
                self.port = String(target.port)
                self.enabled = target.enabled
                self.siteId = target.siteId
                self.healthCheck = target.healthCheck ?? false
                self.usesPathRouting = target.path != nil && target.pathMatchType != nil
                self.path = target.path ?? ""
                self.pathMatchType = TargetPathMatchType(rawValue: target.pathMatchType ?? "prefix") ?? .prefix
                self.usesPathRewriting = target.pathRewriting != nil || target.rewritePathType != nil
                self.rewritePath = target.pathRewriting ?? ""
                self.rewritePathType = TargetRewritePathType(rawValue: target.rewritePathType ?? "prefix") ?? .prefix
            } else {
                if let site = self.appService.sites.first {
                    self.siteId = site.siteId
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.save()
                } label: {
                    Text("SAVE")
                }
                .disabled(!self.validForm || isSaving)
            }
        }
        .alert("ERROR", isPresented: Binding(
            get: { errorKey != nil },
            set: { if !$0 { errorKey = nil } }
        )) {
            Button("OK", role: .cancel) { errorKey = nil }
        } message: {
            if let errorKey { Text(LocalizedStringKey(errorKey)) }
        }
    }
    
    private func save() {
        guard validForm, let targetPort = Int(port) else { return }
        
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let configuration = PublicTargetConfiguration(
                    siteId: siteId,
                    ip: ipHostname.trimmingCharacters(in: .whitespacesAndNewlines),
                    port: targetPort,
                    method: resource.http ? method : nil,
                    enabled: enabled,
                    healthCheck: healthCheck,
                    path: usesPathRouting ? path.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                    pathMatchType: usesPathRouting ? pathMatchType : nil,
                    rewritePath: usesPathRouting && usesPathRewriting && !rewritePath.isEmpty
                        ? rewritePath.trimmingCharacters(in: .whitespacesAndNewlines)
                        : nil,
                    rewritePathType: usesPathRouting && usesPathRewriting ? rewritePathType : nil,
                    healthCheckConfiguration: target?.healthCheckConfiguration ?? .init()
                )
                if let target {
                    _ = try await appService.updateTarget(targetId: target.targetId, configuration: configuration)
                } else {
                    _ = try await appService.createTarget(resourceId: resource.resourceId, configuration: configuration)
                }
                dismiss()
            } catch let error as PangolinAPIError {
                errorKey = error.localizationKey
            } catch {
                errorKey = "ERROR_CONNECTING_TO_SERVER"
            }
        }
    }
}

#Preview {
    ResourceTargetView(resource: Resource.fake())
}

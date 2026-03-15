//
//  BrandingView.swift
//  Pango
//

import SwiftUI
import PhotosUI

struct BrandingView: View {

    @State private var primaryColor: String = ""
    @State private var accentColor: String = ""
    @State private var loginTitle: String = ""
    @State private var loginMessage: String = ""
    @State private var footerText: String = ""
    @State private var logoUrl: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""

    var body: some View {
        Form {
            Section(header: Text("LOGO")) {
                if !logoUrl.isEmpty {
                    AsyncImage(url: URL(string: logoUrl)) { image in
                        image.resizable().scaledToFit().frame(maxHeight: 60)
                    } placeholder: {
                        ProgressView()
                    }
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("UPLOAD_LOGO", systemImage: "photo")
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            await uploadLogo(data)
                        }
                    }
                }
            }

            Section(header: Text("COLORS")) {
                HStack {
                    Text("PRIMARY_COLOR")
                    TextField("#000000", text: $primaryColor)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                }
                HStack {
                    Text("ACCENT_COLOR")
                    TextField("#0066FF", text: $accentColor)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                }
            }

            Section(header: Text("LOGIN_PAGE")) {
                TextField("LOGIN_TITLE", text: $loginTitle)
                TextField("LOGIN_MESSAGE", text: $loginMessage, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section(header: Text("FOOTER")) {
                TextField("FOOTER_TEXT", text: $footerText)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(Color(.systemRed))
                    .font(.subheadline)
            }
            if !successMessage.isEmpty {
                Text(successMessage)
                    .foregroundStyle(Color(.systemGreen))
                    .font(.subheadline)
            }
        }
        .navigationTitle("BRANDING")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SAVE") {
                    Task { await save() }
                }
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            if let branding = try await BrandingRequest.fetch() {
                primaryColor = branding.primaryColor ?? ""
                accentColor = branding.accentColor ?? ""
                loginTitle = branding.loginTitle ?? ""
                loginMessage = branding.loginMessage ?? ""
                footerText = branding.footerText ?? ""
                logoUrl = branding.logoUrl ?? ""
            }
        } catch {}
        isLoading = false
    }

    private func save() async {
        errorMessage = ""
        successMessage = ""
        do {
            let success = try await BrandingRequest.update(
                primaryColor: primaryColor.isEmpty ? nil : primaryColor,
                accentColor: accentColor.isEmpty ? nil : accentColor,
                loginTitle: loginTitle.isEmpty ? nil : loginTitle,
                loginMessage: loginMessage.isEmpty ? nil : loginMessage,
                footerText: footerText.isEmpty ? nil : footerText
            )
            if success {
                hapticSuccess()
                successMessage = "Saved"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func uploadLogo(_ data: Data) async {
        errorMessage = ""
        do {
            let success = try await BrandingRequest.uploadLogo(imageData: data)
            if success {
                await fetch()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        BrandingView()
    }
}

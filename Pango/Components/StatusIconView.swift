//
//  StatusIconView.swift
//  Pango
//
//  Created by Yaser Almasri on 04/08/25.
//

import SwiftUI

struct StatusIconView: View {

    var online: Bool

    var body: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 8))
            .foregroundStyle(self.online ? Color(.systemGreen) : Color(.systemRed))
            .accessibilityLabel(self.online ? "Online" : "Offline")
    }
}

#Preview {
    StatusIconView(online: true)
}

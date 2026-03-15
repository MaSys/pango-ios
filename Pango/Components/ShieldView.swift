//
//  ShieldView.swift
//  Pango
//
//  Created by Yaser Almasri on 05/08/25.
//

import SwiftUI

struct ShieldView: View {

    var resource: Resource
    var showText: Bool = false

    var body: some View {
        HStack {
            Image(systemName: self.resource.protected ? "checkmark.shield" : "xmark.shield")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(self.resource.protected ? Color(.systemGreen) : .orange)
            if self.showText {
                Text(resource.protected ? "PROTECTED" : "NOT_PROTECTED")
                    .font(.subheadline)
                    .foregroundStyle(self.resource.protected ? Color(.systemGreen) : .orange)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(resource.protected ? "Protected" : "Not protected")
    }
}

#Preview {
    ShieldView(resource: Resource.fake())
}

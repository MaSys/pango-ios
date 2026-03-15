//
//  DetailRow.swift
//  Pango
//

import SwiftUI

struct DetailRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(LocalizedStringResource(stringLiteral: label))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        DetailRow(label: "EMAIL", value: "user@example.com")
        DetailRow(label: "STATUS", value: "Active")
    }
}

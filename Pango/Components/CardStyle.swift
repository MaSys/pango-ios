//
//  CardStyle.swift
//  Pango
//

import SwiftUI

struct CardStyle: ViewModifier {
    var verticalPadding: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                    .shadow(color: .gray.opacity(0.2), radius: 2, y: 1)
            )
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
    }
}

extension View {
    func cardStyle(verticalPadding: CGFloat = 2) -> some View {
        modifier(CardStyle(verticalPadding: verticalPadding))
    }
}

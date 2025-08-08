//
//  ShieldView.swift
//  Pangolinios
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
                .foregroundStyle(self.resource.protected ? .green : .yellow)
            if self.showText {
                Text(resource.protected ? "PROTECTED" : "NOT_PROTECTED")
                    .font(.system(size: 14))
                    .foregroundStyle(self.resource.protected ? .green : .yellow)
            }
        }
    }
}

#Preview {
    ShieldView(resource: Resource.fake())
}

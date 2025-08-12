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
            .resizable()
            .frame(width: 11, height: 11)
            .foregroundStyle(self.online ? .green : .red)
    }
}

#Preview {
    StatusIconView(online: true)
}

//
//  Invitation.swift
//  Pango
//
//  Created by Yaser Almasri on 09/10/25.
//

import SwiftUI

struct Invitation: Decodable {
    var inviteId: String
    var email: String
    var expiresAt: Int
    var roleId: Int
    var roleName: String?
}

extension Invitation {
    var formattedExpiresAt: String {
        let date = Date(timeIntervalSince1970: Double(expiresAt / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

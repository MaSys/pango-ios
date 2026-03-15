//
//  ShareableLink.swift
//  Pango
//

import SwiftUI

struct ShareableLink: Decodable {
    var linkId: String
    var resourceId: Int?
    var token: String?
    var expiresAt: Int?
    var usageCount: Int?
    var maxUses: Int?
    var url: String?
    var dateCreated: String?

    var formattedExpiresAt: String? {
        guard let expiresAt = expiresAt else { return nil }
        let date = Date(timeIntervalSince1970: Double(expiresAt / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        let date = Date(timeIntervalSince1970: Double(expiresAt / 1000))
        return date < Date()
    }
}

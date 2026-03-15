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

    private static let expiresFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var formattedExpiresAt: String? {
        guard let expiresAt = expiresAt else { return nil }
        let date = Date(timeIntervalSince1970: Double(expiresAt / 1000))
        return Self.expiresFormatter.string(from: date)
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        let date = Date(timeIntervalSince1970: Double(expiresAt / 1000))
        return date < Date()
    }
}

//
//  Log.swift
//  Pango
//

import SwiftUI

struct AccessLog: Decodable {
    var id: String
    var timestamp: String
    var userId: String?
    var userName: String?
    var userEmail: String?
    var resourceId: Int?
    var resourceName: String?
    var action: String?
    var success: Bool?
    var ip: String?
    var country: String?
    var userAgent: String?
}

struct ActionLog: Decodable {
    var id: String
    var timestamp: String
    var userId: String?
    var userName: String?
    var userEmail: String?
    var action: String?
    var target: String?
    var targetId: String?
    var details: String?
}

struct RequestLog: Decodable {
    var id: String
    var timestamp: String
    var method: String?
    var path: String?
    var statusCode: Int?
    var ip: String?
    var userAgent: String?
    var resourceId: Int?
    var resourceName: String?
    var decision: String?
    var duration: Int?
}

private enum TimestampFormatting {
    static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()

    static func format(_ timestamp: String) -> String {
        if let date = isoFormatter.date(from: timestamp) {
            return displayFormatter.string(from: date)
        }
        return timestamp
    }
}

extension AccessLog {
    var formattedTimestamp: String {
        TimestampFormatting.format(timestamp)
    }
}

extension ActionLog {
    var formattedTimestamp: String {
        TimestampFormatting.format(timestamp)
    }
}

extension RequestLog {
    var formattedTimestamp: String {
        TimestampFormatting.format(timestamp)
    }
}

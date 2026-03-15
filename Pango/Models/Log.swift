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

extension AccessLog {
    var formattedTimestamp: String {
        return formatTimestamp(timestamp)
    }
}

extension ActionLog {
    var formattedTimestamp: String {
        return formatTimestamp(timestamp)
    }
}

extension RequestLog {
    var formattedTimestamp: String {
        return formatTimestamp(timestamp)
    }
}

private func formatTimestamp(_ timestamp: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: timestamp) {
        let display = DateFormatter()
        display.dateStyle = .short
        display.timeStyle = .medium
        return display.string(from: date)
    }
    return timestamp
}

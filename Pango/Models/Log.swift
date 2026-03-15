//
//  Log.swift
//  Pango
//

import SwiftUI

// The Pangolin API has a single log type: request audit logs
struct RequestAuditLog: Decodable, Identifiable {
    var id: Int
    var timestamp: Int  // unix timestamp
    var orgId: String?
    var action: Bool?
    var reason: Int?
    var actorType: String?
    var actor: String?
    var actorId: String?
    var resourceId: Int?
    var resourceName: String?
    var resourceNiceId: String?
    var ip: String?
    var location: String?
    var userAgent: String?
    var metadata: String?
    var headers: String?
    var query: String?
    var originalRequestURL: String?
    var scheme: String?
    var host: String?
    var path: String?
    var method: String?
    var tls: Bool?

    var formattedTimestamp: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return Self.displayFormatter.string(from: date)
    }

    var actionString: String {
        action == true ? "Allowed" : "Denied"
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()
}

struct RequestAuditLogResponse: Decodable {
    var log: [RequestAuditLog]
    var pagination: LogPagination?
}

struct LogPagination: Decodable {
    var total: Int?
    var limit: Int?
    var offset: Int?
}

// Keep legacy types for backward compat with any remaining references
typealias AccessLog = RequestAuditLog
typealias ActionLog = RequestAuditLog
typealias RequestLog = RequestAuditLog

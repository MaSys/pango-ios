//
//  Analytics.swift
//  Pango
//

import Foundation

enum DateRange: String, CaseIterable, Identifiable {
    case day = "24h"
    case week = "7d"
    case month = "30d"
    case custom = "Custom"
    var id: String { rawValue }
}

struct AnalyticsData: Decodable {
    var requestsPerDay: [DailyRequests]
    var requestsPerCountry: [CountryRequests]
    var totalRequests: Int
    var totalBlocked: Int

    var totalAllowed: Int {
        totalRequests - totalBlocked
    }

    var blockRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(totalBlocked) / Double(totalRequests) * 100
    }

    var peakDay: DailyRequests? {
        requestsPerDay.max(by: { $0.totalCount < $1.totalCount })
    }
}

struct DailyRequests: Decodable, Identifiable {
    var day: String
    var allowedCount: Int
    var blockedCount: Int
    var totalCount: Int

    var id: String { day }

    private static let inputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private static let isoFormatter = ISO8601DateFormatter()
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE M/d"
        return f
    }()
    var parsedDate: Date? {
        Self.inputFormatter.date(from: day) ?? Self.isoFormatter.date(from: day)
    }

    var shortDay: String {
        if let date = parsedDate {
            return Self.displayFormatter.string(from: date)
        }
        return String(day.suffix(5))
    }

    /// Same format as shortDay — kept as a semantic alias for peak insight display
    var peakLabel: String { shortDay }
}

struct CountryRequests: Decodable, Identifiable {
    var code: String
    var count: Int

    var id: String { code }
}

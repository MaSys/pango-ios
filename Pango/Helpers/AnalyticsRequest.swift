//
//  AnalyticsRequest.swift
//  Pango
//

import Alamofire
import Foundation

class AnalyticsRequest {

    static func fetchAnalytics(resourceId: Int? = nil, startDate: Date, endDate: Date) async throws -> AnalyticsData {
        let config = try BaseRequest.config()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        var components = URLComponents(string: config.orgURL("logs/analytics").absoluteString)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "timeStart", value: formatter.string(from: startDate)),
            URLQueryItem(name: "timeEnd", value: formatter.string(from: endDate))
        ]
        if let resourceId = resourceId {
            queryItems.append(URLQueryItem(name: "resourceId", value: String(resourceId)))
        }
        components.queryItems = queryItems

        let url = components.url!
        let data = try await BaseRequest.get(
            MainResponse<AnalyticsData>.self,
            url: url,
            headers: config.headers
        )
        guard let analytics = data else {
            throw APIError.decodingFailed
        }
        return analytics
    }
}

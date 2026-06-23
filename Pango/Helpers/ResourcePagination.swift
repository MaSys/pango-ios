//
//  ResourcePagination.swift
//  Pango
//
//  Created by Yaser Almasri on 23/06/26.
//

import Foundation

struct ResourcePagination {
    static let pageSize = 100

    static func url(baseUrl: String, orgId: String, page: Int) -> URL? {
        guard var components = URLComponents(string: "\(baseUrl)/v1/org/\(orgId)/resources") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]

        return components.url
    }

    static func hasNextPage(total: Int, page: Int, pageSize: Int) -> Bool {
        return page * pageSize < total
    }
}

//
//  BaseRequest.swift
//  Pango
//
//  Shared API request infrastructure with async/await support.
//

import SwiftUI
import Alamofire

enum APIError: LocalizedError {
    case missingConfiguration
    case requestFailed(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Server URL or API key not configured"
        case .requestFailed(let message):
            return message
        case .decodingFailed:
            return "Failed to decode server response"
        }
    }
}

struct PaginatedResponse<T: Decodable>: Decodable {
    var data: T?
    var success: Bool
    var error: Bool
    var message: String
    var status: Int
    var pagination: Pagination?
}

struct Pagination: Decodable {
    var total: Int
    var page: Int
    var limit: Int
}

class BaseRequest {

    struct Config {
        let baseUrl: String
        let apiKey: String
        let orgId: String

        var token: String { "Bearer \(apiKey)" }
        var headers: HTTPHeaders { ["Authorization": token] }

        func orgURL(_ path: String) -> URL {
            URL(string: "\(baseUrl)/v1/org/\(orgId)/\(path)")!
        }

        func url(_ path: String) -> URL {
            URL(string: "\(baseUrl)/v1/\(path)")!
        }
    }

    static func config() throws -> Config {
        let defaults = UserDefaults.standard
        guard let baseUrl = defaults.string(forKey: "pangolin_server_url"),
              let apiKey = defaults.string(forKey: "pangolin_api_key"),
              let orgId = defaults.string(forKey: "pangolin_organization_id"),
              !baseUrl.isEmpty, !apiKey.isEmpty else {
            throw APIError.missingConfiguration
        }
        return Config(baseUrl: baseUrl, apiKey: apiKey, orgId: orgId)
    }

    static func configWithoutOrg() throws -> Config {
        let defaults = UserDefaults.standard
        guard let baseUrl = defaults.string(forKey: "pangolin_server_url"),
              let apiKey = defaults.string(forKey: "pangolin_api_key"),
              !baseUrl.isEmpty, !apiKey.isEmpty else {
            throw APIError.missingConfiguration
        }
        let orgId = defaults.string(forKey: "pangolin_organization_id") ?? ""
        return Config(baseUrl: baseUrl, apiKey: apiKey, orgId: orgId)
    }

    // MARK: - Async GET

    static func get<T: Decodable>(
        _ responseType: MainResponse<T>.Type,
        url: URL,
        headers: HTTPHeaders
    ) async throws -> T? {
        let response = await AF.request(url, headers: headers)
            .serializingDecodable(MainResponse<T>.self)
            .response
        guard let value = response.value else {
            throw APIError.decodingFailed
        }
        guard value.success else {
            throw APIError.requestFailed(value.message)
        }
        return value.data
    }

    static func getPaginated<T: Decodable>(
        _ responseType: PaginatedResponse<T>.Type,
        url: URL,
        headers: HTTPHeaders
    ) async throws -> (data: T?, pagination: Pagination?) {
        let response = await AF.request(url, headers: headers)
            .serializingDecodable(PaginatedResponse<T>.self)
            .response
        guard let value = response.value else {
            throw APIError.decodingFailed
        }
        guard value.success else {
            throw APIError.requestFailed(value.message)
        }
        return (value.data, value.pagination)
    }

    // MARK: - Async POST/PUT/DELETE

    static func post<T: Decodable>(
        _ responseType: MainResponse<T>.Type,
        url: URL,
        parameters: Parameters? = nil,
        headers: HTTPHeaders
    ) async throws -> MainResponse<T> {
        let response = await AF.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .serializingDecodable(MainResponse<T>.self)
        .response
        guard let value = response.value else {
            throw APIError.decodingFailed
        }
        return value
    }

    static func put<T: Decodable>(
        _ responseType: MainResponse<T>.Type,
        url: URL,
        parameters: Parameters? = nil,
        headers: HTTPHeaders
    ) async throws -> MainResponse<T> {
        let response = await AF.request(
            url,
            method: .put,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .serializingDecodable(MainResponse<T>.self)
        .response
        guard let value = response.value else {
            throw APIError.decodingFailed
        }
        return value
    }

    static func delete<T: Decodable>(
        _ responseType: MainResponse<T>.Type,
        url: URL,
        parameters: Parameters? = nil,
        headers: HTTPHeaders
    ) async throws -> MainResponse<T> {
        let response = await AF.request(
            url,
            method: .delete,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .serializingDecodable(MainResponse<T>.self)
        .response
        guard let value = response.value else {
            throw APIError.decodingFailed
        }
        return value
    }
}

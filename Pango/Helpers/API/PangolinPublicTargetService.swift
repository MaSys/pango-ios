import Foundation

struct PublicTargetsPage: Decodable {
    struct Pagination: Decodable {
        let total: Int
        let limit: Int
        let offset: Int
    }

    let targets: [Target]
    let pagination: Pagination?
}

enum PublicTargetMethod: String, Encodable {
    case http
    case https
    case h2c
}

enum TargetPathMatchType: String, Encodable {
    case exact
    case prefix
    case regex
}

enum TargetRewritePathType: String, Encodable {
    case exact
    case prefix
    case regex
    case stripPrefix
}

struct PublicTargetConfiguration {
    let siteId: Int
    let ip: String
    let port: Int
    let method: PublicTargetMethod?
    let enabled: Bool
    let healthCheck: Bool
    let path: String?
    let pathMatchType: TargetPathMatchType?
    let rewritePath: String?
    let rewritePathType: TargetRewritePathType?
    let healthCheckHostname: String?
    let healthCheckConfiguration: TargetHealthCheckConfiguration

    init(
        siteId: Int,
        ip: String,
        port: Int,
        method: PublicTargetMethod?,
        enabled: Bool,
        healthCheck: Bool,
        path: String?,
        pathMatchType: TargetPathMatchType?,
        rewritePath: String?,
        rewritePathType: TargetRewritePathType?,
        healthCheckHostname: String? = nil,
        healthCheckConfiguration: TargetHealthCheckConfiguration = .init()
    ) {
        self.siteId = siteId
        self.ip = ip
        self.port = port
        self.method = method
        self.enabled = enabled
        self.healthCheck = healthCheck
        self.path = path
        self.pathMatchType = pathMatchType
        self.rewritePath = rewritePath
        self.rewritePathType = rewritePathType
        self.healthCheckHostname = healthCheckHostname
        self.healthCheckConfiguration = healthCheckConfiguration
    }
}

struct PangolinPublicTargetService: Sendable {
    private struct TargetBody: Encodable {
        let siteId: Int
        let ip: String
        let port: Int
        let method: PublicTargetMethod?
        let enabled: Bool
        let hcEnabled: Bool
        let healthCheckConfiguration: TargetHealthCheckConfiguration
        let path: String?
        let pathMatchType: TargetPathMatchType?
        let rewritePath: String?
        let rewritePathType: TargetRewritePathType?

        private enum CodingKeys: String, CodingKey {
            case siteId, ip, port, method, enabled, hcEnabled
            case path, pathMatchType, rewritePath, rewritePathType
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(siteId, forKey: .siteId)
            try container.encode(ip, forKey: .ip)
            try container.encode(port, forKey: .port)
            try container.encodeIfPresent(method, forKey: .method)
            try container.encode(enabled, forKey: .enabled)
            try container.encode(hcEnabled, forKey: .hcEnabled)
            try container.encodeIfPresent(path, forKey: .path)
            try container.encodeIfPresent(pathMatchType, forKey: .pathMatchType)
            try container.encodeIfPresent(rewritePath, forKey: .rewritePath)
            try container.encodeIfPresent(rewritePathType, forKey: .rewritePathType)
            try healthCheckConfiguration.encode(to: encoder)
        }
    }

    private let client: PangolinAPIClient

    init(client: PangolinAPIClient) {
        self.client = client
    }

    func listTargets(resourceId: Int, limit: Int = 1_000, offset: Int = 0) async throws -> PublicTargetsPage {
        let response: PangolinResponse<PublicTargetsPage> = try await client.send(
            .get,
            path: "/public-resource/\(resourceId)/targets",
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        guard let data = response.data else { throw PangolinAPIError.decoding }
        return data
    }

    func listAllTargets(resourceId: Int, limit: Int = 1_000) async throws -> [Target] {
        var targets: [Target] = []
        var requestedOffset = 0

        while true {
            let result = try await listTargets(resourceId: resourceId, limit: limit, offset: requestedOffset)
            targets.append(contentsOf: result.targets)
            guard let pagination = result.pagination,
                  targets.count < pagination.total else { return targets }
            guard !result.targets.isEmpty else { throw PangolinAPIError.decoding }

            let nextOffset = pagination.offset + pagination.limit
            guard nextOffset > requestedOffset else { throw PangolinAPIError.decoding }
            requestedOffset = nextOffset
        }
    }

    func createTarget(resourceId: Int, configuration: PublicTargetConfiguration) async throws -> Target {
        let response: PangolinResponse<Target> = try await client.send(
            .put,
            path: "/public-resource/\(resourceId)/target",
            body: try body(for: configuration)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        guard let data = response.data else { throw PangolinAPIError.decoding }
        return data
    }

    func updateTarget(targetId: Int, configuration: PublicTargetConfiguration) async throws -> Target {
        let response: PangolinResponse<Target> = try await client.send(
            .post,
            path: "/target/\(targetId)",
            body: try body(for: configuration)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
        guard let data = response.data else { throw PangolinAPIError.decoding }
        return data
    }

    func deleteTarget(targetId: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .delete,
            path: "/target/\(targetId)"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }

    private func body(for configuration: PublicTargetConfiguration) throws -> TargetBody {
        guard (1...65_535).contains(configuration.port) else {
            throw PangolinAPIError.serverRejected(status: 400, message: "INVALID_PORT")
        }
        guard configuration.rewritePath == nil || configuration.path != nil else {
            throw PangolinAPIError.serverRejected(status: 400, message: "PATH_REQUIRED")
        }
        var healthCheckConfiguration = configuration.healthCheckConfiguration
        if let hostname = configuration.healthCheckHostname {
            healthCheckConfiguration.hostname = hostname
        }
        if configuration.healthCheck {
            healthCheckConfiguration = healthCheckConfiguration.applyingDefaults(
                hostname: configuration.ip, port: configuration.port, method: configuration.method
            )
        }
        return TargetBody(
            siteId: configuration.siteId,
            ip: configuration.ip,
            port: configuration.port,
            method: configuration.method,
            enabled: configuration.enabled,
            hcEnabled: configuration.healthCheck,
            healthCheckConfiguration: healthCheckConfiguration,
            path: configuration.path,
            pathMatchType: configuration.pathMatchType,
            rewritePath: configuration.rewritePath,
            rewritePathType: configuration.rewritePathType
        )
    }
}

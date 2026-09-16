import Foundation

struct TargetHealthCheckConfiguration: Codable {
    struct Header: Codable {
        var name: String
        var value: String
    }

    var hostname: String?
    var port: Int?
    var mode: String?
    var scheme: String?
    var path: String?
    var method: String?
    var interval: Int?
    var unhealthyInterval: Int?
    var timeout: Int?
    var headers: [Header]?
    var followRedirects: Bool?
    var status: Int?
    var tlsServerName: String?
    var healthyThreshold: Int?
    var unhealthyThreshold: Int?

    private enum CodingKeys: String, CodingKey {
        case hostname = "hcHostname", port = "hcPort", mode = "hcMode"
        case scheme = "hcScheme", path = "hcPath", method = "hcMethod"
        case interval = "hcInterval", unhealthyInterval = "hcUnhealthyInterval"
        case timeout = "hcTimeout", headers = "hcHeaders"
        case followRedirects = "hcFollowRedirects", status = "hcStatus"
        case tlsServerName = "hcTlsServerName"
        case healthyThreshold = "hcHealthyThreshold", unhealthyThreshold = "hcUnhealthyThreshold"
    }

    func applyingDefaults(hostname: String, port: Int, method: PublicTargetMethod?) -> Self {
        var settings = self
        if settings.hostname?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            settings.hostname = hostname
        }
        settings.port = settings.port ?? port
        settings.mode = settings.mode ?? (method == nil ? "tcp" : "http")
        settings.scheme = settings.scheme ?? (method == .https ? "https" : "http")
        settings.path = settings.path ?? "/"
        settings.method = settings.method ?? "GET"
        settings.interval = settings.interval ?? 30
        settings.unhealthyInterval = settings.unhealthyInterval ?? 30
        settings.timeout = settings.timeout ?? 5
        settings.followRedirects = settings.followRedirects ?? true
        settings.tlsServerName = settings.tlsServerName ?? ""
        settings.healthyThreshold = settings.healthyThreshold ?? 1
        settings.unhealthyThreshold = settings.unhealthyThreshold ?? 1
        // A missing status retains Newt's default of accepting all 2xx responses.
        return settings
    }
}

extension TargetHealthCheckConfiguration {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hostname = try container.decodeIfPresent(String.self, forKey: .hostname)
        port = try container.decodeIfPresent(Int.self, forKey: .port)
        mode = try container.decodeIfPresent(String.self, forKey: .mode)
        scheme = try container.decodeIfPresent(String.self, forKey: .scheme)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        method = try container.decodeIfPresent(String.self, forKey: .method)
        interval = try container.decodeIfPresent(Int.self, forKey: .interval)
        unhealthyInterval = try container.decodeIfPresent(Int.self, forKey: .unhealthyInterval)
        timeout = try container.decodeIfPresent(Int.self, forKey: .timeout)
        // List responses return an array; mutation responses can return stored JSON text.
        if let encodedHeaders = try? container.decode(String.self, forKey: .headers) {
            headers = try JSONDecoder().decode([Header]?.self, from: Data(encodedHeaders.utf8))
        } else {
            headers = try container.decodeIfPresent([Header].self, forKey: .headers)
        }
        followRedirects = try container.decodeIfPresent(Bool.self, forKey: .followRedirects)
        status = try container.decodeIfPresent(Int.self, forKey: .status)
        tlsServerName = try container.decodeIfPresent(String.self, forKey: .tlsServerName)
        healthyThreshold = try container.decodeIfPresent(Int.self, forKey: .healthyThreshold)
        unhealthyThreshold = try container.decodeIfPresent(Int.self, forKey: .unhealthyThreshold)
    }
}

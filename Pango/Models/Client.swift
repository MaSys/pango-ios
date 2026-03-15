//
//  Client.swift
//  Pango
//

struct Client: Decodable {
    var clientId: String
    var name: String?
    var fingerprint: String?
    var status: String?
    var lastSeen: String?
    var ip: String?
    var os: String?
    var version: String?
    var userId: String?
    var userEmail: String?
    var siteId: Int?
    var siteName: String?
    var approved: Bool?
    var blocked: Bool?
    var archived: Bool?
    var dateCreated: String?

    var displayStatus: String {
        if blocked == true { return "Blocked" }
        if archived == true { return "Archived" }
        if approved == false { return "Pending" }
        return status?.capitalized ?? "Active"
    }

    var isActive: Bool {
        return blocked != true && archived != true
    }
}

extension Client {
    static func fake() -> Client {
        return Client(
            clientId: "abc123",
            name: "Test Client",
            fingerprint: "aa:bb:cc:dd",
            status: "active",
            lastSeen: "2025-01-01T00:00:00Z",
            ip: "192.168.1.1",
            os: "macOS",
            version: "1.0.0",
            approved: true,
            blocked: false,
            archived: false
        )
    }
}

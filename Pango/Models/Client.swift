//
//  Client.swift
//  Pango
//

struct Client: Decodable {
    var clientId: Int
    var orgId: String?
    var name: String?
    var pubKey: String?
    var subnet: String?
    var megabytesIn: Float?
    var megabytesOut: Float?
    var orgName: String?
    var type: String?
    var online: Bool?
    var olmVersion: String?
    var userId: String?
    var username: String?
    var userEmail: String?
    var niceId: String?
    var agent: String?
    var approvalState: String?
    var olmArchived: Bool?
    var archived: Bool?
    var blocked: Bool?

    var displayStatus: String {
        if blocked == true { return "Blocked" }
        if archived == true { return "Archived" }
        if approvalState == "pending" { return "Pending" }
        if online == true { return "Online" }
        return "Offline"
    }

    var isActive: Bool {
        return online == true && blocked != true && archived != true
    }

    var isPending: Bool {
        return approvalState == "pending"
    }

    var clientIdString: String {
        return String(clientId)
    }
}

extension Client {
    static func fake() -> Client {
        return Client(
            clientId: 1,
            name: "Test Client",
            type: "olm",
            online: true,
            olmVersion: "1.0.0",
            approvalState: "approved",
            archived: false,
            blocked: false
        )
    }
}

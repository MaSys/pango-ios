//
//  DeviceApproval.swift
//  Pango
//

struct DeviceApproval: Decodable {
    var approvalId: String
    var deviceName: String?
    var fingerprint: String?
    var userId: String?
    var userEmail: String?
    var status: String?
    var requestedAt: String?
    var ip: String?
    var os: String?

    var isPending: Bool {
        return status?.lowercased() == "pending"
    }
}

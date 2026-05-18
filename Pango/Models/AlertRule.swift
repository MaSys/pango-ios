//
//  AlertRule.swift
//  Pango
//
//  Created by Yaser Almasri on 17/05/26.
//

struct AlertRule: Decodable {
    var alertId: Int
    var name: String
    var triggerType: String
    var notificationMethod: String
    var notificationTarget: String
    var enabled: Bool
}

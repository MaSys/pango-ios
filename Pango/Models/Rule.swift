//
//  Rule.swift
//  Pango
//

struct Rule: Decodable {
    var ruleId: Int
    var resourceId: Int?
    var action: String
    var match: String?
    var value: String?
    var priority: Int?
    var enabled: Bool?
}

extension Rule {
    var displayAction: String {
        return action.capitalized
    }

    var displayMatch: String {
        return match?.capitalized ?? "Unknown"
    }

    static func fake() -> Rule {
        return Rule(
            ruleId: 1,
            resourceId: 1,
            action: "allow",
            match: "path",
            value: "/api/*",
            priority: 1,
            enabled: true
        )
    }
}

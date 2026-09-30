import Foundation

enum PrivateResourceAccessKind: String, CaseIterable, Sendable {
    case users, roles, clients

    var titleKey: String { rawValue.uppercased() }
}

struct PrivateResourceAccessOption: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    var isReadOnly = false
}

struct PrivateResourceAccessSelection {
    let options: [PrivateResourceAccessOption]
    private(set) var selectedIDs: Set<String>

    init(assigned: [PrivateResourceAccessOption], available: [PrivateResourceAccessOption]) {
        // Keep assigned entries even when the inventory omits them.
        var merged = assigned
        var indices = Dictionary(merged.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
        for option in available {
            if let index = indices[option.id] {
                merged[index].isReadOnly = merged[index].isReadOnly || option.isReadOnly
            } else {
                indices[option.id] = merged.count
                merged.append(option)
            }
        }
        options = merged
        selectedIDs = Set(assigned.map(\.id))
    }

    var editableIDs: Set<String> {
        selectedIDs.subtracting(options.filter(\.isReadOnly).map(\.id))
    }

    mutating func toggle(id: String) {
        guard let option = options.first(where: { $0.id == id }), !option.isReadOnly else { return }
        if selectedIDs.contains(id) { selectedIDs.remove(id) }
        else { selectedIDs.insert(id) }
    }
}

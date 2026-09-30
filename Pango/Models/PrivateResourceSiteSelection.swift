struct PrivateResourceSiteSelection {
    struct Option: Identifiable {
        let id: Int
        let name: String
    }

    private(set) var siteIds: [Int]
    private var knownSiteIds: [Int]

    init(siteIds: [Int] = []) {
        var seen = Set<Int>()
        self.siteIds = siteIds.filter { seen.insert($0).inserted }
        knownSiteIds = self.siteIds
    }

    mutating func toggle(_ siteId: Int) {
        if !knownSiteIds.contains(siteId) { knownSiteIds.append(siteId) }
        if siteIds.contains(siteId) { siteIds.removeAll { $0 == siteId } }
        else { siteIds.append(siteId) }
    }

    func options(available: [Site], names: [Int: String] = [:]) -> [Option] {
        let currentNames = Dictionary(available.map { ($0.siteId, $0.name) }, uniquingKeysWith: { first, _ in first })
        var seen = Set<Int>()
        // Inventory refreshes never silently remove an existing assignment.
        return (knownSiteIds + available.map(\.siteId)).compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return Option(id: id, name: currentNames[id] ?? names[id] ?? String(id))
        }
    }
}

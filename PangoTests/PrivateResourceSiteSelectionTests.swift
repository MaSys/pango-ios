import Testing
@testable import Pango

struct PrivateResourceSiteSelectionTests {
    @Test("keeps existing site order and removes duplicates")
    func preservesOrder() {
        let selection = PrivateResourceSiteSelection(siteIds: [7, 3, 7])
        #expect(selection.siteIds == [7, 3])
    }

    @Test("selection changes only when explicitly toggled")
    func togglesSites() {
        var selection = PrivateResourceSiteSelection(siteIds: [7, 3])
        selection.toggle(8)
        #expect(selection.siteIds == [7, 3, 8])
        selection.toggle(3)
        #expect(selection.siteIds == [7, 8])
    }

    @Test("keeps assigned sites missing from inventory visible")
    func preservesUnavailableSites() {
        let selection = PrivateResourceSiteSelection(siteIds: [7, 3])
        let options = selection.options(available: [Site(siteId: 8, name: "New", type: "newt")], names: [7: "Existing"])
        #expect(options.map(\.id) == [7, 3, 8])
        #expect(options.map(\.name) == ["Existing", "3", "New"])
        #expect(selection.siteIds == [7, 3])
    }

    @Test("an unavailable assignment can be deselected and reselected before saving")
    func retainsDeselectedOption() {
        var selection = PrivateResourceSiteSelection(siteIds: [7])
        selection.toggle(7)
        #expect(selection.siteIds.isEmpty)
        #expect(selection.options(available: []).map(\.id) == [7])
        selection.toggle(7)
        #expect(selection.siteIds == [7])
    }

    @Test("uses current site names without duplicating selected options")
    func prefersCurrentNames() {
        let selection = PrivateResourceSiteSelection(siteIds: [7])
        let options = selection.options(available: [Site(siteId: 7, name: "Renamed", type: "newt")], names: [7: "Old"])
        #expect(options.map(\.name) == ["Renamed"])
    }
}

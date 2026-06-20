import Foundation
import Combine

/// Persists discovered listings to disk and tracks which ones are new.
///
/// The store is the single source of truth for the Results screen. `merge(_:)` is
/// called by the SearchCoordinator after each run (manual or background) and returns
/// the listings that are genuinely new this run, so the caller can notify.
@MainActor
final class ListingStore: ObservableObject {
    @Published private(set) var listings: [Listing] = []
    @Published private(set) var lastUpdated: Date?
    @Published var isSearching = false

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("listings.json")
    }()
    private let metaKey = "scoutfinder.lastUpdated.v1"

    init() {
        load()
        if let t = UserDefaults.standard.object(forKey: metaKey) as? Date { lastUpdated = t }
    }

    var newCount: Int { listings.filter { $0.isNew }.count }

    /// Merge a freshly-fetched batch. Existing listings (matched by id == URL) are
    /// kept with their original `firstSeen`; brand-new ones are inserted as `isNew`.
    /// Returns the newly-discovered listings.
    @discardableResult
    func merge(_ fetched: [Listing]) -> [Listing] {
        var byID = Dictionary(uniqueKeysWithValues: listings.map { ($0.id, $0) })
        var brandNew: [Listing] = []

        for var item in fetched {
            if let existing = byID[item.id] {
                // Preserve discovery metadata; refresh mutable display fields.
                item.firstSeen = existing.firstSeen
                item.isNew = existing.isNew
                byID[item.id] = item
            } else {
                item.firstSeen = Date()
                item.isNew = true
                byID[item.id] = item
                brandNew.append(item)
            }
        }

        listings = byID.values.sorted { a, b in
            // New first, then most-recently-seen.
            if a.isNew != b.isNew { return a.isNew && !b.isNew }
            return a.firstSeen > b.firstSeen
        }
        lastUpdated = Date()
        UserDefaults.standard.set(lastUpdated, forKey: metaKey)
        save()
        return brandNew
    }

    /// Clear the "NEW" flags once the user has reviewed the feed.
    func markAllSeen() {
        guard newCount > 0 else { return }
        listings = listings.map { var l = $0; l.isNew = false; return l }
        save()
    }

    func clearAll() {
        listings = []
        save()
    }

    // MARK: - Disk

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Listing].self, from: data) else { return }
        listings = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(listings) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

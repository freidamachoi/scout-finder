import Foundation

/// A single vehicle listing discovered by an automated provider.
struct Listing: Identifiable, Codable, Hashable {
    /// Stable identity = the canonical listing URL. Used for de-duplication and
    /// "have I seen this before?" tracking across runs.
    var id: String { url.absoluteString }

    let title: String
    let url: URL
    let price: String?          // display string, e.g. "$24,500"
    let priceValue: Double?     // parsed numeric value when available, for sorting
    let imageURL: URL?
    let location: String?
    let sourceID: String        // Source.id this came from
    let sourceName: String
    let postedAt: Date?

    /// When this listing was first seen by the app. Set by ListingStore on insert.
    var firstSeen: Date = Date()

    /// Marked true on the run that first discovered it; cleared once the user has
    /// viewed the results. Drives the "NEW" badge and notifications.
    var isNew: Bool = true
}

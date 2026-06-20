import Foundation

/// How the app handles a given site.
enum SourceKind: String, Codable {
    /// The app fetches and parses listings itself (no login, parseable feed/HTML).
    case automated
    /// The app cannot reliably scrape it (login wall, anti-bot, JS-only, or a phone
    /// dealer). Instead it provides a one-tap prebuilt search + exact criteria the
    /// user runs inside the site.
    case manual
}

/// Buckets mirror the user's source list so the Browse screen reads naturally.
enum SourceCategory: String, Codable, CaseIterable, Identifiable {
    case auction          = "Auction Platforms"
    case classicMarket    = "Classic Car Marketplaces"
    case general          = "General / Local / Peer-to-Peer"
    case specialist       = "IH / Scout Specialists & Community"
    case barnFind         = "Barn-Find / Curated"
    case regional         = "Regional (NC / VA)"

    var id: String { rawValue }
}

/// A searchable source. Automated sources additionally carry a `providerID`
/// matching a `SearchProvider`; manual sources carry only the deep link + criteria.
struct Source: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: SourceCategory
    let kind: SourceKind
    /// Prebuilt deep link that runs (or sets up) the Scout search inside the site.
    let searchURL: URL
    /// Exact, human-readable criteria to run within the site — shown verbatim so the
    /// user can reproduce/refine the search behind a login.
    let criteria: String
    let requiresLogin: Bool
    /// For `.automated` sources only — links to a SearchProvider implementation.
    let providerID: String?
    /// Phone numbers, contacts, or notes (e.g. specialist dealers).
    let notes: String?
}

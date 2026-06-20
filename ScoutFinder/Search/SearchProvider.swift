import Foundation

/// A source the app can fetch and parse on its own. Conform a new type, give it a
/// unique `providerID`, register it in `SearchCoordinator.providers`, and reference
/// that id from the matching `Source` in `SourceRegistry`.
protocol SearchProvider {
    /// Stable id, also referenced by `Source.providerID`.
    static var providerID: String { get }
    var providerID: String { get }

    /// The `Source.id` this provider feeds results into.
    var sourceID: String { get }

    /// Fetch listings matching the user's settings. Should not throw for "no results";
    /// throw only on network/parse failure so the coordinator can log and continue.
    func fetch(settings: SearchSettings) async throws -> [Listing]
}

extension SearchProvider {
    var providerID: String { Self.providerID }
}

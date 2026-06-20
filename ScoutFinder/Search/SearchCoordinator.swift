import Foundation

/// Runs every automated provider concurrently, merges results into the ListingStore,
/// and reports how many listings are brand new. Used by both the manual "Search Now"
/// button and the daily background task.
struct SearchCoordinator {

    /// Register automated providers here. Each must have a matching `.automated`
    /// entry in `SourceRegistry` (by `providerID`).
    static let providers: [SearchProvider] = [
        EbayProvider(),
        CraigslistProvider()
    ]

    struct RunResult {
        let totalFetched: Int
        let newListings: [Listing]
        let errors: [String]
    }

    /// Execute a full search. Pure with respect to UI — pass the store to persist into.
    @discardableResult
    static func run(settings: SearchSettings, store: ListingStore) async -> RunResult {
        await MainActor.run { store.isSearching = true }
        defer { Task { @MainActor in store.isSearching = false } }

        var fetched: [Listing] = []
        var errors: [String] = []

        await withTaskGroup(of: Result<[Listing], Error>.self) { group in
            for provider in providers {
                group.addTask {
                    do { return .success(try await provider.fetch(settings: settings)) }
                    catch { return .failure(error) }
                }
            }
            for await result in group {
                switch result {
                case .success(let list): fetched.append(contentsOf: list)
                case .failure(let err): errors.append(String(describing: err))
                }
            }
        }

        let brandNew = await MainActor.run { store.merge(fetched) }
        return RunResult(totalFetched: fetched.count, newListings: brandNew, errors: errors)
    }
}

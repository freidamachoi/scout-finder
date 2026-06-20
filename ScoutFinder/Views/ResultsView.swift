import SwiftUI

/// The automated-search feed: results pulled by the eBay + Craigslist providers, with
/// a manual "Search Now" button, pull-to-refresh, and NEW badges.
struct ResultsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var listingStore: ListingStore

    @State private var openURL: URL?
    @State private var banner: String?

    var body: some View {
        NavigationStack {
            Group {
                if listingStore.listings.isEmpty {
                    emptyState
                } else {
                    listView
                }
            }
            .navigationTitle("Scouts for Sale")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await runSearch() }
                    } label: {
                        if listingStore.isSearching {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(listingStore.isSearching)
                }
            }
            .safariSheet(url: $openURL)
            .onAppear { listingStore.markAllSeen() }
        }
    }

    private var listView: some View {
        List {
            if let lastUpdated = listingStore.lastUpdated {
                Section {
                    HStack {
                        Text("Last searched")
                        Spacer()
                        Text(lastUpdated, style: .relative) + Text(" ago")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            Section {
                ForEach(listingStore.listings) { listing in
                    Button { openURL = listing.url } label: {
                        ListingRow(listing: listing)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("\(listingStore.listings.count) listings · automated (eBay + Craigslist)")
            } footer: {
                Text("Other sources are searched manually — see the Sources tab.")
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await runSearch() }
        .overlay(alignment: .bottom) { bannerView }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No listings yet", systemImage: "magnifyingglass")
        } description: {
            Text("Tap Search Now to scan eBay and Craigslist, or open the Sources tab to run guided searches on every other site.")
        } actions: {
            Button("Search Now") { Task { await runSearch() } }
                .buttonStyle(.borderedProminent)
                .disabled(listingStore.isSearching)
        }
    }

    @ViewBuilder private var bannerView: some View {
        if let banner {
            Text(banner)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func runSearch() async {
        let result = await SearchCoordinator.run(settings: settingsStore.settings, store: listingStore)
        if settingsStore.settings.notifyOnNew {
            await NotificationManager.shared.notifyNewListings(result.newListings)
        }
        let msg: String
        if result.totalFetched == 0 && !result.errors.isEmpty {
            msg = "Search failed — check your connection."
        } else if result.newListings.isEmpty {
            msg = "No new listings (\(result.totalFetched) found)."
        } else {
            msg = "\(result.newListings.count) new listing\(result.newListings.count == 1 ? "" : "s")!"
        }
        withAnimation { banner = msg }
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        withAnimation { banner = nil }
    }
}

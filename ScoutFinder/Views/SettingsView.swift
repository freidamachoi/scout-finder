import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var listingStore: ListingStore

    @State private var newRegion = ""

    private var s: Binding<SearchSettings> { $settingsStore.settings }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily search") {
                    Toggle("Search automatically each day", isOn: s.dailyEnabled)
                    Toggle("Notify me of new listings", isOn: s.notifyOnNew)
                    Text("iOS schedules background runs opportunistically (when charging / on Wi-Fi). Use Search Now for an immediate scan.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button {
                        Task {
                            let r = await SearchCoordinator.run(settings: settingsStore.settings, store: listingStore)
                            if settingsStore.settings.notifyOnNew {
                                await NotificationManager.shared.notifyNewListings(r.newListings)
                            }
                        }
                    } label: {
                        Label("Search Now", systemImage: "magnifyingglass")
                    }
                    .disabled(listingStore.isSearching)
                }

                Section("Model years") {
                    Stepper("From \(String(s.wrappedValue.minYear))", value: s.minYear, in: 1955...1975)
                    Stepper("To \(String(s.wrappedValue.maxYear))", value: s.maxYear, in: 1955...1975)
                }

                Section("Location") {
                    TextField("ZIP code", text: s.zip)
                        .keyboardType(.numberPad)
                }

                Section {
                    ForEach(settingsStore.settings.craigslistRegions, id: \.self) { region in
                        Text(region)
                    }
                    .onDelete { idx in
                        settingsStore.settings.craigslistRegions.remove(atOffsets: idx)
                    }
                    HStack {
                        TextField("Add region (e.g. atlanta)", text: $newRegion)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button("Add") {
                            let r = newRegion.trimmingCharacters(in: .whitespaces).lowercased()
                            guard !r.isEmpty, !settingsStore.settings.craigslistRegions.contains(r) else { return }
                            settingsStore.settings.craigslistRegions.append(r)
                            newRegion = ""
                        }
                        .disabled(newRegion.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Craigslist regions")
                } footer: {
                    Text("Use the subdomain from the region's Craigslist URL, e.g. raleigh.craigslist.org → \"raleigh\".")
                }

                Section {
                    SecureField("eBay Browse API token (optional)", text: s.ebayAPIKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("eBay API")
                } footer: {
                    Text("Optional. With a token the app uses eBay's official API for reliable results; without one it falls back to scraping the public search page. See README → \"eBay API key\".")
                }

                Section {
                    Button(role: .destructive) {
                        listingStore.clearAll()
                    } label: {
                        Label("Clear saved listings", systemImage: "trash")
                    }
                }

                Section {
                    Text("Scout Finder \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

import SwiftUI

/// Browse every source. Automated sources are tagged "Auto"; everything else is a
/// one-tap guided manual search showing the exact criteria to run inside the site.
struct SourcesView: View {
    @State private var openURL: URL?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Tap any source to see exact search criteria and open it. \"Auto\" sources are also scanned automatically and feed the Results tab.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(SourceRegistry.grouped(), id: \.0) { category, sources in
                    Section(category.rawValue) {
                        ForEach(sources) { source in
                            NavigationLink {
                                SourceDetailView(source: source, openURL: $openURL)
                            } label: {
                                sourceRow(source)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sources")
            .safariSheet(url: $openURL)
        }
    }

    private func sourceRow(_ source: Source) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name).font(.body)
                if let notes = source.notes {
                    Text(notes).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if source.kind == .automated {
                tag("Auto", color: .green)
            }
            if source.requiresLogin {
                tag("Login", color: .orange)
            }
        }
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}

struct SourceDetailView: View {
    let source: Source
    @Binding var openURL: URL?

    var body: some View {
        List {
            Section {
                Button {
                    openURL = source.searchURL
                } label: {
                    Label(source.requiresLogin ? "Open & sign in" : "Open search",
                          systemImage: "safari.fill")
                }
                .font(.headline)
            } footer: {
                Text(source.searchURL.absoluteString).font(.caption2)
            }

            Section("Search criteria") {
                Text(source.criteria)
                    .font(.callout)
                    .textSelection(.enabled)
            }

            if source.kind == .automated {
                Section {
                    Label("This source is searched automatically and appears in the Results tab.",
                          systemImage: "bolt.fill")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            if source.requiresLogin {
                Section {
                    Label("This site needs an account. Sign in, then run the criteria above. Save the search inside the site for its own alerts.",
                          systemImage: "lock.fill")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            if let notes = source.notes {
                Section("Notes") {
                    Text(notes).font(.callout).textSelection(.enabled)
                }
            }
        }
        .navigationTitle(source.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

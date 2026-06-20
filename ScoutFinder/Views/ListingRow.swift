import SwiftUI

struct ListingRow: View {
    let listing: Listing

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if listing.isNew {
                        Text("NEW")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    Text(listing.sourceName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(listing.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if let price = listing.price {
                        Text(price).font(.subheadline.bold()).foregroundStyle(.green)
                    }
                    if let loc = listing.location {
                        Text(loc).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var thumbnail: some View {
        if let url = listing.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: placeholder
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            placeholder.frame(width: 64, height: 64)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .overlay(Image(systemName: "car.fill").foregroundStyle(.secondary))
    }
}

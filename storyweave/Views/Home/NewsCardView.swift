import SwiftUI

struct NewsCardView: View {
    let article: NewsArticle
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = URL(string: article.url) {
                openURL(url)
            }
        } label: {
            SWCard {
                VStack(alignment: .leading, spacing: swSpacing * 1.5) {
                    if let imageURL = article.urlToImage, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.swSurfaceRaised)
                                .overlay(
                                    Image(systemName: "newspaper")
                                        .foregroundStyle(Color.swTextSecondary)
                                        .font(.title2)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    HStack(spacing: swSpacing) {
                        SWPillBadge(text: article.source.name, color: Color.swAccentPrimary)
                        Spacer()
                        Text(formattedDate)
                            .font(.swCaption)
                            .foregroundStyle(Color.swTextSecondary)
                    }

                    Text(article.title)
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)

                    if let description = article.description, !description.isEmpty {
                        Text(description)
                            .font(.swBody)
                            .foregroundStyle(Color.swTextSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    // "Read more" indicator
                    HStack {
                        Spacer()
                        Label("Read full article", systemImage: "safari")
                            .font(.swCaption)
                            .foregroundStyle(Color.swAccentLight)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(article.title)
    }

    private var formattedDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: article.publishedAt) {
            return date.formatted(.relative(presentation: .named))
        }
        return article.publishedAt
    }
}

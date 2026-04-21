import SwiftUI

struct PostCardView: View {
    let post: Post
    let isLiked: Bool
    let onLike: () -> Void
    let onTap: () -> Void

    var body: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing * 1.5) {
                headerRow
                bodyText
                imageIfPresent
                actionRow
            }
        }
        .onTapGesture { onTap() }
        .accessibilityElement(children: .contain)
    }

    // MARK: — Sub-views

    private var headerRow: some View {
        HStack(spacing: swSpacing * 1.5) {
            avatarCircle
            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(.swHeadline)
                    .foregroundStyle(Color.swTextPrimary)
                Text(post.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
            }
            Spacer()
        }
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(Color.swAccentDeep)
                .frame(width: 36, height: 36)
            Text(String(post.authorName.prefix(1)).uppercased())
                .font(.swHeadline)
                .foregroundStyle(Color.swAccentLight)
        }
    }

    private var bodyText: some View {
        Text(post.body)
            .font(.swBody)
            .foregroundStyle(Color.swTextPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(4)
    }

    @ViewBuilder
    private var imageIfPresent: some View {
        if let imageURL = post.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Rectangle()
                    .fill(Color.swSurface)
                    .frame(height: 160)
                    .overlay(ProgressView().tint(Color.swAccentPrimary))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var actionRow: some View {
        HStack(spacing: swSpacing * 2) {
            Button(action: onLike) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? Color.swDanger : Color.swTextSecondary)
                    Text("\(post.likeCount)")
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }
            }
            .accessibilityLabel(isLiked ? "Unlike" : "Like")

            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .foregroundStyle(Color.swTextSecondary)
                Text("Comment")
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
            }
            .accessibilityLabel("View comments")

            Spacer()

            Text("View post")
                .font(.swCaption)
                .foregroundStyle(Color.swAccentLight)
        }
    }
}

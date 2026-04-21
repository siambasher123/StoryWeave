import SwiftUI

struct PostCardView: View {
    let post: Post
    let isLiked: Bool
    let currentUserID: String?
    let onLike: () -> Void
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    let onEdit: (() -> Void)?

    @State private var attachedCharacter: Character? = nil
    @State private var attachedSkill: Skill? = nil

    init(post: Post,
         isLiked: Bool,
         currentUserID: String? = nil,
         onLike: @escaping () -> Void,
         onTap: @escaping () -> Void,
         onDelete: (() -> Void)? = nil,
         onEdit: (() -> Void)? = nil) {
        self.post = post
        self.isLiked = isLiked
        self.currentUserID = currentUserID
        self.onLike = onLike
        self.onTap = onTap
        self.onDelete = onDelete
        self.onEdit = onEdit
    }

    private var isOwn: Bool { post.authorUID == currentUserID }

    var body: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing * 1.5) {
                headerRow
                bodyText
                attachmentRow
                imageIfPresent
                actionRow
            }
        }
        .onTapGesture { onTap() }
        .task {
            if let cid = post.attachedCharacterID, attachedCharacter == nil {
                attachedCharacter = try? await FirestoreService.shared.fetchCharacter(id: cid)
            }
            if let sid = post.attachedSkillID, attachedSkill == nil {
                attachedSkill = try? await FirestoreService.shared.fetchSkill(id: sid)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: — Sub-views

    private var headerRow: some View {
        HStack(spacing: swSpacing * 1.5) {
            SWAvatarView(name: post.authorName, size: 36, color: .swAccentPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(.swHeadline)
                    .foregroundStyle(Color.swTextPrimary)
                Text(post.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
            }
            Spacer()
            if isOwn {
                Menu {
                    if let onEdit {
                        Button { onEdit() } label: {
                            Label("Edit Post", systemImage: "pencil")
                        }
                    }
                    if let onDelete {
                        Button(role: .destructive) { onDelete() } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundStyle(Color.swTextSecondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Post options")
            }
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

    @ViewBuilder
    private var attachmentRow: some View {
        if let character = attachedCharacter {
            attachmentChip(
                icon: archetypeIcon(character.archetype),
                iconColor: Color.swAccentPrimary,
                title: character.name,
                subtitle: "\(character.archetype.rawValue.capitalized) · Lv\(character.level)",
                trailing: "HP \(character.hp)"
            )
        }
        if let skill = attachedSkill {
            attachmentChip(
                icon: statIcon(skill.statAffected),
                iconColor: Color.swAccentHighlight,
                title: skill.name,
                subtitle: "\(skill.statAffected.rawValue.uppercased()) \(skill.modifier >= 0 ? "+" : "")\(skill.modifier) · \(skill.targetType.rawValue.capitalized)",
                trailing: nil
            )
        }
    }

    private func attachmentChip(icon: String, iconColor: Color, title: String, subtitle: String, trailing: String?) -> some View {
        HStack(spacing: swSpacing) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.caption)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextPrimary)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.swTextSecondary)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.swTextSecondary)
            }
        }
        .padding(.horizontal, swSpacing * 1.5)
        .padding(.vertical, swSpacing)
        .background(Color.swSurfaceRaised, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(iconColor.opacity(0.25), lineWidth: 1))
    }

    private func archetypeIcon(_ arch: Archetype) -> String {
        switch arch {
        case .warrior: return "shield.fill"
        case .mage:    return "sparkles"
        case .rogue:   return "eye.slash.fill"
        case .cleric:  return "cross.fill"
        case .ranger:  return "target"
        case .tank:    return "shield.lefthalf.filled"
        }
    }

    private func statIcon(_ stat: StatType) -> String {
        switch stat {
        case .hp:    return "heart.fill"
        case .atk:   return "bolt.fill"
        case .def:   return "shield.fill"
        case .dex:   return "figure.run"
        case .intel: return "brain"
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

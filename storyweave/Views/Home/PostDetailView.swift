import SwiftUI
import Combine

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var reactions: [Reaction] = []
    @Published var comments: [Comment] = []
    @Published var commentText: String = ""
    @Published var replyingTo: Comment?
    @Published var editingComment: Comment?
    @Published var isSubmitting = false
    @Published var myReactionEmoji: String?
    @Published var showReactionGivers = false
    @Published var attachedCharacter: Character? = nil
    @Published var attachedSkill: Skill? = nil

    let post: Post
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private var reactionTask: Task<Void, Never>?
    private var commentTask: Task<Void, Never>?

    var currentUserID: String? { auth.currentUserID }

    init(post: Post) {
        self.post = post
    }

    func startListening() {
        reactionTask = Task {
            for await r in firestore.reactionsStream(postID: post.id) {
                reactions = r.sorted { $0.timestamp < $1.timestamp }
                if let uid = auth.currentUserID {
                    myReactionEmoji = reactions.first(where: { $0.uid == uid })?.emoji
                }
            }
        }
        commentTask = Task {
            for await c in firestore.commentsStream(postID: post.id) {
                comments = c
            }
        }
        loadAttachments()
    }

    private func loadAttachments() {
        if let cid = post.attachedCharacterID {
            Task { attachedCharacter = try? await firestore.fetchCharacter(id: cid) }
        }
        if let sid = post.attachedSkillID {
            Task { attachedSkill = try? await firestore.fetchSkill(id: sid) }
        }
    }

    func stopListening() {
        reactionTask?.cancel()
        commentTask?.cancel()
    }

    func toggleReaction(emoji: String) {
        guard let uid = auth.currentUserID else { return }
        if myReactionEmoji == emoji {
            Task { try? await firestore.removeReaction(postID: post.id, uid: uid) }
            myReactionEmoji = nil
        } else {
            Task {
                let displayName: String
                if let profile = try? await firestore.fetchUserProfile(uid: uid) {
                    displayName = profile.displayName
                } else {
                    displayName = "Adventurer"
                }
                try? firestore.react(postID: post.id, emoji: emoji, uid: uid, displayName: displayName)
            }
            myReactionEmoji = emoji
        }
    }

    func submitComment() async {
        let body = commentText.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else { return }

        if var editing = editingComment {
            editing.body = body
            comments = comments.map { $0.id == editing.id ? editing : $0 }
            try? firestore.updateComment(editing)
            commentText = ""
            editingComment = nil
            return
        }

        guard let uid = auth.currentUserID else { return }
        isSubmitting = true
        let displayName: String
        if let profile = try? await firestore.fetchUserProfile(uid: uid) {
            displayName = profile.displayName
        } else {
            displayName = "Adventurer"
        }
        let comment = Comment(
            id: UUID().uuidString,
            postID: post.id,
            parentCommentID: replyingTo?.id,
            authorUID: uid,
            authorName: displayName,
            body: body,
            timestamp: Date()
        )
        try? firestore.addComment(comment)
        commentText = ""
        replyingTo = nil
        isSubmitting = false
    }

    func startEditComment(_ comment: Comment) {
        replyingTo = nil
        editingComment = comment
        commentText = comment.body
    }

    func cancelEdit() {
        editingComment = nil
        commentText = ""
    }

    func deleteComment(_ comment: Comment) {
        comments.removeAll { $0.id == comment.id }
        Task { try? await firestore.deleteComment(commentID: comment.id, postID: post.id) }
    }
}

// MARK: — View

struct PostDetailView: View {
    let post: Post
    @StateObject private var vm: PostDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditPost = false
    @State private var showDeleteConfirm = false

    private var isOwnPost: Bool { vm.currentUserID == post.authorUID }

    init(post: Post) {
        self.post = post
        _vm = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: swSpacing * 3) {
                        postBody
                        attachmentSection
                        reactionBar
                        Divider().background(Color.swAccentDeep)
                        commentSection
                    }
                    .padding(swSpacing * 2)
                }

                VStack {
                    Spacer()
                    commentComposer
                }
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.swAccentPrimary)
                }
                if isOwnPost {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button { showEditPost = true } label: {
                                Label("Edit Post", systemImage: "pencil")
                            }
                            Button(role: .destructive) { showDeleteConfirm = true } label: {
                                Label("Delete Post", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(Color.swAccentPrimary)
                        }
                        .accessibilityLabel("Post options")
                    }
                }
            }
            .task { vm.startListening() }
            .onDisappear { vm.stopListening() }
            .sheet(isPresented: $vm.showReactionGivers) {
                reactionGiversSheet
            }
            .sheet(isPresented: $showEditPost) {
                CreatePostView(editing: post)
            }
            .confirmationDialog("Delete this post?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        try? await FirestoreService.shared.deletePost(postID: post.id)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: — Post body

    private var postBody: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            HStack {
                SWAvatarView(name: post.authorName, size: 40, color: .swAccentPrimary)
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
            Text(post.body)
                .font(.swBody)
                .foregroundStyle(Color.swTextPrimary)
        }
    }

    // MARK: — Attachments

    @ViewBuilder
    private var attachmentSection: some View {
        if let character = vm.attachedCharacter {
            characterCard(character)
        }
        if let skill = vm.attachedSkill {
            skillCard(skill)
        }
    }

    private func characterCard(_ character: Character) -> some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            Label("Attached Character", systemImage: "person.fill")
                .font(.swCaption)
                .foregroundStyle(Color.swTextSecondary)

            HStack(spacing: swSpacing * 2) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                    Text("\(character.archetype.rawValue.capitalized) · Level \(character.level)")
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentLight)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill").foregroundStyle(Color.swDanger).font(.caption2)
                        Text("\(character.hp)/\(character.maxHP)").font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill").foregroundStyle(Color.swWarning).font(.caption2)
                        Text("ATK \(character.atk)").font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    }
                }
            }

            if !character.loreDescription.isEmpty {
                Text(character.loreDescription)
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(swSpacing * 1.5)
        .background(Color.swSurfaceRaised, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.swAccentPrimary.opacity(0.3), lineWidth: 1))
    }

    private func skillCard(_ skill: Skill) -> some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            Label("Attached Skill", systemImage: "sparkles")
                .font(.swCaption)
                .foregroundStyle(Color.swTextSecondary)

            HStack(spacing: swSpacing * 2) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.name)
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                    Text("\(skill.statAffected.rawValue.uppercased()) \(skill.modifier >= 0 ? "+" : "")\(skill.modifier) · \(skill.targetType.rawValue.capitalized) · \(skill.cooldownTurns)T cooldown")
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentLight)
                }
                Spacer()
            }

            if !skill.description.isEmpty {
                Text(skill.description)
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
                    .lineLimit(3)
            }
        }
        .padding(swSpacing * 1.5)
        .background(Color.swSurfaceRaised, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.swAccentHighlight.opacity(0.3), lineWidth: 1))
    }

    // MARK: — Reaction bar

    private var reactionBar: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            HStack(spacing: swSpacing) {
                ForEach(["❤️", "😂", "😮", "👏"], id: \.self) { emoji in
                    reactionButton(emoji: emoji)
                }
                Spacer()
                if !vm.reactions.isEmpty {
                    Button { vm.showReactionGivers = true } label: {
                        Text("\(vm.reactions.count) reaction\(vm.reactions.count == 1 ? "" : "s")")
                            .font(.swCaption)
                            .foregroundStyle(Color.swAccentLight)
                    }
                    .accessibilityLabel("View \(vm.reactions.count) reactions")
                }
            }

            if !vm.reactions.isEmpty {
                reactionSummary
            }
        }
    }

    private func reactionButton(emoji: String) -> some View {
        let isSelected = vm.myReactionEmoji == emoji
        return Button {
            vm.toggleReaction(emoji: emoji)
        } label: {
            Text(emoji)
                .font(.title2)
                .padding(6)
                .background(isSelected ? Color.swAccentDeep : Color.clear)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(isSelected ? Color.swAccentPrimary : Color.clear, lineWidth: 1.5)
                )
        }
        .accessibilityLabel(isSelected ? "Remove \(emoji) reaction" : "React with \(emoji)")
    }

    private var reactionSummary: some View {
        let grouped = Dictionary(grouping: vm.reactions, by: \.emoji)
        return HStack(spacing: swSpacing) {
            ForEach(grouped.keys.sorted(), id: \.self) { emoji in
                HStack(spacing: 3) {
                    Text(emoji).font(.swCaption)
                    Text("\(grouped[emoji]!.count)")
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }
            }
        }
    }

    // MARK: — Comments

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: swSpacing * 2) {
            Text("Comments")
                .font(.swHeadline)
                .foregroundStyle(Color.swTextPrimary)

            let topLevel = vm.comments.filter { $0.parentCommentID == nil }
            if topLevel.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
            } else {
                ForEach(topLevel) { comment in
                    commentRow(comment, isReply: false)
                    let replies = vm.comments.filter { $0.parentCommentID == comment.id }
                    ForEach(replies) { reply in
                        commentRow(reply, isReply: true)
                    }
                }
            }
        }
        .padding(.bottom, 120)
    }

    private func commentRow(_ comment: Comment, isReply: Bool) -> some View {
        let isOwn = comment.authorUID == vm.currentUserID
        return HStack(alignment: .top, spacing: swSpacing) {
            if isReply { Spacer().frame(width: 24) }
            SWAvatarView(name: comment.authorName, size: isReply ? 28 : 32, color: .swAccentMuted)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(comment.authorName)
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentLight)
                    Text(comment.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                    Spacer()
                    if isOwn {
                        Button {
                            vm.startEditComment(comment)
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(Color.swAccentLight.opacity(0.8))
                        }
                        .accessibilityLabel("Edit comment")
                        Button {
                            vm.deleteComment(comment)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(Color.swDanger.opacity(0.7))
                        }
                        .accessibilityLabel("Delete comment")
                    }
                }
                Text(comment.body)
                    .font(.swBody)
                    .foregroundStyle(Color.swTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if !isReply {
                    Button("Reply") { vm.replyingTo = comment }
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentPrimary)
                        .accessibilityLabel("Reply to \(comment.authorName)")
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: — Composer

    private var commentComposer: some View {
        VStack(spacing: 0) {
            if let editTarget = vm.editingComment {
                HStack {
                    Image(systemName: "pencil").foregroundStyle(Color.swAccentLight).font(.caption)
                    Text("Editing comment by \(editTarget.authorName)")
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentLight)
                    Spacer()
                    Button("Cancel") { vm.cancelEdit() }
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }
                .padding(.horizontal, swSpacing * 2)
                .padding(.vertical, swSpacing)
                .background(Color.swSurface)
            } else if let replyTarget = vm.replyingTo {
                HStack {
                    Text("Replying to \(replyTarget.authorName)")
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentLight)
                    Spacer()
                    Button("Cancel") { vm.replyingTo = nil }
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }
                .padding(.horizontal, swSpacing * 2)
                .padding(.vertical, swSpacing)
                .background(Color.swSurface)
            }

            HStack(spacing: swSpacing) {
                TextField("Add a comment...", text: $vm.commentText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.swBody)
                    .foregroundStyle(Color.swTextPrimary)
                    .tint(Color.swAccentPrimary)
                    .padding(.horizontal, swSpacing * 2)
                    .padding(.vertical, swSpacing * 1.5)
                    .background(Color.swSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    Task { await vm.submitComment() }
                } label: {
                    Image(systemName: vm.isSubmitting ? "clock" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(vm.commentText.isEmpty ? Color.swTextSecondary : Color.swAccentPrimary)
                }
                .disabled(vm.commentText.isEmpty || vm.isSubmitting)
                .accessibilityLabel("Send comment")
            }
            .padding(.horizontal, swSpacing * 2)
            .padding(.vertical, swSpacing)
            .background(Color.swBackground)
        }
        .overlay(alignment: .top) {
            Divider().background(Color.swAccentDeep)
        }
    }

    // MARK: — Reaction givers sheet

    private var reactionGiversSheet: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                List(vm.reactions) { reaction in
                    HStack {
                        Text(reaction.emoji).font(.title2)
                        Text(reaction.displayName)
                            .font(.swBody)
                            .foregroundStyle(Color.swTextPrimary)
                        Spacer()
                        Text(reaction.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.swCaption)
                            .foregroundStyle(Color.swTextSecondary)
                    }
                    .listRowBackground(Color.swSurface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Reactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { vm.showReactionGivers = false }
                        .foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
    }
}

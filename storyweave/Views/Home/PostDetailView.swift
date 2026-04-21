import SwiftUI
import Combine

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var reactions: [Reaction] = []
    @Published var comments: [Comment] = []
    @Published var commentText: String = ""
    @Published var replyingTo: Comment?
    @Published var isSubmitting = false
    @Published var myReactionEmoji: String?
    @Published var showReactionGivers = false

    let post: Post
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private var reactionTask: Task<Void, Never>?
    private var commentTask: Task<Void, Never>?

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
    }

    func stopListening() {
        reactionTask?.cancel()
        commentTask?.cancel()
    }

    func toggleReaction(emoji: String) {
        guard let uid = auth.currentUserID,
              let profile = auth.currentUserID else { return }
        if myReactionEmoji == emoji {
            Task { try? await firestore.removeReaction(postID: post.id, uid: uid) }
            myReactionEmoji = nil
        } else {
            let displayName = uid  // will fetch profile in production
            try? firestore.react(postID: post.id, emoji: emoji, uid: uid, displayName: displayName)
            myReactionEmoji = emoji
        }
    }

    func submitComment() async {
        guard let uid = auth.currentUserID,
              !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
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
            body: commentText.trimmingCharacters(in: .whitespaces),
            timestamp: Date()
        )
        try? firestore.addComment(comment)
        commentText = ""
        replyingTo = nil
        isSubmitting = false
    }
}

// MARK: — View

struct PostDetailView: View {
    let post: Post
    @StateObject private var vm: PostDetailViewModel
    @Environment(\.dismiss) private var dismiss

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
            }
            .task {
                vm.startListening()
            }
            .onDisappear { vm.stopListening() }
            .sheet(isPresented: $vm.showReactionGivers) {
                reactionGiversSheet
            }
        }
    }

    // MARK: — Post body (compact)

    private var postBody: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            HStack {
                avatarCircle(name: post.authorName, size: 40)
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

    // MARK: — Reaction bar

    private var reactionBar: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            HStack(spacing: swSpacing) {
                ForEach(["❤️", "😂", "😮", "👏"], id: \.self) { emoji in
                    reactionButton(emoji: emoji)
                }
                Spacer()
                if !vm.reactions.isEmpty {
                    Button {
                        vm.showReactionGivers = true
                    } label: {
                        Text("\(vm.reactions.count) reaction\(vm.reactions.count == 1 ? "" : "s")")
                            .font(.swCaption)
                            .foregroundStyle(Color.swAccentLight)
                    }
                    .accessibilityLabel("View \(vm.reactions.count) reactions")
                }
            }

            // Emoji count summary
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
        .padding(.bottom, 120)  // space for composer
    }

    private func commentRow(_ comment: Comment, isReply: Bool) -> some View {
        HStack(alignment: .top, spacing: swSpacing) {
            if isReply { Spacer().frame(width: 24) }
            avatarCircle(name: comment.authorName, size: isReply ? 28 : 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(comment.authorName)
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentLight)
                    Text(comment.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }
                Text(comment.body)
                    .font(.swBody)
                    .foregroundStyle(Color.swTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if !isReply {
                    Button("Reply") {
                        vm.replyingTo = comment
                    }
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
            if let replyTarget = vm.replyingTo {
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

    // MARK: — Helper

    private func avatarCircle(name: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.swAccentDeep)
                .frame(width: size, height: size)
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(Color.swAccentLight)
        }
    }
}

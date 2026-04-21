import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Message Model Extensions
struct MessageViewData: Identifiable, Codable {
    let id: String
    let senderId: String
    let senderName: String
    let senderAvatar: String
    let content: String
    let timestamp: Date
    let isEdited: Bool
    let editedAt: Date?
    let reactions: [String: [String]]
    let threadId: String?
    let parentMessageId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderAvatar = "sender_avatar"
        case content
        case timestamp
        case isEdited = "is_edited"
        case editedAt = "edited_at"
        case reactions
        case threadId = "thread_id"
        case parentMessageId = "parent_message_id"
    }
}

struct MessageThreadData: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let createdAt: Date
    let createdBy: String
    let messageCount: Int
    let lastMessageAt: Date
    let participants: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case createdAt = "created_at"
        case createdBy = "created_by"
        case messageCount = "message_count"
        case lastMessageAt = "last_message_at"
        case participants
    }
}

// MARK: - Message View Model
class MessageViewModel: ObservableObject {
    @Published var messages: [MessageViewData] = []
    @Published var threads: [MessageThreadData] = []
    @Published var selectedThread: MessageThreadData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var filteredMessages: [MessageViewData] = []
    @Published var replyingTo: MessageViewData?
    @Published var editingMessage: MessageViewData?
    @Published var messageInput = ""
    @Published var selectedReactions: [String: Bool] = [:]
    @Published var isTyping = false
    @Published var typingUsers: [String] = []
    @Published var messageStatus: MessageSendStatus = .idle
    @Published var unreadCount = 0
    @Published var sortOrder: MessageSortOrder = .newest
    @Published var filterOption: MessageFilter = .all
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var typingTimer: Timer?
    private var currentUserId = Auth.auth().currentUser?.uid ?? ""
    
    enum MessageSendStatus {
        case idle
        case sending
        case sent
        case failed(String)
    }
    
    enum MessageSortOrder {
        case newest
        case oldest
        case unread
    }
    
    enum MessageFilter {
        case all
        case unread
        case mentions
        case reactions
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.filterMessages(by: text)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Loading
    func loadInitialData() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.fetchThreads()
            self?.fetchMessages()
            DispatchQueue.main.async {
                self?.isLoading = false
            }
        }
    }
    
    func fetchThreads() {
        db.collection("message_threads")
            .whereField("participants", arrayContains: currentUserId)
            .order(by: "last_message_at", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    self?.errorMessage = error?.localizedDescription
                    return
                }
                
                self?.threads = documents.compactMap { doc in
                    do {
                        var thread = try doc.data(as: MessageThreadData.self)
                        thread.id = doc.documentID
                        return thread
                    } catch {
                        return nil
                    }
                }
            }
    }
    
    func fetchMessages() {
        guard let threadId = selectedThread?.id else { return }
        
        listener = db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    self?.errorMessage = error?.localizedDescription
                    return
                }
                
                self?.messages = documents.compactMap { doc in
                    do {
                        var message = try doc.data(as: MessageViewData.self)
                        message.id = doc.documentID
                        return message
                    } catch {
                        return nil
                    }
                }
                
                self?.applyFiltering()
                self?.applySorting()
            }
    }
    
    // MARK: - Message Operations
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let threadId = selectedThread?.id else { return }
        
        messageStatus = .sending
        
        let messageData: [String: Any] = [
            "sender_id": currentUserId,
            "sender_name": "Current User",
            "sender_avatar": "avatar_url",
            "content": text,
            "timestamp": Timestamp(date: Date()),
            "is_edited": false,
            "edited_at": NSNull(),
            "reactions": [:],
            "thread_id": threadId,
            "parent_message_id": replyingTo?.id ?? NSNull()
        ]
        
        db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .addDocument(data: messageData) { [weak self] error in
                if let error = error {
                    self?.messageStatus = .failed(error.localizedDescription)
                } else {
                    self?.messageStatus = .sent
                    self?.messageInput = ""
                    self?.replyingTo = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.messageStatus = .idle
                    }
                }
            }
    }
    
    func editMessage(_ message: MessageViewData, newContent: String) {
        guard let threadId = selectedThread?.id else { return }
        
        let updateData: [String: Any] = [
            "content": newContent,
            "is_edited": true,
            "edited_at": Timestamp(date: Date())
        ]
        
        db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .document(message.id)
            .updateData(updateData) { [weak self] error in
                if error == nil {
                    self?.editingMessage = nil
                    self?.messageInput = ""
                    self?.fetchMessages()
                }
            }
    }
    
    func deleteMessage(_ message: MessageViewData) {
        guard let threadId = selectedThread?.id else { return }
        guard message.senderId == currentUserId else { return }
        
        db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .document(message.id)
            .delete { [weak self] error in
                if error == nil {
                    self?.messages.removeAll { $0.id == message.id }
                }
            }
    }
    
    func addReaction(_ emoji: String, to message: MessageViewData) {
        guard let threadId = selectedThread?.id else { return }
        
        var reactions = message.reactions
        if reactions[emoji] == nil {
            reactions[emoji] = []
        }
        
        if !reactions[emoji]!.contains(currentUserId) {
            reactions[emoji]!.append(currentUserId)
        }
        
        db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .document(message.id)
            .updateData(["reactions": reactions]) { [weak self] _ in
                self?.fetchMessages()
            }
    }
    
    func removeReaction(_ emoji: String, from message: MessageViewData) {
        guard let threadId = selectedThread?.id else { return }
        
        var reactions = message.reactions
        reactions[emoji]?.removeAll { $0 == currentUserId }
        
        if reactions[emoji]?.isEmpty == true {
            reactions.removeValue(forKey: emoji)
        }
        
        db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .document(message.id)
            .updateData(["reactions": reactions]) { [weak self] _ in
                self?.fetchMessages()
            }
    }
    
    func createThread(title: String, description: String, participants: [String]) {
        var threadParticipants = participants
        if !threadParticipants.contains(currentUserId) {
            threadParticipants.append(currentUserId)
        }
        
        let threadData: [String: Any] = [
            "title": title,
            "description": description,
            "created_at": Timestamp(date: Date()),
            "created_by": currentUserId,
            "message_count": 0,
            "last_message_at": Timestamp(date: Date()),
            "participants": threadParticipants
        ]
        
        db.collection("message_threads")
            .addDocument(data: threadData) { [weak self] result, error in
                if error == nil {
                    self?.fetchThreads()
                }
            }
    }
    
    // MARK: - Filtering and Sorting
    func filterMessages(by text: String) {
        if text.isEmpty {
            filteredMessages = messages
        } else {
            filteredMessages = messages.filter { message in
                message.content.localizedCaseInsensitiveContains(text) ||
                message.senderName.localizedCaseInsensitiveContains(text)
            }
        }
    }
    
    private func applyFiltering() {
        switch filterOption {
        case .all:
            filteredMessages = messages
        case .unread:
            filteredMessages = messages.filter { _ in true }
        case .mentions:
            filteredMessages = messages.filter { $0.content.contains("@") }
        case .reactions:
            filteredMessages = messages.filter { !$0.reactions.isEmpty }
        }
    }
    
    private func applySorting() {
        switch sortOrder {
        case .newest:
            filteredMessages.sort { $0.timestamp > $1.timestamp }
        case .oldest:
            filteredMessages.sort { $0.timestamp < $1.timestamp }
        case .unread:
            filteredMessages.sort { $0.timestamp > $1.timestamp }
        }
    }
    
    // MARK: - Typing Indicators
    func notifyTyping() {
        isTyping = true
        typingTimer?.invalidate()
        
        guard let threadId = selectedThread?.id else { return }
        
        let typingData: [String: Any] = [
            "user_id": currentUserId,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("message_threads")
            .document(threadId)
            .collection("typing")
            .document(currentUserId)
            .setData(typingData)
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.clearTypingStatus()
        }
    }
    
    func clearTypingStatus() {
        isTyping = false
        typingTimer?.invalidate()
        
        guard let threadId = selectedThread?.id else { return }
        
        db.collection("message_threads")
            .document(threadId)
            .collection("typing")
            .document(currentUserId)
            .delete()
    }
    
    func subscribeToTypingIndicators() {
        guard let threadId = selectedThread?.id else { return }
        
        db.collection("message_threads")
            .document(threadId)
            .collection("typing")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.typingUsers = snapshot?.documents.compactMap { $0.get("user_id") as? String } ?? []
            }
    }
    
    deinit {
        listener?.remove()
        typingTimer?.invalidate()
    }
}

// MARK: - Message List View
struct MessageListView: View {
    @ObservedObject var viewModel: MessageViewModel
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.messages.isEmpty {
                EmptyMessageView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredMessages) { message in
                                MessageRowView(
                                    message: message,
                                    isCurrentUser: message.senderId == viewModel.currentUserId,
                                    onReply: {
                                        viewModel.replyingTo = message
                                    },
                                    onEdit: {
                                        viewModel.editingMessage = message
                                        viewModel.messageInput = message.content
                                    },
                                    onDelete: {
                                        viewModel.deleteMessage(message)
                                    },
                                    onReactionAdd: { emoji in
                                        viewModel.addReaction(emoji, to: message)
                                    }
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Message Input View
struct MessageInputView: View {
    @ObservedObject var viewModel: MessageViewModel
    @State private var showEmojiPicker = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 8) {
            if let replyingTo = viewModel.replyingTo {
                ReplyPreviewView(message: replyingTo) {
                    viewModel.replyingTo = nil
                }
            }
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $viewModel.messageInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.messageInput) { _ in
                        viewModel.notifyTyping()
                    }
                
                Button(action: { showEmojiPicker.toggle() }) {
                    Image(systemName: "smileyface")
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    viewModel.sendMessage(viewModel.messageInput)
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.messageInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            if showEmojiPicker {
                EmojiPickerView(selectedEmoji: { emoji in
                    showEmojiPicker = false
                })
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Message Row View
struct MessageRowView: View {
    let message: MessageViewData
    let isCurrentUser: Bool
    let onReply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReactionAdd: (String) -> Void
    
    @State private var showActions = false
    @State private var showReactionPicker = false
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack(spacing: 8) {
                if !isCurrentUser {
                    AsyncImage(url: URL(string: message.senderAvatar)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        default:
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                    if !isCurrentUser {
                        Text(message.senderName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                        Text(message.content)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                            .foregroundColor(isCurrentUser ? .white : .primary)
                            .cornerRadius(12)
                        
                        if message.isEdited {
                            Text("(edited)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("Reply", action: onReply)
                        if isCurrentUser {
                            Button("Edit", action: onEdit)
                            Button("Delete", action: onDelete)
                        }
                    }
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if isCurrentUser {
                    AsyncImage(url: URL(string: message.senderAvatar)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        default:
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            }
            
            if !message.reactions.isEmpty {
                ReactionBubbleView(reactions: message.reactions)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Reply Preview View
struct ReplyPreviewView: View {
    let message: MessageViewData
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to \(message.senderName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .margin(.horizontal, 12)
    }
}

// MARK: - Reaction Bubble View
struct ReactionBubbleView: View {
    let reactions: [String: [String]]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(reactions.sorted(by: { $0.key < $1.key }), id: \.key) { emoji, users in
                HStack(spacing: 2) {
                    Text(emoji)
                    Text("\(users.count)")
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Emoji Picker View
struct EmojiPickerView: View {
    let selectedEmoji: (String) -> Void
    
    let emojis = ["👍", "❤️", "😂", "😮", "😢", "🎉", "🔥", "💯", "👏", "🙏", "💪", "🤔", "👀", "😎", "🤷"]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Add Reaction")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji(emoji)
                    }) {
                        Text(emoji)
                            .font(.system(size: 24))
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - Empty Message View
struct EmptyMessageView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Messages Yet")
                    .font(.headline)
                
                Text("Start a conversation by sending your first message")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Thread Selection View
struct ThreadSelectionView: View {
    @ObservedObject var viewModel: MessageViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.threads) { thread in
                ThreadRowView(thread: thread) {
                    viewModel.selectedThread = thread
                    viewModel.fetchMessages()
                }
            }
        }
        .navigationTitle("Messages")
    }
}

// MARK: - Thread Row View
struct ThreadRowView: View {
    let thread: MessageThreadData
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(thread.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Label("\(thread.messageCount)", systemImage: "bubble")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Label(thread.lastMessageAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Main Message Home View
struct MessageHomeView: View {
    @StateObject private var viewModel = MessageViewModel()
    @State private var showNewThreadSheet = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("Messages").tag(0)
                    Text("Threads").tag(1)
                    Text("Search").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    MessageListView(viewModel: viewModel)
                } else if selectedTab == 1 {
                    ThreadSelectionView(viewModel: viewModel)
                } else {
                    MessageSearchView(viewModel: viewModel)
                }
                
                MessageInputView(viewModel: viewModel)
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewThreadSheet.toggle() }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showNewThreadSheet) {
                NewThreadView(viewModel: viewModel, isPresented: $showNewThreadSheet)
            }
        }
    }
}

// MARK: - Message Search View
struct MessageSearchView: View {
    @ObservedObject var viewModel: MessageViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search messages", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            if viewModel.filteredMessages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No messages found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.filteredMessages) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.senderName)
                                .font(.headline)
                            
                            Text(message.content)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            Text(message.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - New Thread View
struct NewThreadView: View {
    @ObservedObject var viewModel: MessageViewModel
    @Binding var isPresented: Bool
    
    @State private var threadTitle = ""
    @State private var threadDescription = ""
    @State private var selectedParticipants: Set<String> = []
    @State private var availableParticipants: [String] = ["User1", "User2", "User3", "User4", "User5"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thread Details")) {
                    TextField("Title", text: $threadTitle)
                    TextField("Description", text: $threadDescription)
                }
                
                Section(header: Text("Participants")) {
                    List(selection: $selectedParticipants) {
                        ForEach(availableParticipants, id: \.self) { participant in
                            Text(participant)
                                .tag(participant)
                        }
                    }
                    .environment(\.editMode, .constant(.active))
                }
                
                Section {
                    Button(action: {
                        viewModel.createThread(
                            title: threadTitle,
                            description: threadDescription,
                            participants: Array(selectedParticipants)
                        )
                        isPresented = false
                    }) {
                        Text("Create Thread")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(threadTitle.isEmpty || selectedParticipants.isEmpty)
                }
            }
            .navigationTitle("New Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Message Statistics View
struct MessageStatisticsView: View {
    @ObservedObject var viewModel: MessageViewModel
    
    var totalMessages: Int {
        viewModel.messages.count
    }
    
    var totalThreads: Int {
        viewModel.threads.count
    }
    
    var averageMessagesPerThread: Double {
        guard totalThreads > 0 else { return 0 }
        return Double(totalMessages) / Double(totalThreads)
    }
    
    var mostActiveUser: String {
        let messagesByUser = Dictionary(grouping: viewModel.messages, by: { $0.senderName })
        return messagesByUser.max(by: { $0.value.count < $1.value.count })?.key ?? "N/A"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Message Statistics")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatisticCardView(
                    title: "Total Messages",
                    value: "\(totalMessages)",
                    icon: "bubble.fill"
                )
                
                StatisticCardView(
                    title: "Total Threads",
                    value: "\(totalThreads)",
                    icon: "square.stack.fill"
                )
            }
            
            HStack(spacing: 16) {
                StatisticCardView(
                    title: "Avg per Thread",
                    value: String(format: "%.1f", averageMessagesPerThread),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                StatisticCardView(
                    title: "Most Active",
                    value: mostActiveUser,
                    icon: "person.fill"
                )
            }
        }
        .padding()
    }
}

// MARK: - Statistic Card View
struct StatisticCardView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    MessageHomeView()
}

// MARK: - Additional Helper Extensions
extension View {
    func margin(_ edges: Edge.Set, _ length: CGFloat) -> some View {
        padding(edges, length)
    }
}

// MARK: - Message Formatting Utilities
struct MessageFormatter {
    static func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        }
        return formatter.string(from: date)
    }
    
    static func formatMessageContent(_ content: String) -> String {
        return content.trimmingCharacters(in: .whitespaces)
    }
    
    static func detectMentions(in text: String) -> [String] {
        let pattern = "@([a-zA-Z0-9_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }
    
    static func detectUrls(in text: String) -> [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let nsText = text as NSString
        let matches = detector?.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        return matches?.compactMap { $0.url } ?? []
    }
}

// MARK: - Message Cache Manager
class MessageCacheManager: ObservableObject {
    @Published var cachedMessages: [String: [MessageViewData]] = [:]
    
    private let cache = NSCache<NSString, MessageCache>()
    
    func cacheMessages(_ messages: [MessageViewData], for threadId: String) {
        let messageCache = MessageCache()
        messageCache.messages = messages
        cache.setObject(messageCache, forKey: threadId as NSString)
    }
    
    func getCachedMessages(for threadId: String) -> [MessageViewData]? {
        return cache.object(forKey: threadId as NSString)?.messages
    }
    
    func clearCache(for threadId: String) {
        cache.removeObject(forKey: threadId as NSString)
    }
    
    func clearAllCache() {
        cache.removeAllObjects()
    }
}

class MessageCache: NSObject {
    var messages: [MessageViewData] = []
}

// MARK: - Message Notification Manager
class MessageNotificationManager: NSObject {
    static let shared = MessageNotificationManager()
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleNotification(for message: MessageViewData, threadTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = threadTitle
        content.body = message.content
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: message.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

import UserNotifications
import Combine

// MARK: - Advanced Message Features

// MARK: - Message Encryption Manager
class MessageEncryptionManager {
    static let shared = MessageEncryptionManager()
    
    func encryptMessage(_ message: String, with key: String) -> String {
        // Placeholder for encryption logic
        return message
    }
    
    func decryptMessage(_ encryptedMessage: String, with key: String) -> String {
        // Placeholder for decryption logic
        return encryptedMessage
    }
}

// MARK: - Advanced Message View Model Extensions
extension MessageViewModel {
    func archiveThread(_ thread: MessageThreadData) {
        guard let index = threads.firstIndex(where: { $0.id == thread.id }) else { return }
        threads.remove(at: index)
    }
    
    func muteThread(_ thread: MessageThreadData) {
        db.collection("message_threads")
            .document(thread.id)
            .updateData(["is_muted": true])
    }
    
    func unmuteThread(_ thread: MessageThreadData) {
        db.collection("message_threads")
            .document(thread.id)
            .updateData(["is_muted": false])
    }
    
    func pinMessage(_ message: MessageViewData) {
        guard let threadId = selectedThread?.id else { return }
        
        db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .document(message.id)
            .updateData(["is_pinned": true])
    }
    
    func unpinMessage(_ message: MessageViewData) {
        guard let threadId = selectedThread?.id else { return }
        
        db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .document(message.id)
            .updateData(["is_pinned": false])
    }
    
    func markAsRead(_ message: MessageViewData) {
        guard let threadId = selectedThread?.id else { return }
        
        db.collection("message_threads")
            .document(threadId)
            .collection("messages")
            .document(message.id)
            .updateData(["read_by": FieldValue.arrayUnion([currentUserId])])
    }
    
    func searchMessages(query: String) -> [MessageViewData] {
        return messages.filter { message in
            message.content.localizedCaseInsensitiveContains(query) ||
            message.senderName.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getMessagesByUser(_ userId: String) -> [MessageViewData] {
        return messages.filter { $0.senderId == userId }
    }
    
    func getMessagesInDateRange(_ startDate: Date, _ endDate: Date) -> [MessageViewData] {
        return messages.filter { message in
            message.timestamp >= startDate && message.timestamp <= endDate
        }
    }
}

// MARK: - Message Rich Text View
struct RichMessageView: View {
    let message: MessageViewData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMessageContent(message.content), id: \.self) { component in
                switch component {
                case .text(let text):
                    Text(text)
                        .font(.body)
                
                case .mention(let username):
                    Text("@\(username)")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                
                case .url(let url):
                    Link(url.absoluteString, destination: url)
                        .foregroundColor(.blue)
                        .underline()
                
                case .emoji(let emoji):
                    Text(emoji)
                        .font(.system(size: 20))
                }
            }
        }
    }
    
    enum MessageComponent: Hashable {
        case text(String)
        case mention(String)
        case url(URL)
        case emoji(String)
    }
    
    private func parseMessageContent(_ content: String) -> [MessageComponent] {
        var components: [MessageComponent] = []
        var remainingText = content
        
        let mentions = MessageFormatter.detectMentions(in: content)
        let urls = MessageFormatter.detectUrls(in: content)
        
        for mention in mentions {
            if let range = remainingText.range(of: "@\(mention)") {
                let beforeMention = String(remainingText[..<range.lowerBound])
                if !beforeMention.isEmpty {
                    components.append(.text(beforeMention))
                }
                components.append(.mention(mention))
                remainingText = String(remainingText[range.upperBound...])
            }
        }
        
        if !remainingText.isEmpty {
            components.append(.text(remainingText))
        }
        
        return components
    }
}

// MARK: - Message Reactions Advanced View
struct AdvancedReactionView: View {
    let message: MessageViewData
    let onAddReaction: (String) -> Void
    let onRemoveReaction: (String) -> Void
    
    @State private var showReactionPicker = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(message.reactions.sorted(by: { $0.key < $1.key }), id: \.key) { emoji, users in
                    ReactionButtonView(emoji: emoji, userCount: users.count) {
                        onRemoveReaction(emoji)
                    }
                }
                
                Button(action: { showReactionPicker.toggle() }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
            }
            
            if showReactionPicker {
                EmojiPickerView { emoji in
                    onAddReaction(emoji)
                    showReactionPicker = false
                }
            }
        }
    }
}

// MARK: - Reaction Button Component
struct ReactionButtonView: View {
    let emoji: String
    let userCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(emoji)
                
                if userCount > 1 {
                    Text("\(userCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Message Detail View
struct MessageDetailView: View {
    let message: MessageViewData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: message.senderAvatar)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 48, height: 48)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.senderName)
                        .font(.headline)
                    
                    Text(message.timestamp.formatted(date: .abbreviated, time: .standard))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            RichMessageView(message: message)
            
            if message.isEdited {
                HStack {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.secondary)
                    
                    Text("Edited on \(message.editedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Message Info")
                    .font(.headline)
                
                DetailRow(label: "Message ID", value: message.id)
                DetailRow(label: "Thread", value: message.threadId ?? "N/A")
                DetailRow(label: "Sent At", value: message.timestamp.ISO8601Format())
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Message Details")
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.caption)
        .padding(.vertical, 4)
    }
}

// MARK: - Message Typing Indicator View
struct TypingIndicatorView: View {
    let typingUsers: [String]
    
    @State private var dotScale: [CGFloat] = [1.0, 1.0, 1.0]
    
    var body: some View {
        if !typingUsers.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(typingUsers.joined(separator: ", ")) \(typingUsers.count == 1 ? "is" : "are") typing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                            .scaleEffect(dotScale[index])
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .onAppear {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
            for index in 0..<3 {
                dotScale[index] = 1.3
            }
        }
    }
}

// MARK: - Message Filter Manager
class MessageFilterManager: ObservableObject {
    @Published var activeFilters: Set<MessageFilter> = []
    @Published var searchTerms: [String] = []
    @Published var dateRange: ClosedRange<Date>?
    
    enum MessageFilter: String, CaseIterable {
        case unread = "Unread"
        case mentions = "Mentions"
        case reactions = "Reactions"
        case pinned = "Pinned"
        case archived = "Archived"
        case important = "Important"
    }
    
    func applyFilters(to messages: [MessageViewData]) -> [MessageViewData] {
        var filtered = messages
        
        if activeFilters.contains(.unread) {
            filtered = filtered.filter { !$0.reactions.isEmpty }
        }
        
        if activeFilters.contains(.mentions) {
            filtered = filtered.filter { $0.content.contains("@") }
        }
        
        if activeFilters.contains(.reactions) {
            filtered = filtered.filter { !$0.reactions.isEmpty }
        }
        
        for term in searchTerms {
            filtered = filtered.filter { message in
                message.content.localizedCaseInsensitiveContains(term) ||
                message.senderName.localizedCaseInsensitiveContains(term)
            }
        }
        
        return filtered
    }
}

// MARK: - Advanced Message List View
struct AdvancedMessageListView: View {
    @ObservedObject var viewModel: MessageViewModel
    @StateObject var filterManager = MessageFilterManager()
    
    @State private var selectedMessage: MessageViewData?
    @State private var sortOrder: SortOrder = .newest
    
    enum SortOrder {
        case newest
        case oldest
        case mostReacted
    }
    
    var filteredAndSortedMessages: [MessageViewData] {
        var messages = filterManager.applyFilters(to: viewModel.messages)
        
        switch sortOrder {
        case .newest:
            messages.sort { $0.timestamp > $1.timestamp }
        case .oldest:
            messages.sort { $0.timestamp < $1.timestamp }
        case .mostReacted:
            messages.sort { $0.reactions.count > $1.reactions.count }
        }
        
        return messages
    }
    
    var body: some View {
        VStack(spacing: 0) {
            FilterBarView(filterManager: filterManager)
            
            if filteredAndSortedMessages.isEmpty {
                EmptyMessageView()
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(filteredAndSortedMessages) { message in
                            NavigationLink(destination: MessageDetailView(message: message)) {
                                MessageRowView(
                                    message: message,
                                    isCurrentUser: message.senderId == viewModel.currentUserId,
                                    onReply: { viewModel.replyingTo = message },
                                    onEdit: {
                                        viewModel.editingMessage = message
                                        viewModel.messageInput = message.content
                                    },
                                    onDelete: { viewModel.deleteMessage(message) },
                                    onReactionAdd: { emoji in
                                        viewModel.addReaction(emoji, to: message)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - Filter Bar View
struct FilterBarView: View {
    @ObservedObject var filterManager: MessageFilterManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(MessageFilterManager.MessageFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        if filterManager.activeFilters.contains(filter) {
                            filterManager.activeFilters.remove(filter)
                        } else {
                            filterManager.activeFilters.insert(filter)
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(filterManager.activeFilters.contains(filter) ? Color.blue : Color(.systemGray5))
                            .foregroundColor(filterManager.activeFilters.contains(filter) ? .white : .primary)
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Message Analytics Manager
class MessageAnalyticsManager: ObservableObject {
    @Published var messageStats: MessageStatistics = MessageStatistics()
    
    struct MessageStatistics {
        var totalMessages: Int = 0
        var totalThreads: Int = 0
        var averageMessagesPerThread: Double = 0
        var mostActiveUser: String = "N/A"
        var mostUsedEmoji: String = "👍"
        var averageMessageLength: Double = 0
        var peakHour: Int = 12
        var dailyMessageCount: Int = 0
    }
    
    func calculateStatistics(from messages: [MessageViewData]) {
        messageStats.totalMessages = messages.count
        messageStats.averageMessageLength = Double(messages.map { $0.content.count }.reduce(0, +)) / Double(max(messages.count, 1))
        
        let emojiCounts = messages.flatMap { $0.reactions.keys }
        messageStats.mostUsedEmoji = emojiCounts.max(by: {
            emojiCounts.filter { $0 == $1 }.count < emojiCounts.filter { $0 == $0 }.count
        }) ?? "👍"
    }
}

// MARK: - Message Gesture Handler
struct MessageGestureHandler {
    static func handleLongPress(message: MessageViewData) {
        print("Long press on message: \(message.id)")
    }
    
    static func handleDoubleTap(message: MessageViewData) {
        print("Double tap on message: \(message.id)")
    }
    
    static func handleSwipeLeft(message: MessageViewData) {
        print("Swipe left on message: \(message.id)")
    }
    
    static func handleSwipeRight(message: MessageViewData) {
        print("Swipe right on message: \(message.id)")
    }
}

// MARK: - Message Animation Utilities
struct MessageAnimationUtils {
    static func slideInAnimation() -> Animation {
        Animation.easeOut(duration: 0.3)
    }
    
    static func fadeInAnimation() -> Animation {
        Animation.easeIn(duration: 0.2)
    }
    
    static func popAnimation() -> Animation {
        Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
    
    static func bounceAnimation() -> Animation {
        Animation.interpolatingSpring(stiffness: 100, damping: 10)
    }
}

// MARK: - Animated Message Row
struct AnimatedMessageRow: View {
    let message: MessageViewData
    @State private var isVisible = false
    
    var body: some View {
        MessageRowView(
            message: message,
            isCurrentUser: false,
            onReply: {},
            onEdit: {},
            onDelete: {},
            onReactionAdd: { _ in }
        )
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            withAnimation(MessageAnimationUtils.slideInAnimation()) {
                isVisible = true
            }
        }
    }
}

// MARK: - Message Media Handler
class MessageMediaHandler: NSObject, ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isUploadingMedia = false
    @Published var mediaUploadProgress: Double = 0
    
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        isUploadingMedia = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Simulate upload delay
            for i in 0...100 {
                self?.mediaUploadProgress = Double(i) / 100.0
                usleep(10000)
            }
            
            self?.isUploadingMedia = false
            completion("https://example.com/image.jpg")
        }
    }
}

// MARK: - Message Accessibility Features
extension View {
    func messageAccessibility(message: MessageViewData) -> some View {
        self
            .accessibility(label: Text("\(message.senderName) message"))
            .accessibility(value: Text(message.content))
            .accessibility(hint: Text("Sent at \(message.timestamp.formatted())"))
    }
}

// MARK: - Message Persistence Manager
class MessagePersistenceManager: ObservableObject {
    @Published var isSynced = false
    
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func saveMessagesDraft(_ messages: [MessageViewData], for threadId: String) {
        let url = documentsDirectory.appendingPathComponent("messages_\(threadId).json")
        
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: url)
        } catch {
            print("Error saving messages: \(error)")
        }
    }
    
    func loadMessagesDraft(for threadId: String) -> [MessageViewData]? {
        let url = documentsDirectory.appendingPathComponent("messages_\(threadId).json")
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([MessageViewData].self, from: data)
        } catch {
            print("Error loading messages: \(error)")
            return nil
        }
    }
}

// MARK: - User Mention Manager
class UserMentionManager: ObservableObject {
    @Published var suggestedUsers: [UserProfile] = []
    @Published var selectedMentions: [UserProfile] = []
    
    func fetchSuggestedUsers(matching prefix: String) {
        // Fetch users that match the prefix
        suggestedUsers = [
            UserProfile(id: "1", name: "Alice Anderson", avatar: ""),
            UserProfile(id: "2", name: "Bob Brown", avatar: ""),
            UserProfile(id: "3", name: "Charlie Chen", avatar: "")
        ].filter { $0.name.localizedCaseInsensitiveContains(prefix) }
    }
    
    func addMention(_ user: UserProfile) {
        if !selectedMentions.contains(where: { $0.id == user.id }) {
            selectedMentions.append(user)
        }
    }
    
    func removeMention(_ user: UserProfile) {
        selectedMentions.removeAll { $0.id == user.id }
    }
}

// MARK: - Message Custom Toolbar
struct MessageCustomToolbar: View {
    @ObservedObject var viewModel: MessageViewModel
    @State private var showDatePicker = false
    @State private var showSortOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showSortOptions.toggle() }) {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(.blue)
            }
            
            if showSortOptions {
                Menu {
                    Button("Newest First") {
                        viewModel.sortOrder = .newest
                    }
                    Button("Oldest First") {
                        viewModel.sortOrder = .oldest
                    }
                    Button("Unread") {
                        viewModel.sortOrder = .unread
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
            
            Button(action: { showDatePicker.toggle() }) {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Menu {
                Button("Archive") {
                    if let thread = viewModel.selectedThread {
                        viewModel.archiveThread(thread)
                    }
                }
                Button("Mute") {
                    if let thread = viewModel.selectedThread {
                        viewModel.muteThread(thread)
                    }
                }
                Button("Delete") {}
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Message Voice Memo Support
class MessageVoiceMemoManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var voiceMemoURL: URL?
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    func startRecording() {
        isRecording = true
        recordingDuration = 0
        
        let filename = UUID().uuidString + ".m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        voiceMemoURL = documentsPath.appendingPathComponent(filename)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
    }
    
    func stopRecording() {
        isRecording = false
        timer?.invalidate()
    }
}

import AVFoundation

// MARK: - Message Thread List Advanced
struct AdvancedThreadListView: View {
    @ObservedObject var viewModel: MessageViewModel
    @State private var selectedThread: MessageThreadData?
    @State private var showNewThread = false
    @State private var searchText = ""
    
    var filteredThreads: [MessageThreadData] {
        if searchText.isEmpty {
            return viewModel.threads
        }
        return viewModel.threads.filter { thread in
            thread.title.localizedCaseInsensitiveContains(searchText) ||
            thread.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                if filteredThreads.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.stack")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No Threads")
                            .font(.headline)
                        
                        Text("Create a new thread to start messaging")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredThreads) { thread in
                            NavigationLink(destination: ThreadDetailView(thread: thread, viewModel: viewModel)) {
                                AdvancedThreadRowView(thread: thread)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Threads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewThread.toggle() }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showNewThread) {
                NewThreadView(viewModel: viewModel, isPresented: $showNewThread)
            }
        }
    }
}

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search threads", text: $text)
                .textFieldStyle(.roundedBorder)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - Advanced Thread Row
struct AdvancedThreadRowView: View {
    let thread: MessageThreadData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(thread.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(thread.messageCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(thread.lastMessageAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(thread.participants.prefix(3), id: \.self) { participant in
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(String(participant.prefix(1)))
                                .font(.caption2)
                                .foregroundColor(.blue)
                        )
                }
                
                if thread.participants.count > 3 {
                    Text("+\(thread.participants.count - 3)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Thread Detail View
struct ThreadDetailView: View {
    let thread: MessageThreadData
    @ObservedObject var viewModel: MessageViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(thread.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(thread.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Created")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(thread.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(thread.messageCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            Spacer()
        }
        .navigationTitle("Thread Details")
    }
}

// MARK: - Message Batch Operations
class MessageBatchManager: ObservableObject {
    @Published var selectedMessages: Set<String> = []
    @Published var isBatchEditingEnabled = false
    
    func deleteSelectedMessages(from messages: inout [MessageViewData]) {
        messages.removeAll { selectedMessages.contains($0.id) }
        selectedMessages.removeAll()
    }
    
    func archiveSelectedMessages() {
        print("Archiving \(selectedMessages.count) messages")
        selectedMessages.removeAll()
    }
    
    func exportSelectedMessages() -> String {
        let messageIds = selectedMessages.joined(separator: ", ")
        return "Exporting messages: \(messageIds)"
    }
    
    func toggleBatchMode() {
        isBatchEditingEnabled.toggle()
        if !isBatchEditingEnabled {
            selectedMessages.removeAll()
        }
    }
}

// MARK: - Message Export Formats
enum MessageExportFormat {
    case json
    case csv
    case plainText
    case pdf
    
    func export(messages: [MessageViewData]) -> String {
        switch self {
        case .json:
            if let data = try? JSONEncoder().encode(messages),
               let json = String(data: data, encoding: .utf8) {
                return json
            }
        case .csv:
            return messages.map { "\"\\($0.senderName)\",\"\\($0.content)\",\"\\($0.timestamp)\"" }
                .joined(separator: "\n")
        case .plainText:
            return messages.map { "\\($0.senderName): \\($0.content)" }
                .joined(separator: "\n")
        case .pdf:
            return "PDF Export"
        }
        return ""
    }
}

// MARK: - Message Moderation System
class MessageModerationManager: ObservableObject {
    @Published var flaggedMessages: [String] = []
    @Published var blockedUsers: Set<String> = []
    
    let bannedWords = ["inappropriate", "spam", "abuse"]
    
    func checkMessage(_ message: MessageViewData) -> ModerationResult {
        for word in bannedWords {
            if message.content.localizedCaseInsensitiveContains(word) {
                return ModerationResult(isFlagged: true, reason: "Contains banned word: \(word)")
            }
        }
        return ModerationResult(isFlagged: false, reason: nil)
    }
    
    func blockUser(_ userId: String) {
        blockedUsers.insert(userId)
    }
    
    func unblockUser(_ userId: String) {
        blockedUsers.remove(userId)
    }
    
    func reportMessage(_ messageId: String) {
        flaggedMessages.append(messageId)
    }
    
    struct ModerationResult {
        let isFlagged: Bool
        let reason: String?
    }
}

// MARK: - Message Notification Preferences Manager
class MessageNotificationPreferencesManager: ObservableObject {
    @Published var notificationsEnabled = true
    @Published var soundEnabled = true
    @Published var vibrationEnabled = true
    @Published var showPreview = true
    @Published var quietHoursStart = Date()
    @Published var quietHoursEnd = Date()
    @Published var notifyOnMentions = true
    @Published var notifyOnReplies = true
    @Published var notifyOnReactions = false
    @Published var mutedThreads: Set<String> = []
    @Published var notificationBadgeCount = 0
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
    }
    
    func toggleSound() {
        soundEnabled.toggle()
    }
    
    func toggleVibration() {
        vibrationEnabled.toggle()
    }
    
    func setQuietHours(start: Date, end: Date) {
        quietHoursStart = start
        quietHoursEnd = end
    }
    
    func isInQuietHours() -> Bool {
        let now = Date()
        return now >= quietHoursStart && now <= quietHoursEnd
    }
    
    func muteThread(_ threadId: String) {
        mutedThreads.insert(threadId)
    }
    
    func unmuteThread(_ threadId: String) {
        mutedThreads.remove(threadId)
    }
    
    func shouldNotify(for thread: MessageThreadData) -> Bool {
        return notificationsEnabled && !mutedThreads.contains(thread.id)
    }
}

// MARK: - Message Link Preview Manager
class MessageLinkPreviewManager: ObservableObject {
    @Published var linkPreviews: [String: LinkPreview] = [:]
    @Published var isLoadingPreviews = false
    
    struct LinkPreview: Identifiable {
        let id: String
        let title: String
        let description: String
        let imageURL: URL?
        let url: URL
    }
    
    func fetchLinkPreview(for url: URL, completion: @escaping (LinkPreview?) -> Void) {
        isLoadingPreviews = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Simulate fetching preview
            let preview = LinkPreview(
                id: url.absoluteString,
                title: "Link Title",
                description: "Link description goes here",
                imageURL: nil,
                url: url
            )
            
            DispatchQueue.main.async {
                self?.linkPreviews[url.absoluteString] = preview
                self?.isLoadingPreviews = false
                completion(preview)
            }
        }
    }
    
    func getPreview(for url: URL) -> LinkPreview? {
        return linkPreviews[url.absoluteString]
    }
}

// MARK: - Message Translation Manager
class MessageTranslationManager: ObservableObject {
    @Published var translatedMessages: [String: String] = [:]
    @Published var isTranslating = false
    @Published var targetLanguage = "en"
    
    let supportedLanguages = ["en", "es", "fr", "de", "it", "ja", "zh", "ru"]
    
    func translateMessage(_ message: MessageViewData, to language: String) {
        isTranslating = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Simulate translation API call
            let translated = message.content + " (translated to \(language))"
            
            DispatchQueue.main.async {
                self?.translatedMessages[message.id] = translated
                self?.isTranslating = false
            }
        }
    }
    
    func getTranslation(for messageId: String) -> String? {
        return translatedMessages[messageId]
    }
    
    func clearTranslations() {
        translatedMessages.removeAll()
    }
}

// MARK: - Message Scheduling Manager
class MessageSchedulingManager: ObservableObject {
    @Published var scheduledMessages: [ScheduledMessage] = []
    @Published var isScheduling = false
    
    struct ScheduledMessage: Identifiable {
        let id: String
        let content: String
        let threadId: String
        let scheduledTime: Date
        var isSent = false
    }
    
    func scheduleMessage(_ content: String, for threadId: String, at time: Date) {
        let scheduled = ScheduledMessage(
            id: UUID().uuidString,
            content: content,
            threadId: threadId,
            scheduledTime: time
        )
        scheduledMessages.append(scheduled)
    }
    
    func cancelScheduledMessage(_ id: String) {
        scheduledMessages.removeAll { $0.id == id }
    }
    
    func processScheduledMessages() {
        let now = Date()
        for (index, message) in scheduledMessages.enumerated() {
            if message.scheduledTime <= now && !message.isSent {
                scheduledMessages[index].isSent = true
            }
        }
    }
}

// MARK: - Message Drafts Manager
class MessageDraftsManager: ObservableObject {
    @Published var drafts: [MessageDraft] = []
    
    struct MessageDraft: Identifiable {
        let id: String
        let threadId: String
        var content: String
        let createdAt: Date
        var lastModified: Date
    }
    
    func saveDraft(_ content: String, for threadId: String) {
        if let index = drafts.firstIndex(where: { $0.threadId == threadId }) {
            drafts[index].content = content
            drafts[index].lastModified = Date()
        } else {
            let draft = MessageDraft(
                id: UUID().uuidString,
                threadId: threadId,
                content: content,
                createdAt: Date(),
                lastModified: Date()
            )
            drafts.append(draft)
        }
    }
    
    func getDraft(for threadId: String) -> MessageDraft? {
        return drafts.first { $0.threadId == threadId }
    }
    
    func deleteDraft(_ id: String) {
        drafts.removeAll { $0.id == id }
    }
    
    func clearOldDrafts() {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        drafts.removeAll { $0.lastModified < oneDayAgo }
    }
}

// MARK: - Message Search Advanced
class MessageSearchManager: ObservableObject {
    @Published var searchResults: [MessageViewData] = []
    @Published var isSearching = false
    @Published var searchFilters = SearchFilters()
    
    struct SearchFilters {
        var fromUser: String?
        var inThread: String?
        var dateRange: ClosedRange<Date>?
        var hasReactions = false
        var hasMentions = false
    }
    
    func search(_ query: String, in messages: [MessageViewData]) {
        isSearching = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var results = messages.filter { message in
                message.content.localizedCaseInsensitiveContains(query)
            }
            
            if let fromUser = self?.searchFilters.fromUser {
                results = results.filter { $0.senderName == fromUser }
            }
            
            if let inThread = self?.searchFilters.inThread {
                results = results.filter { $0.threadId == inThread }
            }
            
            if let dateRange = self?.searchFilters.dateRange {
                results = results.filter { dateRange.contains($0.timestamp) }
            }
            
            if self?.searchFilters.hasReactions == true {
                results = results.filter { !$0.reactions.isEmpty }
            }
            
            if self?.searchFilters.hasMentions == true {
                results = results.filter { $0.content.contains("@") }
            }
            
            DispatchQueue.main.async {
                self?.searchResults = results
                self?.isSearching = false
            }
        }
    }
}

// MARK: - Message Synchronization Manager
class MessageSynchronizationManager: ObservableObject {
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0
    @Published var lastSyncTime: Date?
    @Published var syncErrors: [String] = []
    
    func syncMessages(completion: @escaping () -> Void) {
        isSyncing = true
        syncProgress = 0
        syncErrors.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for i in 0...100 {
                self?.syncProgress = Double(i) / 100.0
                usleep(50000)
            }
            
            DispatchQueue.main.async {
                self?.isSyncing = false
                self?.lastSyncTime = Date()
                completion()
            }
        }
    }
    
    func addSyncError(_ error: String) {
        syncErrors.append(error)
    }
    
    func clearSyncErrors() {
        syncErrors.removeAll()
    }
}

// MARK: - Message Bookmark Manager
class MessageBookmarkManager: ObservableObject {
    @Published var bookmarkedMessages: Set<String> = []
    
    func addBookmark(_ messageId: String) {
        bookmarkedMessages.insert(messageId)
    }
    
    func removeBookmark(_ messageId: String) {
        bookmarkedMessages.remove(messageId)
    }
    
    func isBookmarked(_ messageId: String) -> Bool {
        return bookmarkedMessages.contains(messageId)
    }
    
    func clearBookmarks() {
        bookmarkedMessages.removeAll()
    }
    
    func getBookmarkCount() -> Int {
        return bookmarkedMessages.count
    }
}

// MARK: - Message Threading Manager
class MessageThreadingManager: ObservableObject {
    @Published var messageThreads: [String: [MessageViewData]] = [:]
    
    func createThread(parentMessageId: String, messages: [MessageViewData]) {
        let threaded = messages.filter { $0.parentMessageId == parentMessageId }
        messageThreads[parentMessageId] = threaded
    }
    
    func getThreadMessages(for parentId: String) -> [MessageViewData] {
        return messageThreads[parentId] ?? []
    }
    
    func addToThread(_ message: MessageViewData, parentId: String) {
        if messageThreads[parentId] != nil {
            messageThreads[parentId]?.append(message)
        }
    }
}

// MARK: - Message Read Receipt Manager
class MessageReadReceiptManager: ObservableObject {
    @Published var readReceipts: [String: [String: Date]] = [:]
    
    func markAsRead(_ messageId: String, by userId: String) {
        if readReceipts[messageId] == nil {
            readReceipts[messageId] = [:]
        }
        readReceipts[messageId]?[userId] = Date()
    }
    
    func getReadReceipts(for messageId: String) -> [String: Date]? {
        return readReceipts[messageId]
    }
    
    func getReadCount(for messageId: String) -> Int {
        return readReceipts[messageId]?.count ?? 0
    }
}

// MARK: - Advanced Message Cell View
struct AdvancedMessageCellView: View {
    let message: MessageViewData
    let isCurrentUser: Bool
    
    @State private var showMenu = false
    @State private var isSelected = false
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack(spacing: 8) {
                if !isCurrentUser {
                    Avatar(url: URL(string: message.senderAvatar))
                }
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                    if !isCurrentUser {
                        Text(message.senderName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(12)
                        .contextMenu {
                            Button("Copy", action: { UIPasteboard.general.string = message.content })
                            Button("Reply", action: {})
                            if isCurrentUser {
                                Button("Edit", action: {})
                                Button("Delete", action: {}, attributes: .destructive)
                            }
                        }
                }
                
                if isCurrentUser {
                    Avatar(url: URL(string: message.senderAvatar))
                }
            }
            
            HStack(spacing: 8) {
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if message.isEdited {
                    Text("(edited)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}

// MARK: - Avatar Component
struct Avatar: View {
    let url: URL?
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            case .loading:
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .shimmer()
            case .empty:
                Circle()
                    .fill(Color.gray)
                    .frame(width: 32, height: 32)
            @unknown default:
                Circle()
                    .fill(Color.gray)
                    .frame(width: 32, height: 32)
            }
        }
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer() -> some View {
        self
            .opacity(0.6)
            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
    }
}

// MARK: - Message Compression Manager
class MessageCompressionManager {
    static func compressMessage(_ message: String) -> Data? {
        guard let data = message.data(using: .utf8) else { return nil }
        return try? (data as NSData).compressed(using: .lz4)
    }
    
    static func decompressMessage(_ data: Data) -> String? {
        guard let decompressed = try? (data as NSData).decompressed(using: .lz4) else { return nil }
        return String(data: decompressed as Data, encoding: .utf8)
    }
}

// MARK: - Message Highlighting
struct HighlightedMessageView: View {
    let message: MessageViewData
    let searchTerm: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(highlightedContent)
                .padding()
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(8)
        }
    }
    
    private var highlightedContent: AttributedString {
        var result = AttributedString(message.content)
        let range = result.range(of: searchTerm, options: .caseInsensitive)
        if let range = range {
            result[range].backgroundColor = .yellow
        }
        return result
    }
}

// MARK: - Message Pagination Manager
class MessagePaginationManager: ObservableObject {
    @Published var messages: [MessageViewData] = []
    @Published var isLoadingMore = false
    @Published var currentPage = 0
    @Published var pageSize = 20
    @Published var hasMorePages = true
    
    func loadNextPage(from allMessages: [MessageViewData]) {
        guard hasMorePages && !isLoadingMore else { return }
        
        isLoadingMore = true
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let startIndex = self.currentPage * self.pageSize
            let endIndex = min(startIndex + self.pageSize, allMessages.count)
            
            if startIndex < allMessages.count {
                let pageMessages = Array(allMessages[startIndex..<endIndex])
                
                DispatchQueue.main.async {
                    self.messages.append(contentsOf: pageMessages)
                    self.currentPage += 1
                    self.hasMorePages = endIndex < allMessages.count
                    self.isLoadingMore = false
                }
            } else {
                DispatchQueue.main.async {
                    self.hasMorePages = false
                    self.isLoadingMore = false
                }
            }
        }
    }
    
    func reset() {
        messages.removeAll()
        currentPage = 0
        hasMorePages = true
    }
}

// MARK: - Message Reaction Analytics
class MessageReactionAnalyticsManager: ObservableObject {
    @Published var reactionStats: [String: Int] = [:]
    @Published var mostUsedReaction: String?
    
    func analyzeReactions(from messages: [MessageViewData]) {
        var stats: [String: Int] = [:]
        
        for message in messages {
            for emoji in message.reactions.keys {
                stats[emoji, default: 0] += message.reactions[emoji]?.count ?? 0
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.reactionStats = stats
            self?.mostUsedReaction = stats.max(by: { $0.value < $1.value })?.key
        }
    }
    
    func getReactionPercentage(for emoji: String) -> Double {
        let total = reactionStats.values.reduce(0, +)
        guard total > 0 else { return 0 }
        return Double(reactionStats[emoji] ?? 0) / Double(total) * 100
    }
}

// MARK: - Message Conflict Resolution Manager
class MessageConflictResolutionManager {
    enum ConflictType {
        case duplicateMessage
        case outOfOrderMessages
        case missingReferences
    }
    
    static func resolveConflict(_ type: ConflictType) -> String {
        switch type {
        case .duplicateMessage:
            return "Duplicate message detected and removed"
        case .outOfOrderMessages:
            return "Messages reordered by timestamp"
        case .missingReferences:
            return "Missing references updated"
        }
    }
}

// MARK: - Message DeepLink Handler
class MessageDeepLinkManager: ObservableObject {
    @Published var selectedMessageId: String?
    @Published var selectedThreadId: String?
    
    func handleDeepLink(_ url: URL) {
        let components = url.pathComponents
        
        if components.contains("message"), let messageId = components.last {
            selectedMessageId = messageId
        } else if components.contains("thread"), let threadId = components.last {
            selectedThreadId = threadId
        }
    }
    
    func generateDeepLink(for messageId: String) -> URL? {
        return URL(string: "storyweave://message/\(messageId)")
    }
}

// MARK: - Message Background Sync
class MessageBackgroundSyncManager: NSObject, ObservableObject {
    @Published var isSyncingInBackground = false
    @Published var backgroundSyncStatus = "Idle"
    
    func startBackgroundSync() {
        isSyncingInBackground = true
        backgroundSyncStatus = "Syncing..."
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            // Simulate background sync
            sleep(2)
            
            DispatchQueue.main.async {
                self?.isSyncingInBackground = false
                self?.backgroundSyncStatus = "Completed"
            }
        }
    }
    
    func cancelBackgroundSync() {
        isSyncingInBackground = false
        backgroundSyncStatus = "Cancelled"
    }
}

// MARK: - End of Message Code

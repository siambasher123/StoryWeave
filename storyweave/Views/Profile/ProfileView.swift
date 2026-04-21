import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var inventoryVM = InventoryViewModel()
    @State private var editingName = false
    @State private var segment = 0

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroBanner

                    Picker("", selection: $segment) {
                        Text("Stats").tag(0)
                        Text("Inventory").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, swSpacing * 2)
                    .padding(.top, swSpacing * 2)

                    if segment == 0 {
                        statsGrid
                        analyticsExtras
                        signOutButton
                            .padding(.horizontal, swSpacing * 2)
                            .padding(.bottom, swSpacing * 4)
                    } else {
                        inventorySection
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            await inventoryVM.load()
        }
        .sheet(isPresented: $editingName) {
            EditNameSheet(currentName: viewModel.profile?.displayName ?? "") { name in
                Task { await viewModel.updateDisplayName(name) }
            }
        }
    }

    // MARK: — Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#3C3668"), Color(hex: "#231F48"), Color.swBackground],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 240)

            // Diffuse glow at banner bottom edge
            Capsule()
                .fill(Color.swAccentPrimary.opacity(0.08))
                .blur(radius: 20)
                .frame(width: 320, height: 80)
                .offset(y: 30)

            VStack(spacing: swSpacing) {
                avatarCircle
                    .padding(.top, swSpacing * 4)

                Button {
                    editingName = true
                } label: {
                    HStack(spacing: swSpacing) {
                        Text(viewModel.profile?.displayName ?? "Adventurer")
                            .font(.swTitle)
                            .foregroundStyle(Color.swTextPrimary)
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.swAccentPrimary)
                    }
                }
                .accessibilityLabel("Edit display name: \(viewModel.profile?.displayName ?? "Adventurer")")

                VStack(spacing: 4) {
                    if let email = viewModel.email {
                        Text(email)
                            .font(.swCaption)
                            .foregroundStyle(Color.swTextSecondary)
                    }
                    if let date = viewModel.profile?.createdAt {
                        Text("Adventuring since \(date.formatted(.dateTime.month(.wide).year()))")
                            .font(.swCaption)
                            .foregroundStyle(Color.swTextSecondary)
                    }
                }

                PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                    Label("Change Photo", systemImage: "camera")
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentPrimary)
                }
                .padding(.bottom, swSpacing * 2)
                .onChange(of: viewModel.selectedPhoto) { _, item in
                    if let item { Task { await viewModel.uploadAvatar(item) } }
                }
            }
        }
    }

    private var avatarCircle: some View {
        ZStack {
            // Conditional gold achievement ring (outermost)
            if !inventoryVM.unlockedAchievements.isEmpty {
                Circle()
                    .stroke(LinearGradient.swGradientGold, lineWidth: 1.5)
                    .frame(width: 106, height: 106)
            }

            // Gradient primary ring
            Circle()
                .stroke(LinearGradient.swGradientPrimary, lineWidth: 2.5)
                .frame(width: 98, height: 98)
                .shadow(color: Color.swAccentPrimary.opacity(0.35), radius: 14, x: 0, y: 4)

            // Radial fill
            Circle()
                .fill(RadialGradient(
                    colors: [Color.swAccentPrimary.opacity(0.30), Color.swAccentPrimary.opacity(0.05)],
                    center: .center, startRadius: 0, endRadius: 48))
                .frame(width: 92, height: 92)

            if let url = viewModel.profile?.avatarURL.flatMap(URL.init) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarInitial
                }
                .frame(width: 92, height: 92)
                .clipShape(Circle())
            } else {
                avatarInitial
            }

            if viewModel.isLoading {
                Circle().fill(Color.swBackground.opacity(0.7)).frame(width: 92, height: 92)
                ProgressView().tint(Color.swAccentPrimary)
            }
        }
    }

    private var avatarInitial: some View {
        Text(String((viewModel.profile?.displayName ?? "A").prefix(1)).uppercased())
            .font(.system(size: 38, weight: .semibold))
            .foregroundStyle(Color.swAccentPrimary)
    }

    // MARK: — Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            sectionHeader("Game Analytics")

            if let stats = viewModel.profile?.gameStats {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: swSpacing) {
                    StatCard(icon: "⚔️", value: "\(stats.combatsWon)", label: "Combats Won",   accent: .swSuccess)
                    StatCard(icon: "🛡", value: "\(stats.combatsLost)", label: "Combats Lost", accent: .swAccentSecondary)
                    StatCard(icon: "📖", value: "\(stats.actsCompleted)/5", label: "Acts Done",  accent: .swAccentPrimary)
                    StatCard(icon: "💀", value: "\(stats.charactersLost)", label: "Heroes Lost", accent: .swDanger)
                    StatCard(icon: "🎯", value: "\(stats.skillChecksPassed)/\(stats.skillChecksAttempted)",
                             label: "Skill Checks",  accent: .swAccentLight)
                    StatCard(icon: "⏱", value: formatPlaytime(stats.totalPlaytimeSeconds),
                             label: "Playtime",      accent: .swAccentHighlight)
                }

                winRateBar(stats: stats)
            } else {
                Text("No stats yet — start an adventure!")
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)
                    .padding(swSpacing * 2)
            }
        }
        .padding(.horizontal, swSpacing * 2)
        .padding(.top, swSpacing * 2)
    }

    private func winRateBar(stats: GameAnalytics) -> some View {
        let total = stats.combatsWon + stats.combatsLost
        let rate  = total > 0 ? Double(stats.combatsWon) / Double(total) : 0

        return VStack(alignment: .leading, spacing: swSpacing) {
            HStack {
                Text("Combat Win Rate")
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)
                Spacer()
                Text(total > 0 ? "\(Int(rate * 100))%" : "—")
                    .font(.swHeadline)
                    .foregroundStyle(rate >= 0.5 ? Color.swSuccess : Color.swAccentSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.swSurface).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.swAccentPrimary, Color.swSuccess],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * rate, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(swSpacing * 2)
        .background(LinearGradient.swGradientSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: — Extra analytics

    private var analyticsExtras: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            if let stats = viewModel.profile?.gameStats, stats.skillChecksAttempted > 0 {
                sectionHeader("Skill Check Accuracy")
                    .padding(.horizontal, swSpacing * 2)

                let accuracy = Double(stats.skillChecksPassed) / Double(stats.skillChecksAttempted)
                VStack(alignment: .leading, spacing: swSpacing) {
                    HStack {
                        Text("Passed \(stats.skillChecksPassed) of \(stats.skillChecksAttempted)")
                            .font(.swBody)
                            .foregroundStyle(Color.swTextSecondary)
                        Spacer()
                        Text("\(Int(accuracy * 100))%")
                            .font(.swHeadline)
                            .foregroundStyle(Color.swAccentLight)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.swSurface).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.swAccentLight)
                                .frame(width: geo.size.width * accuracy, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(swSpacing * 2)
                .background(Color.swSurface, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, swSpacing * 2)
            }
        }
        .padding(.top, swSpacing)
        .padding(.bottom, swSpacing * 2)
    }

    // MARK: — Inventory Section

    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: swSpacing * 3) {
            if !inventoryVM.inventory.isEmpty {
                VStack(alignment: .leading, spacing: swSpacing) {
                    Text("Items")
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                        .padding(.horizontal, swSpacing * 2)
                        .padding(.top, swSpacing * 2)

                    ForEach(ItemType.allCases, id: \.self) { type in
                        let items = inventoryVM.inventory.filter { $0.itemType == type }
                        if !items.isEmpty {
                            SWCard {
                                VStack(alignment: .leading, spacing: swSpacing) {
                                    Text(type.rawValue.capitalized)
                                        .font(.swCaption)
                                        .foregroundStyle(Color.swTextSecondary)
                                        .padding(.bottom, 4)
                                    ForEach(items) { item in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(.swBody)
                                                    .foregroundStyle(Color.swTextPrimary)
                                                Text(item.loreDescription)
                                                    .font(.swCaption)
                                                    .foregroundStyle(Color.swTextSecondary)
                                            }
                                            Spacer()
                                            Text("×\(item.quantity)")
                                                .font(.swHeadline)
                                                .foregroundStyle(Color.swAccentPrimary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, swSpacing * 2)
                        }
                    }
                }
            } else {
                VStack(spacing: swSpacing * 2) {
                    Image(systemName: "bag")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.swTextSecondary)
                    Text("No items yet")
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextSecondary)
                    Text("Start an adventure to collect items")
                        .font(.swBody)
                        .foregroundStyle(Color.swTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, swSpacing * 4)
            }

            if !inventoryVM.unlockedAchievements.isEmpty {
                VStack(alignment: .leading, spacing: swSpacing) {
                    Text("Achievements")
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                        .padding(.horizontal, swSpacing * 2)

                    ForEach(inventoryVM.unlockedAchievements) { achievement in
                        SWCard {
                            HStack(spacing: swSpacing * 2) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(Color.swWarning)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(achievement.title)
                                        .font(.swHeadline)
                                        .foregroundStyle(Color.swTextPrimary)
                                    Text(achievement.description)
                                        .font(.swCaption)
                                        .foregroundStyle(Color.swTextSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, swSpacing * 2)
                    }
                }
            }
        }
        .padding(.bottom, swSpacing * 4)
    }

    // MARK: — Sign Out

    private var signOutButton: some View {
        VStack(spacing: swSpacing * 2) {
            Divider().background(Color.swSurfaceRaised)

            SWButton(title: "Sign Out", style: .danger) {
                viewModel.signOut()
            }
        }
    }

    // MARK: — Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.swHeadline)
            .foregroundStyle(Color.swTextPrimary)
    }

    private func formatPlaytime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return m > 0 ? "\(m)m" : "—"
    }
}

// MARK: — Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(spacing: 0) {
            // Top color band — unique identity per card
            Rectangle()
                .fill(accent.swGradientTopEdge())
                .frame(height: 3)
                .frame(maxWidth: .infinity)

            VStack(spacing: swSpacing) {
                Text(icon).font(.title2)
                    .padding(.top, swSpacing)
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [accent, accent.opacity(0.65)],
                        startPoint: .top, endPoint: .bottom))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(label)
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, swSpacing)
            }
        }
        .frame(maxWidth: .infinity)
        .background(LinearGradient.swGradientSurface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}

// MARK: — Edit Name Sheet

struct EditNameSheet: View {
    @State private var name: String
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void

    init(currentName: String, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: currentName)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                VStack(spacing: swSpacing * 2) {
                    SWTextField(placeholder: "Display Name", text: $name, isSecure: false)
                    Spacer()
                }
                .padding(swSpacing * 2)
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.swTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { onSave(name); dismiss() }
                        .foregroundStyle(Color.swAccentPrimary)
                        .disabled(name.trimmingCharacters(in: .whitespaces).count < 2)
                }
            }
        }
    }
}

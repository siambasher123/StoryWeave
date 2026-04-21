import SwiftUI

struct SkillBrowserView: View {
    @StateObject private var viewModel = SkillBrowserViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(Color.swAccentPrimary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: swSpacing) {
                            ForEach(viewModel.skills) { skill in
                                SkillCardView(skill: skill)
                            }
                        }
                        .padding(swSpacing * 2)
                    }
                }
            }
            .navigationTitle("Skills")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Skill Card (used in Library + browser)

struct SkillCardView: View {
    let skill: Skill
    var isOwn: Bool = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                HStack {
                    Text(skill.name)
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                    Spacer()
                    Text(skill.targetType.rawValue.capitalized)
                        .font(.swCaption)
                        .foregroundStyle(Color.swBackground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.swAccentHighlight)
                        .clipShape(Capsule())

                    if isOwn {
                        if let onEdit {
                            Button(action: onEdit) {
                                Image(systemName: "pencil.circle")
                                    .foregroundStyle(Color.swAccentPrimary)
                            }
                            .accessibilityLabel("Edit skill")
                        }
                        if let onDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash.circle")
                                    .foregroundStyle(Color.swDanger)
                            }
                            .accessibilityLabel("Delete skill")
                        }
                    }
                }

                Text(skill.description)
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)

                HStack(spacing: swSpacing * 2) {
                    Label("\(skill.statAffected.rawValue.uppercased()) +\(skill.modifier)", systemImage: "bolt.fill")
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentPrimary)
                    Label("Cooldown: \(skill.cooldownTurns)t", systemImage: "clock")
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }
            }
        }
    }
}

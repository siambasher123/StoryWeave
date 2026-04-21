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

struct SkillCardView: View {
    let skill: Skill

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

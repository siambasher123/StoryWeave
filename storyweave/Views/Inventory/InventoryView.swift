import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: swSpacing * 3) {
                    if !viewModel.inventory.isEmpty {
                        VStack(alignment: .leading, spacing: swSpacing) {
                            Text("Items")
                                .font(.swHeadline)
                                .foregroundStyle(Color.swTextPrimary)
                                .padding(.horizontal, swSpacing * 2)

                            ForEach(ItemType.allCases, id: \.self) { type in
                                let items = viewModel.inventory.filter { $0.itemType == type }
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
                                .font(.system(size: 48))
                                .foregroundStyle(Color.swTextSecondary)
                            Text("No items yet")
                                .font(.swHeadline)
                                .foregroundStyle(Color.swTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, swSpacing * 6)
                    }

                    if !viewModel.unlockedAchievements.isEmpty {
                        VStack(alignment: .leading, spacing: swSpacing) {
                            Text("Achievements")
                                .font(.swHeadline)
                                .foregroundStyle(Color.swTextPrimary)
                                .padding(.horizontal, swSpacing * 2)

                            ForEach(viewModel.unlockedAchievements) { achievement in
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
                .padding(.vertical, swSpacing * 2)
            }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
    }
}

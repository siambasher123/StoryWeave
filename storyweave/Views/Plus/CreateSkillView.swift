import SwiftUI

struct CreateSkillView: View {
    @StateObject private var viewModel = CreateSkillViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: swSpacing * 2) {
                        SWTextField(placeholder: "Skill Name", text: $viewModel.name, isSecure: false)

                        ZStack(alignment: .topLeading) {
                            Color.swSurface.clipShape(RoundedRectangle(cornerRadius: 14))
                            TextEditor(text: $viewModel.description)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(Color.swTextPrimary)
                                .font(.swBody)
                                .padding(swSpacing)
                                .frame(minHeight: 80)
                            if viewModel.description.isEmpty {
                                Text("Skill description...")
                                    .font(.swBody)
                                    .foregroundStyle(Color.swTextSecondary)
                                    .padding(swSpacing + 4)
                                    .allowsHitTesting(false)
                            }
                        }

                        Picker("Stat Affected", selection: $viewModel.statAffected) {
                            ForEach(StatType.allCases, id: \.self) { stat in
                                Text(stat.rawValue.uppercased()).tag(stat)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Target", selection: $viewModel.targetType) {
                            ForEach(TargetType.allCases, id: \.self) { target in
                                Text(target.rawValue.capitalized).tag(target)
                            }
                        }
                        .pickerStyle(.segmented)

                        StatSlider(label: "Modifier", value: $viewModel.modifier, range: 1...50)
                        StatSlider(label: "Cooldown", value: $viewModel.cooldownTurns, range: 0...5)

                        if let err = viewModel.errorMessage {
                            Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
                        }

                        SWButton(title: viewModel.isLoading ? "Creating..." : "Create Skill", style: .primary) {
                            Task {
                                await viewModel.create()
                                if viewModel.didCreate { dismiss() }
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(swSpacing * 2)
                }
            }
            .navigationTitle("New Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.swTextSecondary)
                }
            }
        }
    }
}

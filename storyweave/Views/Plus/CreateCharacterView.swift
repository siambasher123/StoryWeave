import SwiftUI
import PhotosUI

struct CreateCharacterView: View {
    @StateObject private var viewModel: CreateCharacterViewModel
    @Environment(\.dismiss) private var dismiss

    private let editingCharacter: Character?

    init(editing character: Character? = nil) {
        editingCharacter = character
        _viewModel = StateObject(wrappedValue: CreateCharacterViewModel(editing: character))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: swSpacing * 2) {
                        SWTextField(placeholder: "Character Name", text: $viewModel.name, isSecure: false)

                        Picker("Archetype", selection: $viewModel.archetype) {
                            ForEach(Archetype.allCases, id: \.self) { arch in
                                Text(arch.rawValue.capitalized).tag(arch)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.swAccentPrimary)

                        VStack(alignment: .leading, spacing: swSpacing) {
                            Text("Stats").font(.swHeadline).foregroundStyle(Color.swTextPrimary)
                            StatSlider(label: "Max HP", value: $viewModel.hp, range: 50...200)
                            StatSlider(label: "Attack", value: $viewModel.atk, range: 1...20)
                            StatSlider(label: "Defense", value: $viewModel.def, range: 0...20)
                            StatSlider(label: "Dexterity", value: $viewModel.dex, range: 1...20)
                            StatSlider(label: "Intelligence", value: $viewModel.intel, range: 1...20)
                        }

                        ZStack(alignment: .topLeading) {
                            Color.swSurface.clipShape(RoundedRectangle(cornerRadius: 14))
                            TextEditor(text: $viewModel.loreDescription)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(Color.swTextPrimary)
                                .font(.swBody)
                                .padding(swSpacing)
                                .frame(minHeight: 80)
                            if viewModel.loreDescription.isEmpty {
                                Text("Character lore...")
                                    .font(.swBody)
                                    .foregroundStyle(Color.swTextSecondary)
                                    .padding(swSpacing + 4)
                                    .allowsHitTesting(false)
                            }
                        }

                        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Add Portrait")
                            }
                            .font(.swBody)
                            .foregroundStyle(Color.swAccentPrimary)
                        }

                        if let err = viewModel.errorMessage {
                            Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
                        }

                        SWButton(
                            title: viewModel.isLoading ? "Saving..." : (editingCharacter == nil ? "Create Character" : "Save Changes"),
                            style: .primary
                        ) {
                            Task {
                                if let existing = editingCharacter {
                                    await viewModel.update(character: existing)
                                } else {
                                    await viewModel.create()
                                }
                                if viewModel.didCreate { dismiss() }
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(swSpacing * 2)
                }
            }
            .navigationTitle(editingCharacter == nil ? "New Character" : "Edit Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.swTextSecondary)
                }
            }
        }
    }
}

struct StatSlider: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
                .font(.swBody)
                .foregroundStyle(Color.swTextSecondary)
                .frame(width: 100, alignment: .leading)
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
            .tint(Color.swAccentPrimary)
            Text("\(value)")
                .font(.swCaption)
                .foregroundStyle(Color.swTextPrimary)
                .frame(width: 32)
        }
    }
}

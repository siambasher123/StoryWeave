import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCharacterPicker = false
    @State private var showSkillPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: swSpacing * 2) {
                        bodyEditor
                        imageRow
                        attachmentRow
                        errorLabel
                        postButton
                    }
                    .padding(swSpacing * 2)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.swTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showCharacterPicker) {
            CharacterPickerSheet(selectedID: $viewModel.attachedCharacterID)
        }
        .sheet(isPresented: $showSkillPicker) {
            SkillPickerSheet(selectedID: $viewModel.attachedSkillID)
        }
    }

    // MARK: — Sub-views

    private var bodyEditor: some View {
        ZStack(alignment: .topLeading) {
            Color.swSurface
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.swAccentDeep.opacity(0.6), lineWidth: 1)
                )
            TextEditor(text: $viewModel.body)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Color.swTextPrimary)
                .font(.swBody)
                .tint(Color.swAccentPrimary)
                .padding(swSpacing)
                .frame(minHeight: 120)
            if viewModel.body.isEmpty {
                Text("What's happening in your adventure?")
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)
                    .padding(swSpacing + 4)
                    .allowsHitTesting(false)
            }
        }
    }

    private var imageRow: some View {
        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
            HStack {
                Image(systemName: "photo")
                Text("Add Image")
            }
            .font(.swBody)
            .foregroundStyle(Color.swAccentPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Add image to post")
    }

    private var attachmentRow: some View {
        VStack(spacing: swSpacing) {
            Button {
                showCharacterPicker = true
            } label: {
                HStack {
                    Image(systemName: "person.fill.badge.plus")
                    Text(viewModel.attachedCharacterID.map { _ in "Character attached ✓" } ?? "Attach a Character")
                    Spacer()
                }
                .font(.swBody)
                .foregroundStyle(viewModel.attachedCharacterID == nil ? Color.swAccentPrimary : Color.swSuccess)
            }
            .accessibilityLabel(viewModel.attachedCharacterID == nil ? "Attach character" : "Character attached, tap to change")

            Button {
                showSkillPicker = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text(viewModel.attachedSkillID.map { _ in "Skill attached ✓" } ?? "Attach a Skill")
                    Spacer()
                }
                .font(.swBody)
                .foregroundStyle(viewModel.attachedSkillID == nil ? Color.swAccentPrimary : Color.swSuccess)
            }
            .accessibilityLabel(viewModel.attachedSkillID == nil ? "Attach skill" : "Skill attached, tap to change")
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if let err = viewModel.errorMessage {
            Text(err)
                .font(.swCaption)
                .foregroundStyle(Color.swDanger)
        }
    }

    private var postButton: some View {
        SWButton(title: viewModel.isLoading ? "Posting..." : "Post", style: .primary) {
            Task {
                await viewModel.submit()
                if viewModel.didPost { dismiss() }
            }
        }
        .disabled(viewModel.isLoading)
        .accessibilityLabel("Submit post")
    }
}

// MARK: — Character picker sheet

private struct CharacterPickerSheet: View {
    @Binding var selectedID: String?
    @StateObject private var vm = CharacterBrowserViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                if vm.isLoading {
                    ProgressView().tint(Color.swAccentPrimary)
                } else {
                    List(vm.characters) { character in
                        Button {
                            selectedID = character.id
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(character.name)
                                    .font(.swHeadline)
                                    .foregroundStyle(Color.swTextPrimary)
                                Text(character.archetype.rawValue.capitalized)
                                    .font(.swCaption)
                                    .foregroundStyle(Color.swAccentLight)
                            }
                        }
                        .listRowBackground(selectedID == character.id ? Color.swAccentDeep : Color.swSurface)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Pick a Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.swAccentPrimary)
                }
                if selectedID != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Remove") { selectedID = nil; dismiss() }
                            .foregroundStyle(Color.swDanger)
                    }
                }
            }
            .task { await vm.load() }
        }
    }
}

// MARK: — Skill picker sheet

private struct SkillPickerSheet: View {
    @Binding var selectedID: String?
    @StateObject private var vm = SkillBrowserViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                if vm.isLoading {
                    ProgressView().tint(Color.swAccentPrimary)
                } else {
                    List(vm.skills) { skill in
                        Button {
                            selectedID = skill.id
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(skill.name)
                                    .font(.swHeadline)
                                    .foregroundStyle(Color.swTextPrimary)
                                Text(skill.description)
                                    .font(.swCaption)
                                    .foregroundStyle(Color.swTextSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .listRowBackground(selectedID == skill.id ? Color.swAccentDeep : Color.swSurface)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Pick a Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.swAccentPrimary)
                }
                if selectedID != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Remove") { selectedID = nil; dismiss() }
                            .foregroundStyle(Color.swDanger)
                    }
                }
            }
            .task { await vm.load() }
        }
    }
}

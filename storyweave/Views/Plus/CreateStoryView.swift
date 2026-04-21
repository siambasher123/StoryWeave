import SwiftUI

struct CreateStoryView: View {
    @StateObject private var vm = StoryBuilderViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: BuilderStep = .info
    @State private var selectedSceneID: String?
    @State private var showSceneEditor = false

    enum BuilderStep: Int, CaseIterable {
        case info, scenes, review
        var title: String {
            switch self { case .info: "Story Info"; case .scenes: "Scenes"; case .review: "Review & Publish" }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    stepIndicator
                    Divider().background(Color.swAccentDeep)
                    stepContent
                    Spacer()
                    navigationButtons
                        .padding(.horizontal, swSpacing * 2)
                        .padding(.bottom, swSpacing * 3)
                }
            }
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
        .sheet(isPresented: $showSceneEditor) {
            if let id = selectedSceneID,
               let scene = vm.story.scenes.first(where: { $0.id == id }) {
                SceneEditorView(scene: scene) { updated in
                    vm.updateScene(updated)
                }
            }
        }
        .alert("Saved!", isPresented: $vm.didSave) {
            Button("OK") { dismiss() }
        }
        .alert(vm.saveError ?? "Error", isPresented: Binding(
            get: { vm.saveError != nil },
            set: { if !$0 { vm.saveError = nil } }
        )) {
            Button("OK") { vm.saveError = nil }
        }
    }

    // MARK: — Steps

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(BuilderStep.allCases, id: \.rawValue) { step in
                HStack(spacing: swSpacing) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.swAccentPrimary : Color.swSurface)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(step.rawValue + 1)")
                                .font(.swCaption)
                                .foregroundStyle(step.rawValue <= currentStep.rawValue ? Color.swTextPrimary : Color.swTextSecondary)
                        )
                    Text(step.title)
                        .font(.swCaption)
                        .foregroundStyle(step.rawValue == currentStep.rawValue ? Color.swTextPrimary : Color.swTextSecondary)
                }
                if step != BuilderStep.allCases.last {
                    Rectangle().fill(Color.swSurface).frame(height: 1).padding(.horizontal, swSpacing)
                }
            }
        }
        .padding(swSpacing * 2)
    }

    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            VStack(spacing: swSpacing * 2) {
                switch currentStep {
                case .info:    infoStep
                case .scenes:  scenesStep
                case .review:  reviewStep
                }
            }
            .padding(swSpacing * 2)
        }
    }

    private var infoStep: some View {
        VStack(alignment: .leading, spacing: swSpacing * 2) {
            SWCard {
                VStack(alignment: .leading, spacing: swSpacing) {
                    Text("Title").font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    TextField("My Epic Adventure", text: $vm.story.title)
                        .font(.swBody)
                        .foregroundStyle(Color.swTextPrimary)
                        .padding(swSpacing)
                        .background(Color.swSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            SWCard {
                VStack(alignment: .leading, spacing: swSpacing) {
                    Text("Synopsis").font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    TextEditor(text: $vm.story.synopsis)
                        .font(.swBody)
                        .foregroundStyle(Color.swTextPrimary)
                        .frame(minHeight: 80)
                        .padding(swSpacing)
                        .background(Color.swSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var scenesStep: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            HStack {
                Text("Scenes (\(vm.story.scenes.count)/40)")
                    .font(.swHeadline).foregroundStyle(Color.swTextPrimary)
                Spacer()
                Button {
                    vm.addScene()
                    selectedSceneID = vm.story.scenes.last?.id
                    showSceneEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2).foregroundStyle(Color.swAccentPrimary)
                }
                .disabled(vm.story.scenes.count >= 40)
            }

            if vm.story.scenes.isEmpty {
                Text("No scenes yet. Tap + to add your first scene.")
                    .font(.swBody).foregroundStyle(Color.swTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(swSpacing * 4)
            } else {
                ForEach(vm.story.scenes) { scene in
                    SceneRowView(
                        scene: scene,
                        isStart: scene.id == vm.story.startSceneID,
                        onEdit: {
                            selectedSceneID = scene.id
                            showSceneEditor = true
                        },
                        onDelete: { vm.removeScene(id: scene.id) },
                        onSetStart: {
                            vm.story.startSceneID = scene.id
                        }
                    )
                }
            }
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: swSpacing * 2) {
            SWCard {
                VStack(alignment: .leading, spacing: swSpacing) {
                    Text(vm.story.title.isEmpty ? "Untitled" : vm.story.title)
                        .font(.swTitle).foregroundStyle(Color.swTextPrimary)
                    Text(vm.story.synopsis.isEmpty ? "No synopsis" : vm.story.synopsis)
                        .font(.swBody).foregroundStyle(Color.swTextSecondary)
                    Divider().background(Color.swSurfaceRaised)
                    Text("\(vm.story.scenes.count) scene(s)")
                        .font(.swCaption).foregroundStyle(Color.swAccentLight)
                }
            }

            if let err = vm.validationError {
                Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
                    .padding(swSpacing).background(Color.swDanger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            SWButton(title: "Save Draft", style: .secondary) {
                Task { await vm.save() }
            }
            SWButton(title: "Publish to Community", style: .primary) {
                Task { await vm.publish() }
            }
            .disabled(!vm.isValid || vm.isSaving)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: swSpacing * 2) {
            if currentStep.rawValue > 0 {
                SWButton(title: "Back", style: .secondary) {
                    withAnimation { currentStep = BuilderStep(rawValue: currentStep.rawValue - 1) ?? .info }
                }
            }
            if currentStep != .review {
                SWButton(title: "Next", style: .primary) {
                    withAnimation { currentStep = BuilderStep(rawValue: currentStep.rawValue + 1) ?? .review }
                }
            }
        }
    }
}

// MARK: — Scene Row

private struct SceneRowView: View {
    let scene: UserStoryScene
    let isStart: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetStart: () -> Void

    var body: some View {
        SWCard {
            HStack(spacing: swSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: swSpacing) {
                        Text(scene.sceneType.rawValue.capitalized)
                            .font(.swCaption).foregroundStyle(Color.swAccentLight)
                        if isStart {
                            SWPillBadge(text: "START", color: .swSuccess)
                        }
                    }
                    Text(scene.narrationText.isEmpty ? "No narration" : scene.narrationText)
                        .font(.swBody).foregroundStyle(Color.swTextPrimary)
                        .lineLimit(2)
                }
                Spacer()
                Menu {
                    Button("Edit") { onEdit() }
                    if !isStart { Button("Set as Start") { onSetStart() } }
                    Button("Delete", role: .destructive) { onDelete() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3).foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
    }
}

// MARK: — Scene Editor

struct SceneEditorView: View {
    @State var scene: UserStoryScene
    let onSave: (UserStoryScene) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newChoiceLabel = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: swSpacing * 2) {
                        scenePicker
                        narrationField
                        if scene.sceneType == .dialogue { npcField }
                        if scene.sceneType == .combat { enemySection }
                        if scene.sceneType == .skillCheck { skillCheckSection }
                        if scene.sceneType != .combat { choicesSection }
                    }
                    .padding(swSpacing * 2)
                }
            }
            .navigationTitle("Edit Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.swTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { onSave(scene); dismiss() }
                        .foregroundStyle(Color.swAccentPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var scenePicker: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                Text("Scene Type").font(.swCaption).foregroundStyle(Color.swTextSecondary)
                Picker("Type", selection: $scene.sceneType) {
                    ForEach(SceneType.allCases, id: \.self) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var narrationField: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                Text("Narration / Description").font(.swCaption).foregroundStyle(Color.swTextSecondary)
                TextEditor(text: $scene.narrationText)
                    .font(.swBody).foregroundStyle(Color.swTextPrimary)
                    .frame(minHeight: 100)
                    .padding(swSpacing)
                    .background(Color.swSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var npcField: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                Text("NPC Name").font(.swCaption).foregroundStyle(Color.swTextSecondary)
                TextField("Mysterious Stranger", text: Binding(
                    get: { scene.npcName ?? "" },
                    set: { scene.npcName = $0.isEmpty ? nil : $0 }
                ))
                .font(.swBody).foregroundStyle(Color.swTextPrimary)
                .padding(swSpacing).background(Color.swSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var enemySection: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                HStack {
                    Text("Enemies").font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    Spacer()
                    Button {
                        var enemies = scene.enemies ?? []
                        enemies.append(EnemyTemplate(name: "Goblin", emoji: "👺", hp: 20, atk: 5, def: 3, dex: 4))
                        scene.enemies = enemies
                    } label: {
                        Image(systemName: "plus").foregroundStyle(Color.swAccentPrimary)
                    }
                }
                ForEach(Binding(get: { scene.enemies ?? [] }, set: { scene.enemies = $0 })) { $enemy in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("Name", text: $enemy.name)
                                .font(.swBody).foregroundStyle(Color.swTextPrimary)
                            TextField("Emoji", text: $enemy.emoji)
                                .font(.swBody).frame(width: 44)
                            Spacer()
                            Button { scene.enemies?.removeAll { $0.id == enemy.id } } label: {
                                Image(systemName: "trash").foregroundStyle(Color.swDanger)
                            }
                        }
                        HStack(spacing: swSpacing) {
                            StatStepper(label: "HP", value: $enemy.hp)
                            StatStepper(label: "ATK", value: $enemy.atk)
                            StatStepper(label: "DEF", value: $enemy.def)
                            StatStepper(label: "DEX", value: $enemy.dex)
                        }
                    }
                    .padding(swSpacing)
                    .background(Color.swSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var skillCheckSection: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                Text("Skill Check").font(.swCaption).foregroundStyle(Color.swTextSecondary)

                Picker("Stat", selection: Binding(
                    get: { scene.skillCheckStat ?? .dex },
                    set: { scene.skillCheckStat = $0 }
                )) {
                    ForEach(StatType.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                }
                .pickerStyle(.menu)
                .foregroundStyle(Color.swAccentPrimary)

                Stepper("DC: \(scene.skillCheckDC ?? 12)", value: Binding(
                    get: { scene.skillCheckDC ?? 12 },
                    set: { scene.skillCheckDC = $0 }
                ), in: 5...25)
                .foregroundStyle(Color.swTextPrimary)

                TextField("Success scene ID", text: Binding(
                    get: { scene.skillCheckSuccessSceneID ?? "" },
                    set: { scene.skillCheckSuccessSceneID = $0.isEmpty ? nil : $0 }
                ))
                .font(.swCaption).foregroundStyle(Color.swTextPrimary)
                .padding(swSpacing).background(Color.swSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                TextField("Failure scene ID", text: Binding(
                    get: { scene.skillCheckFailureSceneID ?? "" },
                    set: { scene.skillCheckFailureSceneID = $0.isEmpty ? nil : $0 }
                ))
                .font(.swCaption).foregroundStyle(Color.swTextPrimary)
                .padding(swSpacing).background(Color.swSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var choicesSection: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                Text("Choices").font(.swCaption).foregroundStyle(Color.swTextSecondary)

                ForEach(scene.choices.indices, id: \.self) { idx in
                    HStack {
                        Text("\(idx + 1).")
                            .font(.swCaption).foregroundStyle(Color.swTextSecondary).frame(width: 20)
                        Text(scene.choices[idx])
                            .font(.swBody).foregroundStyle(Color.swTextPrimary)
                        Spacer()
                        Button { removeChoice(at: idx) } label: {
                            Image(systemName: "minus.circle").foregroundStyle(Color.swDanger)
                        }
                    }
                }

                HStack {
                    TextField("New choice label", text: $newChoiceLabel)
                        .font(.swBody).foregroundStyle(Color.swTextPrimary)
                        .padding(swSpacing).background(Color.swSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Button {
                        guard !newChoiceLabel.isEmpty else { return }
                        scene.choices.append(newChoiceLabel)
                        newChoiceLabel = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2).foregroundStyle(Color.swAccentPrimary)
                    }
                }
            }
        }
    }

    private func removeChoice(at idx: Int) {
        let key = "\(idx)"
        scene.choices.remove(at: idx)
        scene.nextSceneIDs.removeValue(forKey: key)
    }
}

private struct StatStepper: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 10)).foregroundStyle(Color.swTextSecondary)
            Stepper("\(value)", value: $value, in: 1...99)
                .labelsHidden()
            Text("\(value)").font(.swCaption).foregroundStyle(Color.swTextPrimary)
        }
    }
}

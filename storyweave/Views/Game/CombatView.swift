import SwiftUI

struct CombatView: View {
    @ObservedObject var viewModel: GameViewModel
    let scene: GameScene

    @State private var enemies: [EnemyCombatant] = []
    @State private var phase: CombatPhase = .playerTurn
    @State private var showHitOverlay = false
    @State private var lastOutcome: CombatOutcome = .fail
    @State private var showDeathOverlay = false
    @State private var deadCharacterName = ""
    @State private var showCritParticles = false
    @State private var showSkillSheet = false
    @State private var showItemSheet = false
    @State private var taunted: String?

    // Animation state
    @State private var enemyAnimStates: [String: CharacterAnimationState] = [:]
    @State private var partyAnimStates: [String: CharacterAnimationState] = [:]
    @State private var damageNumbers: [(id: UUID, text: String, color: Color)] = []
    @State private var playerTookDamage = false
    @State private var showHealing = false

    private var partyHPPercent: Double {
        let total = viewModel.party.map(\.maxHP).reduce(0, +)
        guard total > 0 else { return 1 }
        return Double(viewModel.party.map(\.hp).reduce(0, +)) / Double(total)
    }

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()
            VignetteOverlay(partyHPPercent: partyHPPercent)

            VStack(spacing: swSpacing * 2) {
                combatLabel
                enemySection
                Divider().background(Color.swAccentDeep)
                partySection
                actionSection

                if !viewModel.combatLog.isEmpty {
                    logSection
                }
            }
            .padding(swSpacing * 2)

            AttackHitOverlay(outcome: lastOutcome, isShowing: $showHitOverlay)
            DamageScreenFlash(isShowing: $playerTookDamage)

            if showDeathOverlay {
                DeathOverlay(characterName: deadCharacterName, isShowing: $showDeathOverlay)
            }
            if showCritParticles {
                CriticalHitParticleView()
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .milliseconds(1500))
                            showCritParticles = false
                        }
                    }
            }
            if showHealing {
                HealingParticlesView()
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .milliseconds(1200))
                            showHealing = false
                        }
                    }
            }

            // Floating damage numbers
            ForEach(damageNumbers, id: \.id) { num in
                FloatingDamageNumber(text: num.text, color: num.color) {
                    damageNumbers.removeAll { $0.id == num.id }
                }
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.35)
            }
        }
        .onAppear { setupEnemies() }
        .sheet(isPresented: $showSkillSheet) { skillPickerSheet }
        .sheet(isPresented: $showItemSheet)  { itemPickerSheet }
    }

    // MARK: — Sub-views

    private var combatLabel: some View {
        Text("COMBAT")
            .font(.swCaption)
            .foregroundStyle(Color.swAccentSecondary)
            .tracking(3)
    }

    private var enemySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: swSpacing * 3) {
                ForEach(enemies) { enemy in
                    VStack(spacing: 4) {
                        ZStack {
                            CharacterSpriteView(
                                emoji: enemy.emoji,
                                state: enemyAnimStates[enemy.id] ?? .idle
                            )
                            .frame(width: 56, height: 56)
                            .opacity(enemy.hp > 0 ? 1 : 0.25)

                            if let tauntID = taunted, tauntID == enemy.id {
                                StatusBadgeView(status: .protected)
                                    .offset(x: 20, y: -20)
                            }
                        }
                        Text(enemy.name)
                            .font(.swCaption)
                            .foregroundStyle(Color.swTextSecondary)
                        hpBar(current: enemy.hp, max: enemy.maxHP, color: .swAccentSecondary)
                            .frame(width: 72)
                    }
                    .accessibilityLabel("\(enemy.name), HP \(enemy.hp) of \(enemy.maxHP)")
                }
            }
            .padding(.horizontal, swSpacing)
        }
    }

    private var partySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: swSpacing * 2) {
                ForEach(viewModel.party) { member in
                    VStack(spacing: 4) {
                        ZStack {
                            CharacterSpriteView(
                                emoji: archetypeIcon(for: member.archetype),
                                state: partyAnimStates[member.id] ?? .idle
                            )
                            .frame(width: 48, height: 48)
                            .opacity(member.hp > 0 ? 1 : 0.25)

                            if let tauntID = taunted, tauntID == member.id {
                                StatusBadgeView(status: .protected)
                                    .offset(x: 18, y: -18)
                            }
                        }
                        Text(String(member.name.prefix(7)))
                            .font(.swCaption)
                            .foregroundStyle(Color.swTextPrimary)
                        hpBar(current: member.hp, max: member.maxHP, color: .swAccentPrimary)
                            .frame(width: 60)
                    }
                    .accessibilityLabel("\(member.name), HP \(member.hp) of \(member.maxHP)")
                }
            }
            .padding(.horizontal, swSpacing)
        }
    }

    private var actionSection: some View {
        VStack(spacing: swSpacing) {
            if phase == .playerTurn {
                Text("Your turn")
                    .font(.swHeadline)
                    .foregroundStyle(Color.swAccentPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: swSpacing) {
                        SWButton(title: "⚔️ Attack", style: .danger) {
                            performPlayerAttack()
                        }
                        .frame(width: 110)
                        .accessibilityLabel("Attack")

                        SWButton(title: "🛡 Defend", style: .secondary) {
                            endPlayerTurn()
                        }
                        .frame(width: 110)
                        .accessibilityLabel("Defend")

                        SWButton(title: "✨ Skill", style: .secondary) {
                            showSkillSheet = true
                        }
                        .frame(width: 110)
                        .accessibilityLabel("Use Skill")

                        SWButton(title: "🎒 Item", style: .secondary) {
                            showItemSheet = true
                        }
                        .frame(width: 110)
                        .accessibilityLabel("Use Item")

                        if let fleeID = scene.combat?.fleeSceneID {
                            SWButton(title: "🏃 Flee", style: .secondary) {
                                Task { await viewModel.advanceToScene(fleeID) }
                            }
                            .frame(width: 110)
                            .accessibilityLabel("Flee combat")
                        }
                    }
                    .padding(.horizontal, swSpacing * 2)
                }
            } else {
                Text(phase == .botTurn ? "Allies act..." : "Enemy turn...")
                    .font(.swHeadline)
                    .foregroundStyle(
                        phase == .botTurn ? Color.swAccentLight : Color.swAccentSecondary
                    )
            }
        }
    }

    private var logSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(viewModel.combatLog.suffix(4), id: \.self) { entry in
                    Text(entry)
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 64)
        .padding(.horizontal, swSpacing)
    }

    // MARK: — Skill / Item sheets

    private var skillPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                let player = viewModel.party.first(where: { $0.id == viewModel.gameState?.playerCharacterID })
                if let player {
                    List(player.skills, id: \.self) { skillID in
                        Button(skillID.replacingOccurrences(of: "_", with: " ").capitalized) {
                            showSkillSheet = false
                            performPlayerAttack(skillBonus: 4)
                        }
                        .foregroundStyle(Color.swTextPrimary)
                        .listRowBackground(Color.swSurface)
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    Text("No skills available").foregroundStyle(Color.swTextSecondary)
                }
            }
            .navigationTitle("Choose Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showSkillSheet = false }
                        .foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
    }

    private var itemPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                let consumables = (viewModel.gameState?.inventory ?? []).filter {
                    $0.itemType == .consumable && $0.quantity > 0
                }
                if consumables.isEmpty {
                    Text("No items available").foregroundStyle(Color.swTextSecondary)
                } else {
                    List(consumables) { item in
                        Button("\(item.name) ×\(item.quantity) (+\(item.modifier) HP)") {
                            showItemSheet = false
                            useItem(item)
                        }
                        .foregroundStyle(Color.swTextPrimary)
                        .listRowBackground(Color.swSurface)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Use Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showItemSheet = false }
                        .foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
    }

    // MARK: — Setup

    private func setupEnemies() {
        enemies = (scene.combat?.enemies ?? []).map { EnemyCombatant(from: $0) }
        for enemy in enemies { enemyAnimStates[enemy.id] = .idle }
        for member in viewModel.party { partyAnimStates[member.id] = .idle }
    }

    // MARK: — Player actions

    private func performPlayerAttack(skillBonus: Int = 0) {
        guard let target = enemies.first(where: { $0.hp > 0 }),
              let player = viewModel.party.first(where: { $0.id == viewModel.gameState?.playerCharacterID })
        else { return }

        // Trigger attack animation on player
        partyAnimStates[player.id] = .attack
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            partyAnimStates[player.id] = .idle
        }

        var boostedPlayer = player
        boostedPlayer.atk += skillBonus
        let (outcome, damage) = CombatEngine.resolveAttack(attacker: boostedPlayer, target: Character(
            id: target.id, name: target.name, archetype: .warrior,
            hp: target.hp, maxHP: target.maxHP,
            atk: target.atk, def: target.def, dex: target.dex, intel: 4,
            skills: [], createdByUID: "system", loreDescription: "", level: 1, xp: 0
        ))
        lastOutcome = outcome
        showHitOverlay = true
        if outcome == .criticalSuccess { showCritParticles = true }

        // Enemy takes damage animation
        enemyAnimStates[target.id] = .takeDamage
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            enemyAnimStates[target.id] = .idle
        }

        // Floating damage number
        let dmgText = outcome == .criticalSuccess ? "CRIT! \(damage)" :
                      outcome == .criticalFail ? "MISS" : "\(damage)"
        let dmgColor: Color = outcome == .criticalSuccess ? .swWarning :
                              outcome == .criticalFail ? .swTextSecondary : .swAccentSecondary
        damageNumbers.append((id: UUID(), text: dmgText, color: dmgColor))

        if let idx = enemies.firstIndex(where: { $0.id == target.id }) {
            enemies[idx].hp = max(0, enemies[idx].hp - damage)
            if enemies[idx].hp == 0 {
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    enemyAnimStates[target.id] = .death
                }
            }
        }
        viewModel.combatLog.append("\(player.name) hits \(target.name) for \(damage) (\(outcome.rawValue))")

        if enemies.allSatisfy({ $0.hp <= 0 }) {
            // Victory animation for all party
            for member in viewModel.party { partyAnimStates[member.id] = .victory }
            Task { await viewModel.resolveCombatVictory() }
        } else {
            phase = .botTurn
            Task { await resolveBotTurns() }
        }
    }

    private func useItem(_ item: InventoryItem) {
        guard let playerIdx = viewModel.party.firstIndex(where: { $0.id == viewModel.gameState?.playerCharacterID }),
              let invItemIdx = viewModel.gameState?.inventory.firstIndex(where: { $0.id == item.id }) else { return }
        viewModel.party[playerIdx].hp = min(viewModel.party[playerIdx].maxHP,
                                             viewModel.party[playerIdx].hp + item.modifier)
        viewModel.gameState?.inventory[invItemIdx].quantity -= 1
        viewModel.combatLog.append("\(viewModel.party[playerIdx].name) uses \(item.name) (+\(item.modifier) HP)")

        // Heal animation
        partyAnimStates[viewModel.party[playerIdx].id] = .heal
        showHealing = true
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            partyAnimStates[viewModel.party[playerIdx].id] = .idle
        }

        endPlayerTurn()
    }

    private func endPlayerTurn() {
        phase = .botTurn
        Task { await resolveBotTurns() }
    }

    // MARK: — Bot turns

    private func resolveBotTurns() async {
        for idx in viewModel.bots.indices {
            let bot = viewModel.bots[idx]
            guard bot.hp > 0 else { continue }

            let action = CombatEngine.resolveBotTurn(bot: bot, party: viewModel.party, enemies: enemies)
            switch action {
            case .attackEnemy(let targetID, let damage):
                if let ei = enemies.firstIndex(where: { $0.id == targetID }) {
                    partyAnimStates[bot.id] = .attack
                    enemyAnimStates[enemies[ei].id] = .takeDamage
                    enemies[ei].hp = max(0, enemies[ei].hp - damage)
                    viewModel.combatLog.append("\(bot.name) attacks \(enemies[ei].name) for \(damage)")
                    damageNumbers.append((id: UUID(), text: "\(damage)", color: .swAccentPrimary))
                    try? await Task.sleep(for: .milliseconds(300))
                    partyAnimStates[bot.id] = .idle
                    enemyAnimStates[enemies[ei].id] = enemies[ei].hp == 0 ? .death : .idle
                }
            case .heal(let targetID, let amount):
                if let pi = viewModel.party.firstIndex(where: { $0.id == targetID }) {
                    viewModel.party[pi].hp = min(viewModel.party[pi].maxHP, viewModel.party[pi].hp + amount)
                    viewModel.combatLog.append("\(bot.name) heals \(viewModel.party[pi].name) for \(amount)")
                    partyAnimStates[viewModel.party[pi].id] = .heal
                    showHealing = true
                    damageNumbers.append((id: UUID(), text: "+\(amount)", color: .swSuccess))
                    try? await Task.sleep(for: .milliseconds(500))
                    partyAnimStates[viewModel.party[pi].id] = .idle
                }
            case .taunt(let protectID):
                taunted = protectID
                partyAnimStates[bot.id] = .taunt
                viewModel.combatLog.append("\(bot.name) taunts — protecting \(viewModel.party.first(where: { $0.id == protectID })?.name ?? "ally")")
                try? await Task.sleep(for: .milliseconds(300))
                partyAnimStates[bot.id] = .idle
            case .defend:
                partyAnimStates[bot.id] = .defend
                viewModel.combatLog.append("\(bot.name) defends")
                try? await Task.sleep(for: .milliseconds(300))
                partyAnimStates[bot.id] = .idle
            }

            try? await Task.sleep(for: .milliseconds(400))
        }

        if enemies.allSatisfy({ $0.hp <= 0 }) {
            for member in viewModel.party { partyAnimStates[member.id] = .victory }
            Task { await viewModel.resolveCombatVictory() }
            return
        }

        phase = .enemyTurn
        await resolveEnemyTurns()
    }

    private func resolveEnemyTurns() async {
        for idx in enemies.indices {
            let enemy = enemies[idx]
            guard enemy.hp > 0 else { continue }

            let target: Character?
            if let tauntID = taunted, let t = viewModel.party.first(where: { $0.id == tauntID && $0.hp > 0 }) {
                target = t
            } else {
                target = viewModel.party.filter({ $0.hp > 0 }).randomElement()
            }
            guard var t = target else { continue }

            enemyAnimStates[enemy.id] = .attack

            let roll = CombatEngine.rollD20()
            let modified = roll + enemy.atk - t.def
            let outcome = CombatOutcome.from(roll: modified)
            let damage: Int
            switch outcome {
            case .criticalFail, .fail: damage = 0
            case .partialSuccess:      damage = max(1, enemy.atk / 2)
            case .success:             damage = enemy.atk
            case .criticalSuccess:     damage = enemy.atk * 2
            }

            if let pi = viewModel.party.firstIndex(where: { $0.id == t.id }) {
                viewModel.party[pi].hp = max(0, viewModel.party[pi].hp - damage)
                t = viewModel.party[pi]

                if damage > 0 {
                    partyAnimStates[t.id] = .takeDamage
                    playerTookDamage = (t.id == viewModel.gameState?.playerCharacterID)
                    damageNumbers.append((id: UUID(), text: "-\(damage)", color: .swDanger))
                }
            }
            viewModel.combatLog.append("\(enemy.name) attacks \(t.name) for \(damage) (\(outcome.rawValue))")

            try? await Task.sleep(for: .milliseconds(300))
            enemyAnimStates[enemy.id] = .idle
            partyAnimStates[t.id] = t.hp <= 0 ? .death : .idle

            if t.hp <= 0 {
                deadCharacterName = t.name
                showDeathOverlay = true
            }
            try? await Task.sleep(for: .milliseconds(500))
        }

        taunted = nil

        if viewModel.party.allSatisfy({ $0.hp <= 0 }) {
            await viewModel.resolveCombatDefeat()
        } else {
            phase = .playerTurn
        }
    }

    // MARK: — Helpers

    private func hpBar(current: Int, max: Int, color: Color) -> some View {
        let ratio = max > 0 ? CGFloat(current) / CGFloat(max) : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.swSurface)
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geo.size.width * ratio, height: 6)
                    .animation(.easeInOut, value: ratio)
            }
        }
        .frame(height: 6)
    }

    private func archetypeIcon(for arch: Archetype) -> String {
        switch arch {
        case .warrior: return "⚔️"
        case .mage:    return "🔮"
        case .rogue:   return "🗡"
        case .cleric:  return "✨"
        case .ranger:  return "🏹"
        case .tank:    return "🛡"
        }
    }
}

private enum CombatPhase { case playerTurn, botTurn, enemyTurn }

import SwiftUI
import Combine
import PhotosUI

@MainActor
final class CreateCharacterViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var archetype: Archetype = .warrior
    @Published var loreDescription: String = ""
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didCreate = false

    @Clamped(50...200) var hp: Int = 100
    @Clamped(1...20) var atk: Int = 8
    @Clamped(0...20) var def: Int = 5
    @Clamped(1...20) var dex: Int = 7
    @Clamped(1...20) var intel: Int = 6

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private let cloudinary = CloudinaryService.shared

    // Pre-fill for editing existing character
    init(editing character: Character? = nil) {
        guard let c = character else { return }
        name = c.name
        archetype = c.archetype
        loreDescription = c.loreDescription
        hp = c.hp
        atk = c.atk
        def = c.def
        dex = c.dex
        intel = c.intel
    }

    func create() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name is required."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let uid = auth.currentUserID else { return }

        var portraitURL: String?
        if let photo = selectedPhoto,
           let data = try? await photo.loadTransferable(type: Data.self) {
            portraitURL = try? await cloudinary.upload(imageData: data).absoluteString
        }

        let character = Character(
            id: UUID().uuidString,
            name: name,
            archetype: archetype,
            hp: hp,
            maxHP: hp,
            atk: atk,
            def: def,
            dex: dex,
            intel: intel,
            skills: [],
            createdByUID: uid,
            loreDescription: loreDescription,
            level: 1,
            xp: 0,
            portraitURL: portraitURL
        )
        do {
            try firestore.createCharacter(character)
            didCreate = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(character: Character) async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name is required."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var updatedPortraitURL = character.portraitURL
        if let photo = selectedPhoto,
           let data = try? await photo.loadTransferable(type: Data.self) {
            updatedPortraitURL = try? await cloudinary.upload(imageData: data).absoluteString
        }

        var updated = character
        updated.name = name
        updated.archetype = archetype
        updated.loreDescription = loreDescription
        updated.hp = hp
        updated.maxHP = hp
        updated.atk = atk
        updated.def = def
        updated.dex = dex
        updated.intel = intel
        updated.portraitURL = updatedPortraitURL

        do {
            try firestore.updateCharacter(updated)
            didCreate = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

import SwiftUI

struct CompanionSkin: Identifiable, Equatable {
    let id: String
    let name: String
    let bodyColor: Color
    let feetColor: Color
    let blushColor: Color
    let accentColor: Color

    static let defaultSkin = CompanionSkin(
        id: "default",
        name: "Classic",
        bodyColor: Color(red: 0.92, green: 0.75, blue: 0.70),
        feetColor: Color(red: 0.88, green: 0.68, blue: 0.63),
        blushColor: Color(red: 1.0, green: 0.6, blue: 0.6),
        accentColor: .orange
    )

    static let allSkins: [CompanionSkin] = [
        defaultSkin,
        CompanionSkin(
            id: "ocean",
            name: "Ocean",
            bodyColor: Color(red: 0.6, green: 0.8, blue: 0.9),
            feetColor: Color(red: 0.5, green: 0.7, blue: 0.85),
            blushColor: Color(red: 0.8, green: 0.6, blue: 0.9),
            accentColor: .blue
        ),
        CompanionSkin(
            id: "forest",
            name: "Forest",
            bodyColor: Color(red: 0.7, green: 0.85, blue: 0.65),
            feetColor: Color(red: 0.6, green: 0.75, blue: 0.55),
            blushColor: Color(red: 0.9, green: 0.7, blue: 0.6),
            accentColor: .green
        ),
        CompanionSkin(
            id: "sunset",
            name: "Sunset",
            bodyColor: Color(red: 1.0, green: 0.8, blue: 0.6),
            feetColor: Color(red: 0.95, green: 0.7, blue: 0.5),
            blushColor: Color(red: 1.0, green: 0.5, blue: 0.5),
            accentColor: Color(red: 1.0, green: 0.6, blue: 0.4)
        ),
        CompanionSkin(
            id: "lavender",
            name: "Lavender",
            bodyColor: Color(red: 0.85, green: 0.75, blue: 0.95),
            feetColor: Color(red: 0.75, green: 0.65, blue: 0.85),
            blushColor: Color(red: 1.0, green: 0.7, blue: 0.8),
            accentColor: .purple
        ),
        CompanionSkin(
            id: "midnight",
            name: "Midnight",
            bodyColor: Color(red: 0.4, green: 0.45, blue: 0.6),
            feetColor: Color(red: 0.35, green: 0.4, blue: 0.55),
            blushColor: Color(red: 0.7, green: 0.5, blue: 0.7),
            accentColor: Color(red: 0.6, green: 0.7, blue: 1.0)
        )
    ]
}

class SkinManager: ObservableObject {
    static let shared = SkinManager()

    private let defaults = UserDefaults.standard
    private let skinKey = "selectedSkin"

    @Published var currentSkin: CompanionSkin {
        didSet {
            defaults.set(currentSkin.id, forKey: skinKey)
        }
    }

    init() {
        if let savedSkinId = defaults.string(forKey: skinKey),
           let skin = CompanionSkin.allSkins.first(where: { $0.id == savedSkinId }) {
            self.currentSkin = skin
        } else {
            self.currentSkin = .defaultSkin
        }
    }

    func selectSkin(_ skin: CompanionSkin) {
        currentSkin = skin
    }
}

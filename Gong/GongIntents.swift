import AppIntents
import Foundation

/// The attendant: a tiny bridge between an App Intent firing and the scene
/// being ready to receive the ceremony.
final class PendingCeremony {
    static let shared = PendingCeremony()
    var strikeRequested = false

    static let strikeNotification = Notification.Name("gong.ceremonialStrike")
}

/// "Siri, strike the Gong." Also mappable to the Action button — which is,
/// of course, the correct use of an Action button.
struct StrikeGongIntent: AppIntent {
    static var title: LocalizedStringResource = "Strike the Gong"
    static var description = IntentDescription("Summon the app and sound the gong, ceremonially.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // If the scene is already live it strikes at once; if the app is
        // cold-launching, the flag is consumed the moment the stage appears.
        PendingCeremony.shared.strikeRequested = true
        NotificationCenter.default.post(name: PendingCeremony.strikeNotification, object: nil)
        return .result()
    }
}

struct GongAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StrikeGongIntent(),
            phrases: [
                "Strike the \(.applicationName)",
                "Sound the \(.applicationName)",
                "\(.applicationName)",
            ],
            shortTitle: "Strike",
            systemImageName: "circle.circle.fill"
        )
    }
}

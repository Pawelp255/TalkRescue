import AppIntents

struct TalkRescueShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRescueModeIntent(),
            phrases: [
                "Start rescue mode in \(.applicationName)",
                "Rescue conversation with \(.applicationName)",
                "Open rescue mode in \(.applicationName)"
            ],
            shortTitle: "Rescue Mode",
            systemImageName: "mic.badge.plus"
        )
    }
}

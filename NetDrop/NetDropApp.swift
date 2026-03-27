import SwiftUI

@main
struct NetDropApp: App {
    @State private var favoritesStore = FavoritesStore()
    @State private var transferManager = TransferManager()
    @State private var appSettings = AppSettings()
    @State private var backupScheduler: BackupScheduler?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(favoritesStore)
                .environment(transferManager)
                .environment(appSettings)
                .optionalEnvironment(backupScheduler)
                .preferredColorScheme(appSettings.preferredColorScheme)
                .onAppear {
                    if backupScheduler == nil {
                        backupScheduler = BackupScheduler(favoritesStore: favoritesStore, settings: appSettings)
                    }
                }
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Connection…") {
                    NotificationCenter.default.post(name: .showAddFavorite, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("Quick Connect…") {
                    NotificationCenter.default.post(name: .showQuickConnect, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("Multi-Device Upload…") {
                    NotificationCenter.default.post(name: .showMultiDestination, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Divider()

                Button("Upload Files…") {
                    NotificationCenter.default.post(name: .triggerUpload, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
                .environment(appSettings)
        }

        MenuBarExtra("NetDrop", systemImage: "arrow.down.circle.fill") {
            MenuBarView()
                .environment(favoritesStore)
                .environment(transferManager)
        }
        .menuBarExtraStyle(.window)
    }
}

extension Notification.Name {
    static let showAddFavorite = Notification.Name("showAddFavorite")
    static let showQuickConnect = Notification.Name("showQuickConnect")
    static let showMultiDestination = Notification.Name("showMultiDestination")
    static let triggerUpload = Notification.Name("triggerUpload")
}

// Helper to pass optional environment objects
extension View {
    @ViewBuilder
    func optionalEnvironment<T: AnyObject & Observable>(_ object: T?) -> some View {
        if let object {
            self.environment(object)
        } else {
            self
        }
    }
}

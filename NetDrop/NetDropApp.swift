import SwiftUI

@main
struct NetDropApp: App {
    @State private var favoritesStore = FavoritesStore()
    @State private var transferManager = TransferManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(favoritesStore)
                .environment(transferManager)
        }
        .defaultSize(width: 900, height: 600)
    }
}

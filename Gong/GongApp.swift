import SwiftUI

@main
struct GongApp: App {
    @StateObject private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}

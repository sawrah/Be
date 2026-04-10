import SwiftUI
import SwiftData

@main
struct BeApp: SwiftUI.App {
    @StateObject private var authManager = AuthManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isSignedIn {
                    HomeView()
                } else {
                    SplashView()
                }
            }
            .environmentObject(authManager)
        }
        .modelContainer(sharedModelContainer)
    }
}

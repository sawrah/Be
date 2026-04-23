import SwiftUI
import SwiftData

@main
struct BeApp: SwiftUI.App {
    @StateObject private var authManager = AuthManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

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
                if authManager.hasFinishedSplash && authManager.isSignedIn {
                    HomeView()
                        .transition(.opacity)
                } else if authManager.showOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                } else {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: authManager.hasFinishedSplash)
            .animation(.easeInOut(duration: 0.5), value: authManager.isSignedIn)
            .animation(.easeInOut(duration: 0.5), value: authManager.showOnboarding)
            .environmentObject(authManager)
        }
        .modelContainer(sharedModelContainer)
    }
}

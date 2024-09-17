// MorepracticeApp.swift

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct MorepracticeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Initialize AppViewModel as a single StateObject
    @StateObject private var appViewModel = AppViewModel()

    @AppStorage("darkMode") private var darkMode: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject each ViewModel into the environment
                .environmentObject(appViewModel.authViewModel)
                .environmentObject(appViewModel.scoreManager)
                .environmentObject(appViewModel.imageManager)
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }

    // AppDelegate class for Firebase setup
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         didFinishLaunchingWithOptions launchOptions:
                         [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
            FirebaseApp.configure()
            print("Firebase configured successfully.")

            let providerFactory = AppCheckDebugProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)

            return true
        }
    }
}

import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import FirebaseMessaging
import FirebaseInAppMessaging
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseRemoteConfig
import FirebasePerformance

@main
struct MorepracticeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Initialize environment objects
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var linkingSettingsManager = LinkingSettingsManager()

    @AppStorage("darkMode") private var darkMode: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environmentObject(appViewModel.authViewModel)
                    .environmentObject(appViewModel.scoreManager)
                    .environmentObject(appViewModel.mediaManager)
                    // Uncomment if using: .environmentObject(appViewModel.autoChatManager)
                    .environmentObject(appViewModel)
                    .environmentObject(settingsManager)
                    .environmentObject(linkingSettingsManager)
                    .preferredColorScheme(darkMode ? .dark : .light)
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                        handleScenePhaseChange(from: oldPhase, to: newPhase)
                    }
            }
        }
    }

    // MARK: - Handle Scene Phase Changes
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("App is now active.")
            if appViewModel.authViewModel.isSignedIn {
                appViewModel.authViewModel.setUserOnline(true)
                appViewModel.authViewModel.startHeartbeat()
            }
        case .inactive:
            print("App is now inactive.")
        case .background:
            print("App is now in background.")
            if appViewModel.authViewModel.isSignedIn {
                appViewModel.authViewModel.setUserOnline(false)
                appViewModel.authViewModel.stopHeartbeat()
            }
        @unknown default:
            print("App is in an unknown state.")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        print("Firebase configured successfully.")

        // Set up App Check debug provider
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        return true
    }
}

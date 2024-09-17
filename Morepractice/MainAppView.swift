// MainAppView.swift

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var imageManager: ImageManager

    var body: some View {
        TabView {
            // Dashboard Tab
            NavigationStack {
                DashboardView()
                    // No need to inject environment objects again as they are already in the environment
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        let appVM = AppViewModel()

        MainAppView()
            .environmentObject(appVM.authViewModel)
            .environmentObject(appVM.scoreManager)
            .environmentObject(appVM.imageManager)
    }
}

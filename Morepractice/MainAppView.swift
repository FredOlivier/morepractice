//
//  MainAppView.swift
//  Morepractice
//
//  Created by Example on 01/11/2024.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        // Full-Screen Chat
        .fullScreenCover(item: $appViewModel.currentEphemeralChat) { ephemeralChatVM in
            EphemeralChatContainer(
                ephemeralChatVM: ephemeralChatVM
            ) {
                // Callback to end the ephemeral chat
                appViewModel.endEphemeralChat()
            }
        }
    }
}

// MARK: - Preview

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        let appVM = AppViewModel()
        MainAppView()
            .environmentObject(appVM)
    }
}

//
//  SettingsView.swift
//  Morepractice
//
//  Created by Fred Olivier on 04/10/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var imageManager: ImageManager

    // State for Dark Mode Toggle using @AppStorage for persistence
    @AppStorage("darkMode") private var darkMode: Bool = false

    var body: some View {
        NavigationStack { // Updated from NavigationView to NavigationStack
            Form {
                // Account Section
                Section(header: Text("Account")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(authViewModel.currentUserName ?? "Unknown")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authViewModel.userSession?.email ?? "Unknown")
                            .foregroundColor(.gray)
                    }
                    
                    // Sign Out Button
                    Button(action: {
                        signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Sign Out")
                    .accessibilityHint("Logs you out of the application")
                }
                
                // Preferences Section
                Section(header: Text("Preferences")) {
                    // Dark Mode Toggle
                    Toggle(isOn: $darkMode) {
                        Text("Dark Mode")
                    }
                    .accessibilityLabel("Dark Mode")
                    .accessibilityHint("Toggle to enable or disable dark mode")
                    
                    // Add more preference settings as needed
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(darkMode ? .dark : .light) // Apply color scheme based on toggle
        }
    }
    
    // MARK: - Functions
    
    /// Handles user sign out
    private func signOut() {
        authViewModel.signOut()
        // The app will automatically navigate to LoginView due to state change
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock AuthViewModel, ScoreManager, and ImageManager for previews
        let authVM = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let imgMgr = ImageManager(scoreManager: scoreMgr)
        
        SettingsView()
            .environmentObject(authVM)
            .environmentObject(scoreMgr)
            .environmentObject(imgMgr)
    }
}

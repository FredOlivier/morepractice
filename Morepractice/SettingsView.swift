//
//  SettingsView.swift
//  Morepractice
//
//  Created by Fred Olivier on 09/01/2025.
//

import SwiftUI

/// A settings view allowing users to manage their account and preferences.
/// Includes an onDismiss closure to handle sheet dismissal.
struct SettingsView: View {
    /// Closure to handle dismissal.
    var onDismiss: () -> Void

    // MARK: - Environment Objects
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var mediaManager: MediaManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var linkSettingsManager: LinkingSettingsManager

    // MARK: - Local States
    // We use @AppStorage for Dark Mode so it persists.
    @AppStorage("darkMode") private var darkMode: Bool = false
    
    // We store linking mode locally and sync it to/from appViewModel.linkingMode.
    @State private var localLinkingMode: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Account Section
                Section(header: Text("Account")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(authViewModel.currentUser?.username ?? "Unknown")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authViewModel.currentUser?.email ?? "Unknown")
                            .foregroundColor(.gray)
                    }
                    
                    // Sign Out Button
                    Button(role: .destructive) {
                        signOut()
                    } label: {
                        Text("Sign Out")
                    }
                    .accessibilityLabel("Sign Out")
                    .accessibilityHint("Logs you out of the application")
                }
                
                // MARK: - Preferences Section
                Section(header: Text("Preferences")) {
                    // Dark Mode Toggle
                    Toggle(isOn: $darkMode) {
                        Text("Dark Mode")
                    }
                    .accessibilityLabel("Dark Mode")
                    .accessibilityHint("Toggle to enable or disable dark mode")
                    Toggle("Animated Dashboard Borders", isOn: $settingsManager.animatedBordersEnabled)
                    // Haptic Feedback Toggle (note: using the correct property name)
                    Toggle("Haptic Feedback", isOn: $settingsManager.hapticFeedbackEnabled)
                        .accessibilityLabel("Haptic Feedback")
                        .accessibilityHint("Toggle to enable or disable haptic feedback")
                    
                    // Linking Mode: Two-button approach
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Linking Mode:")
                        
                        HStack(spacing: 20) {
                            // ON Button
                            Button {
                                localLinkingMode = true
                                appViewModel.linkingMode = true
                                print("Linking Mode is now ON")
                            } label: {
                                Text("ON")
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(localLinkingMode ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.borderless)
                            
                            // OFF Button
                            Button {
                                localLinkingMode = false
                                appViewModel.linkingMode = false
                                print("Linking Mode is now OFF")
                            } label: {
                                Text("OFF")
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(!localLinkingMode ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Close button in the navigation bar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                    .accessibilityLabel("Close Settings")
                    .accessibilityHint("Dismiss the settings view")
                }
            }
            .preferredColorScheme(darkMode ? .dark : .light)
            .onAppear {
                // Sync the local linking mode state with the AppViewModel.
                localLinkingMode = appViewModel.linkingMode
            }
        }
    }
    
    // MARK: - Functions
    private func signOut() {
        authViewModel.signOut()
        // The app will automatically navigate to SignInView on sign-out.
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let medMgr = MediaManager(scoreManager: scoreMgr)
        let settingsMgr = SettingsManager()
        let soundMgr = SoundManager.shared
        let appVM = AppViewModel()
        let linkM = LinkingSettingsManager() // << CREATE INSTANCE

        SettingsView(onDismiss: {})
            .environmentObject(authVM)
            .environmentObject(scoreMgr)
            .environmentObject(medMgr)
            .environmentObject(settingsMgr)
            .environmentObject(soundMgr)
            .environmentObject(appVM)
            .environmentObject(linkM)
    }
}

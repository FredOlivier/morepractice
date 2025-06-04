import Foundation
import SwiftUI

struct ModesView: View {
    // ModesView receives the manager from its parent (CircularDashboard's NavLink)
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager
    // Add any other EnvironmentObjects needed

    var body: some View {
        List {
            // --- MODIFY THIS NAVIGATION LINK ---
            NavigationLink("Linking Settings") {
                // Explicitly pass the received manager down to the destination
                LinkingSettingsView()
                    .environmentObject(linkingSettingsManager) // << ADD THIS EXPLICIT INJECTION
            }
            // --- END MODIFICATION ---

            NavigationLink("Media Settings") {
                // MediaSettingsView will inherit (or pass explicitly if needed)
                MediaSettingsView()
                 // If MediaSettingsView also needs it, add:
                 // .environmentObject(linkingSettingsManager)
            }
        }
        .navigationTitle("Modes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MediaSettingsView remains the same
struct MediaSettingsView: View {
    var body: some View {
        Text("Media settings coming soon!")
            .font(.title)
            .navigationTitle("Media Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// Preview remains the same - it was already correct
struct ModesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ModesView()
                .environmentObject(LinkingSettingsManager())
        }
    }
}


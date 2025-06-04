import SwiftUI

/// The primary dashboard showing five circular buttons arranged in a circular layout
/// plus a small settings button in the bottom-right corner.
struct CircleDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager
    /// Toggles the presentation of the SettingsView
    @State private var inSettings: Bool = false

    /// Toggles the presentation of the mediainteractionViewWrapper
    @State private var showExplore: Bool = false

    var body: some View {
        ZStack {
            // 1) Background color
            backgroundColor
                .ignoresSafeArea()

            // 2) Circular Dashboard
            CircularDashboard()
                .ignoresSafeArea()
                // Remove fixed frame and position to allow CircularDashboard to manage its own layout

            // 3) Settings Circle in bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    settingsCircle
                }
                .padding(.bottom, 40)
                .padding(.trailing, 30)
            }
        }
        // Present the SettingsView as a sheet
        .sheet(isPresented: $inSettings) {
            SettingsView(onDismiss: { inSettings = false })
        }
        // Present the Explore view as a full screen cover
        .fullScreenCover(isPresented: $showExplore) {
            MediaInteractionViewWrapper()
        }
    }

    // MARK: - Background

    private var backgroundColor: some View {
        Color(UIColor.systemBackground)
    }

    // MARK: - Settings Circle

    /// The small circle toggling between gear and X; tapping shows the Settings sheet
    private var settingsCircle: some View {
        let diameter: CGFloat = 50
        return Button(action: {
            inSettings.toggle()
        }) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: diameter, height: diameter)

                Image(systemName: inSettings ? "xmark" : "gearshape.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }
        }
        .accessibilityLabel("Settings Button")
        .accessibilityHint("Tap to open settings")
    }

    // Inside CircleDashboardView_Previews
    struct CircleDashboardView_Previews: PreviewProvider {
        static var previews: some View {
            let appVM = AppViewModel()
            let settingsMgr = SettingsManager() // Create instance
            let linkingMgr = LinkingSettingsManager() // Create instance

            CircleDashboardView()
                .environmentObject(appVM.authViewModel)
                .environmentObject(appVM.scoreManager)
                .environmentObject(appVM.mediaManager)
                // .environmentObject(appVM.autoChatManager)
                .environmentObject(appVM)
                .environmentObject(settingsMgr) // Pass instance
                .environmentObject(linkingMgr) // Pass instance << CORRECTED
        }
    }
}

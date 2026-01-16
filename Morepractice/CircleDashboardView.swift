import SwiftUI

/// The primary dashboard showing five circular buttons arranged in a circular layout
/// plus a small settings button in the bottom-right corner.
struct CircleDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager
    @EnvironmentObject var authViewModel: AuthViewModel      // ← ADD

    /// Toggles the presentation of the SettingsView
    @State private var inSettings: Bool = false

    /// Toggles the presentation of the mediainteractionViewWrapper
    @State private var showExplore: Bool = false

    // ← ADD: greeting state
    @State private var greetingText: String = ""
    @State private var showGreeting: Bool = false
    @State private var greetingID = UUID() // forces view refresh/transition

    var body: some View {
        ZStack {
            // 1) Background color
            backgroundColor
                .ignoresSafeArea()

            // 2) Circular Dashboard
            CircularDashboard()
                .ignoresSafeArea()

            // 2.5) ← Greeting overlay (non-blocking)
            if showGreeting {
                GreetingBadge(text: greetingText)
                    .id(greetingID) // in case we re-show quickly
                    .transition(.opacity)
                    .padding(.top, 40)
                    .allowsHitTesting(false)
                    .zIndex(10)
                    .accessibilityHidden(true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

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
        .onAppear {
            showNewGreeting()        // ← ADD
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

// MARK: - Greeting logic
private extension CircleDashboardView {
    func showNewGreeting() {
        // Build a friendly display name
        let first = authViewModel.currentUser?.firstName ?? ""
        let last  = authViewModel.currentUser?.lastName ?? ""
        let username = authViewModel.currentUser?.username ?? ""
        let display = [first, last].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = display.isEmpty ? username : display

        greetingText = randomHello() + (name.isEmpty ? "!" : ", \(name)!")

        withAnimation(.easeInOut(duration: 0.35)) {
            greetingID = UUID()
            showGreeting = true
        }

        // Auto-fade after 7 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            withAnimation(.easeInOut(duration: 0.6)) {
                showGreeting = false
            }
        }
    }

    func randomHello() -> String {
        // 15 major languages + a couple of scripts; all short and friendly
        let hellos = [
            "Hello",        // English
            "Hola",         // Spanish
            "Bonjour",      // French
            "Hallo",        // German
            "Ciao",         // Italian
            "Olá",          // Portuguese
            "Привет",       // Russian
            "こんにちは",     // Japanese
            "你好",           // Chinese (Mandarin)
            "안녕하세요",       // Korean
            "مرحباً",        // Arabic
            "नमस्ते",        // Hindi
            "สวัสดี",        // Thai
            "Merhaba",      // Turkish
            "Hej"           // Swedish (Nordic stand-in)
        ]
        return hellos.randomElement() ?? "Hello"
    }
}

// MARK: - Greeting badge view
private struct GreetingBadge: View {
    let text: String
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Text(text)
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(
                .ultraThinMaterial, in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(scheme == .dark ? 0.18 : 0.12), lineWidth: 1)
            )
            .shadow(radius: 8, y: 6)
            .opacity(0.98)
    }
}

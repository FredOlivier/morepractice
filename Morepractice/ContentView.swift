import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager

    var body: some View {
        NavigationStack {
            if !authViewModel.isSignedIn {
                SignInView()
            } else {
                CircleDashboardView()
                    // MARK: — Live video chat
                    .fullScreenCover(isPresented: Binding<Bool>(
                        get: { appViewModel.isChatChannelOpen },
                        set: { appViewModel.isChatChannelOpen = $0 }
                    )) {
                        VideoChatView()
                            .environmentObject(appViewModel)
                            .environmentObject(linkingSettingsManager)
                    }
                    // MARK: — Post-call rating
                    .fullScreenCover(isPresented: Binding<Bool>(
                        get: { appViewModel.showRatingView },
                        set: { appViewModel.showRatingView = $0 }
                    )) {
                        let actualSnapshot = appViewModel.ratingSnapshot
                                                                    ?? UIImage(systemName: "photo") // Try placeholder first
                                                                    ?? UIImage() // Final fallback to empty image

                        LinkRatingView(
                                                    otherUser:       appViewModel.linkOtherUser    ?? "",
                                                    snapshot:        appViewModel.ratingSnapshot   ?? UIImage(),
                                                    sessionId:       appViewModel.lastSessionId    ?? "",
                                                    callLength:      appViewModel.linkLength,
                                                    startSimilarity: linkingSettingsManager.currentSimilarity,
                                                    extendedBy:      TimeInterval(linkingSettingsManager.totalExtendedSeconds)
                                                )
                                                .environmentObject(appViewModel)
                                                .environmentObject(linkingSettingsManager)
                                                // --- END CHANGE ---
                                            }
                                    }
                                }
                            }
                        }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let appVM       = AppViewModel()
        let authVM      = appVM.authViewModel
        let scoreMgr    = appVM.scoreManager
        let mediaMgr    = appVM.mediaManager
        let settingsMgr = SettingsManager()
        let linkMgr     = LinkingSettingsManager()

        ContentView()
            .environmentObject(authVM)
            .environmentObject(scoreMgr)
            .environmentObject(mediaMgr)
            .environmentObject(appVM)
            .environmentObject(settingsMgr)
            .environmentObject(linkMgr)
    }
}

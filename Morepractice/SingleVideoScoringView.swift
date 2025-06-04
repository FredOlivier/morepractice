//  SingleVideoScoringView.swift
//  Morepractice
//
//  • Title text removed (blank)
//  • Video fills entire screen (scaledToFill + ignoresSafeArea)
//  • Video loops continuously – even while sliders are shown

import SwiftUI
import AVKit

struct SingleVideoScoringView: View {
    // MARK: - Media
    let mediaItem: MediaItem

    // MARK: - Environment
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var mediaManager: MediaManager
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager
    @EnvironmentObject var soundManager: SoundManager     // for haptics / sounds

    // MARK: - State
    @State private var sliderValue: Double = 0.5
    @State private var showSliders = false
    @State private var player: AVPlayer? = nil
    @State private var navigateToMediaInteraction = false

    // ===========================================================
    // MARK: - Body
    // ===========================================================
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .scaledToFill()
                    .ignoresSafeArea()
                    .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
                        // Loop + reveal sliders
                        player.seek(to: .zero)
                        player.play()
                        showSliders = true
                    }
            }

            if showSliders {
                sliderAndButtonsOverlay
            }
        }
        .onAppear { setupVideo() }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .navigationTitle("")                          // <- blank title
        .toolbar { toolbarUI }
        .navigationDestination(isPresented: $navigateToMediaInteraction) {
            MediaInteractionView()
                .environmentObject(authViewModel)
                .environmentObject(scoreManager)
                .environmentObject(mediaManager)
                .environmentObject(appViewModel)
                .environmentObject(settingsManager)
                .environmentObject(linkingSettingsManager)
        }
        .onAppear { makeNavigationBarTransparent() }
    }

    // MARK: - Video
    private func setupVideo() {
        guard let url = URL(string: mediaItem.url) else { return }
        player = AVPlayer(url: url)
    }

    // MARK: - Slider + Buttons
    private var sliderAndButtonsOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 40) {
                SliderView(sliderValue: $sliderValue,
                           startColor: .purple,
                           endColor: .orange)
                    .frame(width: 40, height: 250)

                VStack(spacing: 15) {
                    Button {
                        // Replay (reset slider overlay state)
                        showSliders = false
                        player?.seek(to: .zero)
                        player?.play()
                    } label: {
                        label("gobackward", "Replay")
                    }

                    Button {
                        if settingsManager.hapticOnNextButton {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        submitAndNavigate()
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Next Video")
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers
    private func label(_ system: String, _ text: String) -> some View {
        HStack {
            Image(systemName: system)
            Text(text)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .foregroundColor(.white)
        .cornerRadius(8)
    }

    private func submitAndNavigate() {
        scoreManager.addSingleVideoScore(
            sliderValue: sliderValue * 100,
            mediaItem: mediaItem
        )
        sliderValue = 0.5
        navigateToMediaInteraction = true
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarUI: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            NavigationLink {
                CircleDashboardView()
                    .environmentObject(authViewModel)
                    .environmentObject(scoreManager)
                    .environmentObject(mediaManager)
                    .environmentObject(appViewModel)
                    .environmentObject(settingsManager)
                    .environmentObject(linkingSettingsManager)
            } label: {
                Image(systemName: "house.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: MyHeartView(scoreManager: scoreManager)) {
                Text("MyHeart").foregroundColor(.pink)
            }
        }
    }

    private func makeNavigationBarTransparent() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.clear] // no text colour
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.clear]
        UINavigationBar.appearance().standardAppearance  = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - SliderView (unchanged)
struct SliderView: View {
    @Binding var sliderValue: Double
    let startColor: Color
    let endColor: Color
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        VerticalSlider(
            value: $sliderValue,
            thumbColor: sliderColor(sliderValue, startColor, endColor),
            trackColor: .gray,
            thumbOpacity: 0.5
        )
        .frame(width: 40, height: UIScreen.main.bounds.height * 0.8)
        .opacity(0.7)
        .onChange(of: sliderValue) { _ in
            if settingsManager.hapticFeedbackEnabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    private func sliderColor(_ v: Double, _ s: Color, _ e: Color) -> Color {
        let sc = UIColor(s).cgColor.components ?? [0,0,0,1]
        let ec = UIColor(e).cgColor.components ?? [0,0,0,1]
        let r = (1-v)*sc[0] + v*ec[0]
        let g = (1-v)*sc[1] + v*ec[1]
        let b = (1-v)*sc[2] + v*ec[2]
        let a = (1-v)*sc[3] + v*ec[3]
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Preview
struct SingleVideoScoringView_Previews: PreviewProvider {
    static var previews: some View {
        let m = MediaItem(id: "vid",
                          mediaKind: .video,
                          category: nil,
                          url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                          uploaderUid: "whowh",
                          uploadDocPath: "sffs")
        let authVM   = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let mediaMgr = MediaManager(scoreManager: scoreMgr)
        let appVM    = AppViewModel()
        let settings = SettingsManager()
        let linkMgr  = LinkingSettingsManager()
        let soundMgr = SoundManager.shared

        NavigationStack {
            SingleVideoScoringView(mediaItem: m)
                .environmentObject(authVM)
                .environmentObject(scoreMgr)
                .environmentObject(mediaMgr)
                .environmentObject(appVM)
                .environmentObject(settings)
                .environmentObject(linkMgr)
                .environmentObject(soundMgr)
        }
    }
}

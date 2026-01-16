//  PairScoringView.swift
//  Morepractice
//
//  Smaller toolbar items; custom back only in normal state;
//  hide toolbars during initial maximise and while enlarged.

import SwiftUI
import FirebaseFirestore

struct PairScoringView: View {
    // MARK: - Media Items
    let media1: MediaItem
    let media2: MediaItem

    // MARK: - Environment Objects
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var mediaManager: MediaManager
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager

    // MARK: - Slider State
    @State private var sliderValue1: Double = 0.5
    @State private var sliderValue2: Double = 0.5
    @State private var slider1StartColor: Color = .red
    @State private var slider1EndColor:   Color = .blue
    @State private var slider2StartColor: Color = .green
    @State private var slider2EndColor:   Color = .yellow

    // MARK: - Tutorial / Enlargement State
    @State private var isInitialSequenceActive: Bool = true
    @State private var userTriggeredEnlarge1:  Bool = false
    @State private var userTriggeredEnlarge2:  Bool = false

    private enum EnlargedSide { case none, left, right }
    @State private var enlargedSide: EnlargedSide = .none

    // MARK: - Skip / Navigation / Favourites
    @State private var userInteractedWithSliders: Bool = false
    @State private var skipTapCount: Int = 0
    @State private var navigateToMediaInteraction: Bool = false
    @State private var showAddFavouritesSheet: Bool = false

    // ===============================================================
    // MARK: - Body
    // ===============================================================
    var body: some View {
        ZStack {
            normalLayoutView().zIndex(1)

            if isInitialSequenceActive {
                initialSequenceOverlay().zIndex(2)
            }

            if enlargedSide != .none {
                fullscreenImage(media: enlargedSide == .left ? media1 : media2) {
                    withAnimation { enlargedSide = .none }
                }
                .zIndex(4)
                .transition(.opacity)
            }

            // ♥︎+ button (hidden during enlarge)
            if enlargedSide == .none {
                favouritesButton
                    .zIndex(5)
            }
        }
        .sheet(isPresented: $showAddFavouritesSheet) {
            AddFavouritesView(mediaItems: [media1, media2])
                .environmentObject(authViewModel)
        }
        .navigationDestination(isPresented: $navigateToMediaInteraction) {
            MediaInteractionView()
                .environmentObject(authViewModel)
                .environmentObject(scoreManager)
                .environmentObject(mediaManager)
                .environmentObject(appViewModel)
                .environmentObject(settingsManager)
                .environmentObject(linkingSettingsManager)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)     // hide system back
        .toolbar {
            if toolbarShouldBeVisible {
                toolbarItems
            }
        }
        .onAppear {
            runInitialSequence()
            makeNavigationBarTransparent()
        }
    }

    private var toolbarShouldBeVisible: Bool {
        enlargedSide == .none && !isInitialSequenceActive
    }

    // =========================================================
    // MARK: Layout & sub‑views
    // =========================================================
    private func normalLayoutView() -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Images (side‑by‑side)
                HStack(spacing: 0) {
                    sideMediaView(media: media1, isLeft: true, width: w/2, height: h)
                    sideMediaView(media: media2, isLeft: false, width: w/2, height: h)
                }

                slidersOverlay(width: w, height: h)
                enlargeButtonsOverlay().zIndex(3)
                skipNextControl(containerWidth: w, containerHeight: h)
            }
            .frame(width: w, height: h)
            .background(Color.black)
        }
    }

    private func sideMediaView(media: MediaItem, isLeft: Bool, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            AsyncImage(url: URL(string: media.url)) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(.white)
                        .frame(width: width, height: height)
                        .background(Color.black)
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                case .failure:
                    Color.red.overlay(Text("Failed").foregroundColor(.white))
                        .frame(width: width, height: height)
                @unknown default:
                    EmptyView()
                }
            }

            // Tap anywhere to enlarge
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { showFullscreen(for: isLeft ? .left : .right) }
        }
        .frame(width: width, height: height)
    }

    private func enlargeButtonsOverlay() -> some View {
        HStack {
            enlargeButton { showFullscreen(for: .left) }
            Spacer()
            enlargeButton { showFullscreen(for: .right) }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func enlargeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .padding(6)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
        .accessibilityLabel("Enlarge")
    }

    // --- ♥︎+ favourites button (bottom‑left) ---
    private var favouritesButton: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    showAddFavouritesSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.pink)
                            .frame(width: 36, height: 36)
                            .opacity(0.6)
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 10))
                            .offset(x: 9, y: -9)
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                            .offset(x: -9, y: -9)
                    }
                }
                .accessibilityLabel("Add to favourites")
                .padding(.leading, 20)

                Spacer()
            }
            .padding(.bottom, 28)
        }
    }

    private func slidersOverlay(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 0) {
            PairSliderView(value: $sliderValue1,
                           startColor: slider1StartColor,
                           endColor: slider1EndColor)
                .onChange(of: sliderValue1) { _ in userInteracted() }
                .frame(width: width / 2, height: height)

            PairSliderView(value: $sliderValue2,
                           startColor: slider2StartColor,
                           endColor: slider2EndColor)
                .onChange(of: sliderValue2) { _ in userInteracted() }
                .frame(width: width / 2, height: height)
        }
    }

    private func skipNextControl(containerWidth w: CGFloat, containerHeight h: CGFloat) -> some View {
        let size: CGFloat = 64
        let midX = w / 2
        let midY = h / 2

        return Group {
            if userInteractedWithSliders {
                Button { submitScoreAndAdvance() } label: {
                    Circle().fill(Color.blue)
                        .frame(width: size, height: size)
                        .shadow(radius: 10)
                        .overlay(Text("+")
                            .font(.title)
                            .foregroundColor(.white))
                }
                .position(x: midX, y: midY)
            } else {
                if skipTapCount == 0 {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: size, height: size)
                        .position(x: midX, y: midY)
                        .onTapGesture { skipTapCount = 1 }
                } else {
                    Button { submitSkipAndAdvance() } label: {
                        Circle().fill(Color.blue)
                            .frame(width: size, height: size)
                            .overlay(Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(.white))
                    }
                    .position(x: midX, y: midY)
                }
            }
        }
    }

    // Toolbar
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 10) {
                // Custom back (small), only in normal state
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(6)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }

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
                        .font(.system(size: 14, weight: .medium))
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: MyHeartView(scoreManager: scoreManager)) {
                Text("MyHeart")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pink)
            }
        }
    }
}

// =========================================================
// MARK: Actions & helpers
// =========================================================
extension PairScoringView {
    private func userInteracted() { userInteractedWithSliders = true }

    private func submitScoreAndAdvance() {
        let diff = abs(sliderValue1 - sliderValue2)
        scoreManager.addScore(
            slider1: sliderValue1 * 100,
            slider2: sliderValue2 * 100,
            image1: media1.id,
            image2: media2.id,
            image1URL: media1.url,
            image2URL: media2.url,
            relationalScore: diff
        )
        resetAndNavigate()
    }

    private func submitSkipAndAdvance() {
        scoreManager.addSkipScore(
            image1: media1.id,
            image2: media2.id,
            image1URL: media1.url,
            image2URL: media2.url
        )
        resetAndNavigate()
    }

    private func resetAndNavigate() {
        sliderValue1 = 0.5 ; sliderValue2 = 0.5
        userInteractedWithSliders = false ; skipTapCount = 0
        slider1StartColor = randomColor() ; slider1EndColor = randomColor()
        slider2StartColor = randomColor() ; slider2EndColor = randomColor()
        navigateToMediaInteraction = true
    }

    // Show overlay & auto‑dismiss
    private func showFullscreen(for side: EnlargedSide) {
        if side == .left { userTriggeredEnlarge1 = true } else { userTriggeredEnlarge2 = true }
        withAnimation { enlargedSide = side }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { enlargedSide = .none }
        }
    }

    private func initialSequenceOverlay() -> some View {
        Color.clear.onAppear { runInitialSequence() }
    }

    private func runInitialSequence() {
        DispatchQueue.main.async {
            withAnimation { enlargedSide = .left }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if !userTriggeredEnlarge1 { withAnimation { enlargedSide = .right } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if !userTriggeredEnlarge2 { withAnimation { enlargedSide = .none } }
            withAnimation { isInitialSequenceActive = false }
        }
    }

    private func fullscreenImage(media: MediaItem, onTap: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AsyncImage(url: URL(string: media.url)) { phase in
                switch phase {
                case .empty:   ProgressView().tint(.white)
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .onTapGesture { onTap() }
                case .failure:
                    Color.red.overlay(Text("Failed").foregroundColor(.white))
                        .onTapGesture { onTap() }
                @unknown default: EmptyView()
                }
            }
        }
    }

    private func makeNavigationBarTransparent() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes  = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance  = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private func randomColor() -> Color {
        Color(red: .random(in: 0...1),
              green: .random(in: 0...1),
              blue: .random(in: 0...1))
    }
}

// =========================================================
// MARK: Slider sub‑view (unchanged except size)
// =========================================================
private struct PairSliderView: View {
    @Binding var value: Double
    let startColor: Color
    let endColor:   Color
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        VerticalSlider(
            value: $value,
            thumbColor: sliderColor(),
            trackColor: .gray,
            thumbOpacity: 0.5
        )
        .frame(width: 40, height: UIScreen.main.bounds.height * 0.8)
        .opacity(0.7)
        .onChange(of: value) { _ in
            if settingsManager.hapticFeedbackEnabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    private func sliderColor() -> Color {
        let sc = UIColor(startColor).cgColor.components ?? [0,0,0,1]
        let ec = UIColor(endColor).cgColor.components   ?? [0,0,0,1]
        let r = (1-value)*sc[0] + value*ec[0]
        let g = (1-value)*sc[1] + value*ec[1]
        let b = (1-value)*sc[2] + value*ec[2]
        let a = (1-value)*sc[3] + value*ec[3]
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

// =========================================================
// MARK: Preview (unchanged)
// =========================================================
struct PairScoringView_Previews: PreviewProvider {
    static func appViewModelForPreviews() -> AppViewModel {
        let vm = AppViewModel(); vm.linkingMode = false; return vm
    }

    static var previews: some View {
        let mediaA = MediaItem(id: "A", mediaKind: .image,
                               category: "culture",
                               url: "https://placekitten.com/800/600",
                               uploaderUid: "whowh",
                               uploadDocPath: "sffs")
        let mediaB = MediaItem(id: "B", mediaKind: .image,
                               category: "culture",
                               url: "https://placekitten.com/801/600",
                               uploaderUid: "whowh",
                               uploadDocPath: "sffs")

        let authVM    = AuthViewModel()
        let scoreMgr  = ScoreManager(authViewModel: authVM)
        let mediaMgr  = MediaManager(scoreManager: scoreMgr)
        let appVM     = appViewModelForPreviews()
        let settings  = SettingsManager()
        let linkMgr   = LinkingSettingsManager()

        NavigationStack {
            PairScoringView(media1: mediaA, media2: mediaB)
                .environmentObject(authVM)
                .environmentObject(scoreMgr)
                .environmentObject(mediaMgr)
                .environmentObject(appVM)
                .environmentObject(settings)
                .environmentObject(linkMgr)
        }
    }
}

//
//  SingleImageScoringView.swift
//  Morepractice
//
//  Created by Fred Olivier on 10/01/2025.
//

import SwiftUI

struct SingleImageScoringView: View {
    // MARK: - Media Data
    let mediaItem: MediaItem

    // MARK: - Environment Objects
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var mediaManager: MediaManager

    // MARK: - State Variables
    @State private var sliderValue: Double = 0.5
    @State private var isMaximized: Bool = false
    @State private var navigateToMediaInteraction: Bool = false

    var body: some View {
        ZStack {
            if isMaximized {
                // Full-Screen Layout with vertical slider
                fullScreenLayout()
            } else {
                // Normal Layout with enlarge button
                normalLayout()
            }

            // Hidden NavigationLink to MediaInteractionView
            NavigationLink(
                destination: MediaInteractionView()
                    .environmentObject(scoreManager)
               //    .environmentObject(settingsManager)
               //     .environmentObject(soundManager)
                    .environmentObject(mediaManager),
                isActive: $navigateToMediaInteraction
            ) {
                EmptyView()
            }
        }
        .ignoresSafeArea() // Let the image fill edges if full-screen
        .navigationTitle("Single Image Scoring")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: MyHeartView(scoreManager: scoreManager)) {
                    Text("MyHeart")
                        .foregroundColor(.pink)
                }
                .accessibilityLabel("Navigate to MyHeart View")
                .accessibilityHint("Shows your top scores")
            }
        }
    }

    // MARK: - Normal Layout

    private func normalLayout() -> some View {
        VStack(spacing: 20) {
            // Show a smaller version of the image
            AsyncImage(url: URL(string: mediaItem.url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                case .failure(_):
                    Color.red
                        .frame(width: 300, height: 300)
                        .overlay(Text("Failed to load image").foregroundColor(.white))
                case .empty:
                    ProgressView()
                        .frame(width: 300, height: 300)
                @unknown default:
                    ProgressView()
                }
            }

            // Enlarge Button
            Button {
                withAnimation {
                    isMaximized = true
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.title2)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Enlarge Image")
            .accessibilityHint("Maximize the image to full screen")

            Spacer(minLength: 50)
        }
        .padding()
    }

    // MARK: - Full-Screen Layout

    private func fullScreenLayout() -> some View {
        ZStack {
            // Full-screen image
            AsyncImage(url: URL(string: mediaItem.url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                case .failure(_):
                    Color.red
                        .overlay(Text("Failed to load image").foregroundColor(.white))
                case .empty:
                    ProgressView()
                @unknown default:
                    ProgressView()
                }
            }

            // Vertical Slider overlay + "Next" button
            VStack {
                Spacer()

                HStack(spacing: 40) {
                    // Vertical Slider
                    SliderView(
                        sliderValue: $sliderValue,
                        startColor: .purple,
                        endColor: .orange
                    )
                    .frame(width: 40, height: 250)

                    VStack(spacing: 15) {
                        // "Close" or "Minimize" button
                        Button {
                            withAnimation {
                                isMaximized = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Close Full Screen")

                        // "Next" button
                        Button {
                            submitScoreAndNavigate()
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("Next Image")
                    }
                }
                .padding()
                Spacer()
            }
        }
    }

    // MARK: - Submit Score and Navigate

    private func submitScoreAndNavigate() {
        let numericScore = sliderValue * 100
        let relationalScore = 0.0 // Adjust if needed

        // Save single image score
        scoreManager.addSingleImageScore(
            sliderValue: numericScore,
            mediaItem: mediaItem
        )

        // Reset slider
        sliderValue = 0.5

        // Generate new random colors for sliders if applicable
        // sliderStartColor = randomColor()
        // sliderEndColor = randomColor()

        // Optional haptic feedback
        // if settingsManager.hapticFeedbackEnabled {
        //     let generator = UIImpactFeedbackGenerator(style: .medium)
        //     generator.prepare()
        //     generator.impactOccurred(intensity: CGFloat(Float(settingsManager.hapticStrength)))
        // }

        // Navigate to MediaInteractionView
        navigateToMediaInteraction = true
    }

    // MARK: - Helper Function

    private func randomColor() -> Color {
        Color(
            red:   Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue:  Double.random(in: 0...1)
        )
    }
}



// MARK: - Preview

struct SingleImageScoringView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMedia = MediaItem(id: "mediaC", mediaKind: .image, category: "culture", url: "https://placekitten.com/802/602",
                                    uploaderUid: "whowh",
                                    uploadDocPath: "sffs")

        return NavigationView {
            SingleImageScoringView(mediaItem: sampleMedia)
                .environmentObject(ScoreManager(authViewModel: AuthViewModel()))
             //   .environmentObject(SettingsManager())
            //    .environmentObject(SoundManager.shared)
                .environmentObject(MediaManager(scoreManager: ScoreManager(authViewModel: AuthViewModel())))
        }
    }
}

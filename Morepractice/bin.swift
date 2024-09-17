// MARK: - Normal Layout

private func normalLayout() -> some View {
    HStack(spacing: 0) {
        // Left Image with Enlarge Button
        if let photo1 = currentPhoto1 {
            ZStack {
                // Background Image
                AsyncImage(url: URL(string: photo1.url)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height) // Flexible height
                            .ignoresSafeArea()
                            .clipped()
                            .allowsHitTesting(false)  // Prevent image from intercepting touches
                    } else if phase.error != nil {
                        // Error placeholder
                        Color.red
                            .frame(width: UIScreen.main.bounds.width / 2, height: .infinity)
                    } else {
                        // Placeholder while loading
                        ProgressView()
                            .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height)
                            .background(Color.gray.opacity(0.1))
                    }
                }

             
                // Enlarge Button
                Button(action: {
                    self.viewState = .enlargingImage1
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .position(x: 30, y: UIScreen.main.bounds.height / 2)
            }
        }

        // Right Image with Enlarge Button
        if let photo2 = currentPhoto2 {
            ZStack {
                // Background Image
                AsyncImage(url: URL(string: photo2.url)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height) // Flexible height
                            .ignoresSafeArea()
                            .clipped()
                            .allowsHitTesting(false)
                    } else if phase.error != nil {
                        // Error placeholder
                        Color.red
                            .frame(width: UIScreen.main.bounds.width / 2, height: .infinity)
                    } else {
                        // Placeholder while loading
                        ProgressView()
                            .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height)
                            .background(Color.gray.opacity(0.1))
                    }
                }

                // Enlarge Button
                                    Button(action: {
                                        self.viewState = .enlargingImage2
                                    }) {
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .position(x: (UIScreen.main.bounds.width / 2) - 30, y: UIScreen.main.bounds.height / 2)
                                }
                            }
                        }

    .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure HStack fills the screen
    .overlay(
        VStack {
            Spacer()
            HStack(spacing: 0) {
                // First Slider
                SliderView(
                    sliderValue: $sliderValue1,
                    startColor: slider1StartColor,
                    endColor: slider1EndColor
                )
                .frame(width: UIScreen.main.bounds.width / 2)

                // Second Slider
                SliderView(
                    sliderValue: $sliderValue2,
                    startColor: slider2StartColor,
                    endColor: slider2EndColor
                )
                .frame(width: UIScreen.main.bounds.width / 2)
            }
            .padding()
            Spacer()
        }
    )
    // Removed .ignoresSafeArea() to respect safe areas and avoid white bars
}

-----
@main
struct MorepracticeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isSignedIn {
                MainAppView()
                    .environmentObject(authViewModel)
            } else {
                SignInView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

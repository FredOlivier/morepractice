import SwiftUI

struct UploadOptionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager
    @Environment(\.dismiss) var dismiss
    
    // Set the default mode; change as needed.
    @State private var selectedMode: MediaUploadMode = .imageSingle

    var body: some View {
        NavigationStack {
            ZStack {
                // Geometric art background
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue, .pink, .orange].shuffled()),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: geometry.size.width * 0.8,
                                   height: geometry.size.width * 0.8)
                            .rotationEffect(.degrees(45))
                    )
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 40) {
                    Text("Upload Media")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Upload Pair button—for images; similar one for video if needed.
                        NavigationLink(
                            destination: UploadDetailView(uploadType: .imagePair)
                                .environmentObject(authViewModel)
                                .environmentObject(settingsManager)
                                .environmentObject(appViewModel)
                        ) {
                            UploadButtonView(title: "Upload Pair", iconName: "square.split.2x1.fill")
                        }
                        
                        // Upload Single button—for images.
                        NavigationLink(
                            destination: UploadDetailView(uploadType: .imageSingle)
                                .environmentObject(authViewModel)
                                .environmentObject(settingsManager)
                                .environmentObject(appViewModel)
                        ) {
                            UploadButtonView(title: "Upload Single", iconName: "photo.fill")
                        }
                    }
                    
                    Spacer()
                    
                    // Cancel button to return to the CircleDashboardView.
                    Button("Cancel") {
                        // Replace the root view to navigate back to the dashboard.
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = UIHostingController(rootView: CircleDashboardView()
                                .environmentObject(authViewModel)
                                .environmentObject(appViewModel.scoreManager)
                                .environmentObject(appViewModel.mediaManager)
                                .environmentObject(appViewModel)
                                .environmentObject(settingsManager)
                                .environmentObject(linkingSettingsManager)
                            )
                            window.makeKeyAndVisible()
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                .padding()
            }
        }
    }
}

struct UploadOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        UploadOptionsView()
            .environmentObject(AuthViewModel())
            .environmentObject(SettingsManager())
            .environmentObject(AppViewModel())
    }
}

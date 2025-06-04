/*import SwiftUI

struct UploadMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager
    @State private var selectedUploadType: MediaType? = nil   // When non-nil, navigate to detail view
    
    // The geometric art background can reuse our CircularDashboard random gradients for example:
    var body: some View {
        NavigationStack {
            ZStack {
                // Geometric art background
                GeometricArtBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Upload Your Media")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Two Buttons: Upload Pair and Upload Single
                    HStack(spacing: 20) {
                        NavigationLink(
                            destination: UploadDetailView(uploadType: .imagePair),  // For images by default; can be toggled inside UploadDetailView
                            tag: MediaType.pairImageUpload,
                            selection: $selectedUploadType
                        ) {
                            UploadButtonView(title: "Upload Pair", iconName: "square.stack.2x2.fill")
                        }
                        
                        NavigationLink(
                            destination: UploadDetailView(uploadType: .imageSingle), // For images; you might switch this to video
                            tag: MediaType.singleImage,
                            selection: $selectedUploadType
                        ) {
                            UploadButtonView(title: "Upload Single", iconName: "photo.fill")
                        }
                    }
                    
                    // Optionally add toggles or segmented control to let the user switch between image and video mode.
                    // For example, you could have another HStack with buttons for "Image" and "Video",
                    // and then adjust the destination of the NavigationLinks accordingly.
                }
            }
            .navigationTitle("Modes")
        }
    }
}

struct GeometricArtBackground: View {
    // A sample geometric art background using random pastel gradients
    let gradients = [
        LinearGradient(
            gradient: Gradient(colors: [Color.randomPastel(), Color.randomPastel()]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing),
        LinearGradient(
            gradient: Gradient(colors: [Color.randomPastel(), Color.randomPastel()]),
            startPoint: .bottomLeading,
            endPoint: .topTrailing)
    ]
    
    var body: some View {
        ZStack {
            ForEach(gradients.indices, id: \.self) { i in
                Circle()
                    .fill(gradients[i])
                    .frame(width: 300 + CGFloat(i * 50),
                           height: 300 + CGFloat(i * 50))
                    .rotationEffect(Angle(degrees: Double.random(in: 0...360)))
                    .opacity(0.3)
            }
        }
    }
}

struct UploadButtonView: View {
    let title: String
    let iconName: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
            Text(title)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color.blue.opacity(0.4))
        .cornerRadius(20)
    }
}

struct UploadMainView_Previews: PreviewProvider {
    static var previews: some View {
        UploadMainView()
            .environmentObject(AuthViewModel())
            .environmentObject(SettingsManager())
            .environmentObject(LinkingSettingsManager())
    }
}
*/

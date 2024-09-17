// ImageScoringViewWrapper.swift

import SwiftUI

struct ImageScoringViewWrapper: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager

    var body: some View {
        NavigationStack {
            ImageScoringView()
                .environmentObject(authViewModel)
                .environmentObject(scoreManager)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Image Scoring")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true) // Hide the default back button
        }
    }
}

struct ImageScoringViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        ImageScoringViewWrapper()
            .environmentObject(AuthViewModel())
            .environmentObject(ScoreManager(authViewModel: AuthViewModel()))
    }
}

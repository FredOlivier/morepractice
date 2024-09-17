// AppViewModel.swift

import Foundation
import Combine

class AppViewModel: ObservableObject {
    // Published ViewModels
    @Published var authViewModel: AuthViewModel
    @Published var scoreManager: ScoreManager
    @Published var imageManager: ImageManager

    // Initializer
    init() {
        // Initialize AuthViewModel first
        let authVM = AuthViewModel()
        
        // Initialize ScoreManager with the AuthViewModel instance
        let scoreMgr = ScoreManager(authViewModel: authVM)
        
        // Initialize ImageManager with the ScoreManager instance
        let imgMgr = ImageManager(scoreManager: scoreMgr)
        
        // Assign to published properties after all are initialized
        self.authViewModel = authVM
        self.scoreManager = scoreMgr
        self.imageManager = imgMgr
    }
}

// ContentView.swift

import SwiftUI

struct ContentView: View {
    // Observe AuthViewModel from the environment
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                MainAppView()
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut, value: authViewModel.userSession)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let appVM = AppViewModel()
        
        ContentView()
            .environmentObject(appVM.authViewModel)
            .environmentObject(appVM.scoreManager)
            .environmentObject(appVM.imageManager)
    }
}

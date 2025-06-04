//  SignUpView.swift

import SwiftUI

struct SignUpView: View {
    // MARK: ‑ Environment
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appViewModel: AppViewModel        // Added earlier
    @EnvironmentObject var scoreManager: ScoreManager        // If needed
    @EnvironmentObject var mediaManager: MediaManager    
    // If needed
    // @EnvironmentObject var autoChatManager: AutoChatManager // If needed
    
    /// NEW: lets us programmatically close this view when sign‑up finishes
    @Environment(\.dismiss) private var dismiss
    
    // MARK: ‑ State
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // MARK: ‑ Body
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            
            // Display Name
            TextField("Display Name", text: $displayName)
                .autocapitalization(.words)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityLabel("Display Name Field")
                .accessibilityHint("Enter your display name")
            
            // Email
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityLabel("Email Field")
                .accessibilityHint("Enter your email address")
            
            // Password
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityLabel("Password Field")
                .accessibilityHint("Enter your password")
            
            // Error
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Error Message")
                    .accessibilityHint(errorMessage)
            }
            
            // Sign‑Up Button
            Button(action: {
                signUp()
            }) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .accessibilityLabel("Sign Up Button")
            .accessibilityHint("Tap to create a new account")
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        /*  (toolbar removed earlier but left here commented for reference)
        .toolbar { … }
        */
        // ───────────────────────────────────────────────────────────────
        // NEW: as soon as the auth layer reports “signed‑in”, pop this view
        .onReceive(authViewModel.$isSignedIn) { signedIn in
            if signedIn {
                dismiss()
            }
        }
    }
    
    // MARK: ‑ Sign‑Up Logic
    private func signUp() {
        // Basic validation
        guard !displayName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            showError = true
            return
        }
        
        authViewModel.signUp(name: displayName,
                             email: email,
                             password: password) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
            } else {
                // The auth listener flips isSignedIn; onReceive handles dismissal.
                self.showError = false
            }
        }
    }
}

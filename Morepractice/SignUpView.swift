// SignUpView.swift

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            
            // Display Name TextField
            TextField("Display Name", text: $displayName)
                .autocapitalization(.words)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityLabel("Display Name Field")
                .accessibilityHint("Enter your display name")
            
            // Email TextField
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityLabel("Email Field")
                .accessibilityHint("Enter your email address")
            
            // Password SecureField
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityLabel("Password Field")
                .accessibilityHint("Enter your password")
            
            // Error Message
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Error Message")
                    .accessibilityHint(errorMessage)
            }
            
            // Sign Up Button
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
    }
    
    // MARK: - Sign Up Function
    
    /// Handles user sign-up action.
    private func signUp() {
        // Basic validation
        guard !displayName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            showError = true
            return
        }
        
        authViewModel.signUp(name: displayName, email: email, password: password) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
            } else {
                // Successful sign-up is handled by AuthViewModel's listener.
                self.showError = false
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        SignUpView()
            .environmentObject(authVM)
    }
}

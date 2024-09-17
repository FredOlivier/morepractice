// SignInView.swift

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Sign In")
                    .font(.largeTitle)
                    .bold()
                
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
                
                // Sign In Button or Loading Indicator
                if isLoading {
                    ProgressView("Signing In...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Button(action: {
                        login()
                    }) {
                        Text("Sign In")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Sign In Button")
                    .accessibilityHint("Tap to sign into your account")
                }
                
                // Navigation to Sign Up View
                NavigationLink(destination: SignUpView()) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                        .underline()
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Sign In Failed"),
                      message: Text(errorMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Login Function
    
    /// Handles user login action.
    private func login() {
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showError = true
            return
        }
        
        isLoading = true
        authViewModel.signIn(email: email, password: password) { success, error in
            isLoading = false
            if success {
                // Successful login is handled by AuthViewModel's listener.
                self.showError = false
            } else {
                errorMessage = error?.localizedDescription ?? "An unknown error occurred."
                showError = true
                showAlert = true
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        let appVM = AppViewModel()
        
        SignInView()
            .environmentObject(appVM.authViewModel)
            .environmentObject(appVM.scoreManager)
            .environmentObject(appVM.imageManager)
    }
}

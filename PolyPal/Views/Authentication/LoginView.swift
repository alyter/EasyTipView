//
//  LoginView.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import SwiftUI

struct LoginView: View {
  @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
  @State private var email: String = ""
  @State private var password: String = ""
  @State private var isPasswordVisible: Bool = false
  @State private var showingForgotPassword: Bool = false
  
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0) {
          // Header Section
          VStack(spacing: 24) {
            // Back Button and Title
            HStack {
              Button(action: {
                authenticationViewModel.navigateToWelcome()
              }) {
                HStack(spacing: 8) {
                  Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                  Text("Back")
                    .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
              }
              .accessibilityLabel("Go back to welcome screen")
              
              Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Title Section
            VStack(spacing: 16) {
              Text("Welcome Back")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
              
              Text("Sign in to continue to PolyPal")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
          }
          .padding(.bottom, 40)
          
          // Form Section
          VStack(spacing: 24) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
              Text("Email Address")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
              
              TextField("Enter your email", text: $email)
                .textFieldStyle(CustomTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .accessibilityLabel("Email address input field")
                .accessibilityHint("Enter your email address to sign in")
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
              Text("Password")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
              
              HStack {
                if isPasswordVisible {
                  TextField("Enter your password", text: $password)
                    .accessibilityLabel("Password input field")
                } else {
                  SecureField("Enter your password", text: $password)
                    .accessibilityLabel("Password input field")
                }
                
                Button(action: {
                  isPasswordVisible.toggle()
                }) {
                  Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                }
                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
              }
              .textFieldStyle(CustomTextFieldStyle())
              .accessibilityHint("Enter your password to sign in")
            }
            
            // Forgot Password Link
            HStack {
              Spacer()
              Button(action: {
                authenticationViewModel.navigateToPasswordReset()
              }) {
                Text("Forgot Password?")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(.blue)
              }
              .accessibilityLabel("Forgot password link")
              .accessibilityHint("Navigate to password reset screen")
            }
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 32)
          
          // Error Message
          if let errorMessage = authenticationViewModel.errorMessage {
            VStack(spacing: 12) {
              HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundColor(.red)
                  .font(.system(size: 16))
                
                Text(errorMessage)
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(.red)
                  .multilineTextAlignment(.leading)
                
                Spacer()
              }
              .padding(.horizontal, 24)
              .accessibilityLabel("Error: \(errorMessage)")
            }
            .padding(.bottom, 24)
          }
          
          // Sign In Button
          VStack(spacing: 16) {
            Button(action: {
              signIn()
            }) {
              HStack {
                if authenticationViewModel.isLoading {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                } else {
                  Text("Sign In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                }
              }
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(
                LinearGradient(
                  gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .cornerRadius(16)
              .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(!isFormValid || authenticationViewModel.isLoading)
            .opacity((!isFormValid || authenticationViewModel.isLoading) ? 0.6 : 1.0)
            .accessibilityLabel("Sign in button")
            .accessibilityHint("Tap to sign in with your email and password")
            .padding(.horizontal, 24)
            
            // Register Link
            HStack(spacing: 4) {
              Text("Don't have an account?")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
              
              Button(action: {
                authenticationViewModel.navigateToRegister()
              }) {
                Text("Sign Up")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundColor(.blue)
              }
              .accessibilityLabel("Sign up link")
              .accessibilityHint("Navigate to account registration")
            }
          }
          
          Spacer(minLength: 32)
        }
      }
      .frame(minHeight: geometry.size.height)
    }
    .background(
      LinearGradient(
        gradient: Gradient(colors: [
          Color(.systemBackground),
          Color(.systemBackground).opacity(0.95)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .onTapGesture {
      hideKeyboard()
    }
  }
  
  // MARK: - Helper Methods
  
  private var isFormValid: Bool {
    return isValidEmail(email) && isValidPassword(password)
  }
  
  private func signIn() {
    hideKeyboard()
    authenticationViewModel.signIn(email: email, password: password)
  }
  
  private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

// MARK: - Validation Functions

func isValidEmail(_ email: String) -> Bool {
  let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
  let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
  return emailPredicate.evaluate(with: email)
}

func isValidPassword(_ password: String) -> Bool {
  return password.count >= 6
}

func isLoginFormValid(email: String, password: String) -> Bool {
  return isValidEmail(email) && isValidPassword(password)
}

// MARK: - Preview

#Preview {
  LoginView()
    .environmentObject(AuthenticationViewModel())
}

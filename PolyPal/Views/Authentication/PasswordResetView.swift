//
//  PasswordResetView.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import SwiftUI

struct PasswordResetView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @State var email: String = ""
  @State var resetSent: Bool = false
  
  private var isEmailValid: Bool {
    email.contains("@") && email.contains(".") && email.count > 5
  }
  
  private var canSubmit: Bool {
    isEmailValid && authViewModel.canAuthenticate
  }
  
  var body: some View {
    VStack(spacing: 24) {
      Text("Reset Password")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Text("Enter your email address and we'll send you a link to reset your password.")
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
      
      TextField("Email", text: $email)
        .textFieldStyle(CustomTextFieldStyle())
        .textInputAutocapitalization(.never)
        .keyboardType(.emailAddress)
        .autocorrectionDisabled()
      
      Button(action: sendResetLink) {
        HStack {
          if authViewModel.authenticationState == .authenticating {
            ProgressView()
              .scaleEffect(0.8)
              .foregroundColor(.white)
          }
          Text("Send Reset Link")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(canSubmit ? Color.blue : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(8)
      }
      .disabled(!canSubmit)
      
      if let errorMessage = authViewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
      } else if resetSent {
        Text("Reset link sent! Check your email.")
          .foregroundColor(.green)
          .font(.caption)
      }
      
      Button("Back to Login") {
        authViewModel.navigateToLogin()
      }
      .foregroundColor(.blue)
      .font(.body)
      
      Spacer()
    }
    .padding(.horizontal, 24)
    .navigationTitle("Password Reset")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
  }
  
  private func sendResetLink() {
    Task {
      await authViewModel.resetPassword(email: email)
      if authViewModel.errorMessage == nil {
        resetSent = true
      }
    }
  }
}

#Preview {
  NavigationView {
    PasswordResetView()
      .environmentObject(AuthenticationViewModel())
  }
}

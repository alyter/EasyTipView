//
//  RegisterView.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import SwiftUI

struct RegisterView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @State private var firstName = ""
  @State private var lastName = ""
  @State private var email = ""
  @State private var password = ""
  @State private var confirmPassword = ""
  @State private var agreeToTerms = false
  @State private var showPassword = false
  @State private var showConfirmPassword = false
  @FocusState private var focusedField: Field?
  
  private enum Field: Hashable {
    case firstName, lastName, email, password, confirmPassword
  }
  
  // MARK: - Validation Properties
  
  private var isFirstNameValid: Bool {
    !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  private var isLastNameValid: Bool {
    !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  private var isEmailValid: Bool {
    let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return emailPredicate.evaluate(with: email)
  }
  
  private var isPasswordValid: Bool {
    password.count >= 8
  }
  
  private var doPasswordsMatch: Bool {
    !confirmPassword.isEmpty && password == confirmPassword
  }
  
  private var isFormValid: Bool {
    isFirstNameValid && isLastNameValid && isEmailValid && 
    isPasswordValid && doPasswordsMatch && agreeToTerms
  }
  
  // MARK: - Body
  
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        headerSection
        formSection
        errorSection
        registerButton
        loginLink
      }
      .padding(.horizontal, 24)
    }
    .background(Color(.systemBackground))
    .onTapGesture {
      focusedField = nil
    }
  }
  
  private var headerSection: some View {
    VStack(spacing: 16) {
      Image(systemName: "person.badge.plus.fill")
        .font(.system(size: 60))
        .foregroundColor(.blue)
      
      VStack(spacing: 8) {
        Text("Create Account")
          .font(.largeTitle)
          .fontWeight(.bold)
        
        Text("Join PolyPal and start buying and selling")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .padding(.top, 32)
  }
  
  private var formSection: some View {
    VStack(spacing: 20) {
      nameFields
      emailField
      passwordField
      confirmPasswordField
      termsAgreement
    }
  }
  
  private var nameFields: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text("First Name")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
        
        TextField("First name", text: $firstName)
          .textFieldStyle(CustomTextFieldStyle())
          .textContentType(.givenName)
          .autocapitalization(.words)
          .focused($focusedField, equals: .firstName)
          .onSubmit { focusedField = .lastName }
      }
      
      VStack(alignment: .leading, spacing: 6) {
        Text("Last Name")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
        
        TextField("Last name", text: $lastName)
          .textFieldStyle(CustomTextFieldStyle())
          .textContentType(.familyName)
          .autocapitalization(.words)
          .focused($focusedField, equals: .lastName)
          .onSubmit { focusedField = .email }
      }
    }
  }
  
  private var emailField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Email Address")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
      
      TextField("your.email@example.com", text: $email)
        .textFieldStyle(CustomTextFieldStyle())
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .email)
        .onSubmit { focusedField = .password }
    }
  }
  
  private var passwordField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Password")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
      
      HStack {
        if showPassword {
          TextField("Password (8+ characters)", text: $password)
            .textContentType(.newPassword)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .password)
            .onSubmit { focusedField = .confirmPassword }
        } else {
          SecureField("Password (8+ characters)", text: $password)
            .textContentType(.newPassword)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .password)
            .onSubmit { focusedField = .confirmPassword }
        }
        
        Button(action: { showPassword.toggle() }) {
          Image(systemName: showPassword ? "eye.slash" : "eye")
            .foregroundColor(.secondary)
        }
      }
      .textFieldStyle(CustomTextFieldStyle())
    }
  }
  
  private var confirmPasswordField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Confirm Password")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
      
      HStack {
        if showConfirmPassword {
          TextField("Confirm password", text: $confirmPassword)
            .textContentType(.newPassword)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .confirmPassword)
            .onSubmit { if isFormValid { handleRegistration() } }
        } else {
          SecureField("Confirm password", text: $confirmPassword)
            .textContentType(.newPassword)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .confirmPassword)
            .onSubmit { if isFormValid { handleRegistration() } }
        }
        
        Button(action: { showConfirmPassword.toggle() }) {
          Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
            .foregroundColor(.secondary)
        }
      }
      .textFieldStyle(CustomTextFieldStyle())
    }
  }
  
  private var termsAgreement: some View {
    HStack(alignment: .top, spacing: 12) {
      Button(action: { agreeToTerms.toggle() }) {
        Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
          .font(.title2)
          .foregroundColor(agreeToTerms ? .blue : .secondary)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text("I agree to the Terms of Service and Privacy Policy")
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        
        HStack(spacing: 16) {
          Button("Terms of Service") { }
            .font(.caption)
            .foregroundColor(.blue)
          
          Button("Privacy Policy") { }
            .font(.caption)
            .foregroundColor(.blue)
        }
      }
      
      Spacer()
    }
    .padding(.top, 8)
  }
  
  @ViewBuilder
  private var errorSection: some View {
    if let errorMessage = authViewModel.errorMessage {
      Text(errorMessage)
        .font(.caption)
        .foregroundColor(.red)
    }
  }
  
  private var registerButton: some View {
    Button(action: handleRegistration) {
      HStack {
        if authViewModel.isLoading {
          ProgressView()
            .scaleEffect(0.8)
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
        } else {
          Image(systemName: "person.badge.plus")
          Text("Create Account")
            .fontWeight(.semibold)
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(isFormValid ? Color.blue : Color.secondary)
      .foregroundColor(.white)
      .cornerRadius(12)
    }
    .disabled(!isFormValid || authViewModel.isLoading)
  }
  
  private var loginLink: some View {
    HStack(spacing: 4) {
      Text("Already have an account?")
        .font(.subheadline)
        .foregroundColor(.secondary)
      
      Button("Sign In") {
        authViewModel.navigateToLogin()
      }
      .font(.system(size: 15, weight: .medium))
      .foregroundColor(.blue)
    }
    .padding(.bottom, 32)
  }
  
  // MARK: - Actions
  
  private func handleRegistration() {
    guard isFormValid else { return }
    
    focusedField = nil
    authViewModel.register(
      firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
      lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
      email: email.trimmingCharacters(in: .whitespacesAndNewlines),
      password: password,
      confirmPassword: confirmPassword
    )
  }
}

// MARK: - Preview

struct RegisterView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      RegisterView()
        .environmentObject(AuthenticationViewModel())
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
      
      RegisterView()
        .environmentObject(AuthenticationViewModel())
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
      
      RegisterView()
        .environmentObject(AuthenticationViewModel())
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
        .previewDisplayName("iPhone SE")
      
      RegisterView()
        .environmentObject(AuthenticationViewModel())
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro Max"))
        .previewDisplayName("iPhone 16 Pro Max")
    }
  }
}

//
//  AuthenticationViewModel.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import Foundation
import Combine

class AuthenticationViewModel: ObservableObject {
  @Published var authenticationState: AuthenticationState = .unauthenticated
  @Published var currentUser: User?
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?
  
  // Navigation state
  @Published var showingLogin: Bool = false
  @Published var showingRegister: Bool = false
  @Published var showingMFA: Bool = false
  @Published var showingPasswordReset: Bool = false
  
  enum NavigationState {
    case welcome
    case login
    case register
    case mfa
    case passwordReset
  }
  
  @Published var navigationState: NavigationState = .welcome
  
  // Form fields
  @Published var email: String = ""
  @Published var password: String = ""
  @Published var confirmPassword: String = ""
  @Published var firstName: String = ""
  @Published var lastName: String = ""
  @Published var selectedRole: User.UserRole = .buyer
  @Published var mfaCode: String = ""
  
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    // Subscribe to authentication state changes to update loading state
    $authenticationState
      .sink { [weak self] state in
        self?.isLoading = (state == .authenticating)
        if case .error(let message) = state {
          self?.errorMessage = message
        } else {
          self?.errorMessage = nil
        }
      }
      .store(in: &cancellables)
  }
  
  // MARK: - Navigation Actions
  
  func navigateToWelcome() {
    navigationState = .welcome
    showingLogin = false
    showingRegister = false
    showingMFA = false
    showingPasswordReset = false
    clearForm()
    clearError()
  }
  
  func navigateToLogin() {
    navigationState = .login
    showingLogin = true
    showingRegister = false
    showingMFA = false
    showingPasswordReset = false
    clearError()
  }
  
  func navigateToRegister() {
    navigationState = .register
    showingRegister = true
    showingLogin = false
    showingMFA = false
    showingPasswordReset = false
    clearForm()
    clearError()
  }
  
  func navigateToMFA() {
    navigationState = .mfa
    showingMFA = true
    showingLogin = false
    showingRegister = false
    showingPasswordReset = false
    clearError()
  }
  
  func navigateToPasswordReset() {
    navigationState = .passwordReset
    showingPasswordReset = true
    showingLogin = false
    showingRegister = false
    showingMFA = false
    clearError()
  }
  
  private func clearForm() {
    email = ""
    password = ""
    confirmPassword = ""
    firstName = ""
    lastName = ""
    mfaCode = ""
    selectedRole = .buyer
  }
  
  // MARK: - Authentication Actions
  
  func login() {
    login(email: email, password: password)
  }
  
  func login(email: String, password: String) {
    guard !email.isEmpty, !password.isEmpty else {
      authenticationState = .error("Email and password are required")
      return
    }
    
    guard isValidEmail(email) else {
      authenticationState = .error("Please enter a valid email address")
      return
    }
    
    authenticationState = .authenticating
    
    // Placeholder implementation - simulate API call
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      // For now, accept any valid email format with password "password"
      if password == "password" {
        // For demo purposes, require MFA for email containing "mfa"
        if email.lowercased().contains("mfa") {
          self?.authenticationState = .mfaRequired
        } else {
          let user = User(
            email: email,
            role: .buyer,
            firstName: "Test",
            lastName: "User",
            isEmailVerified: true,
            isMFAEnabled: false
          )
          self?.currentUser = user
          self?.authenticationState = .authenticated
        }
      } else {
        self?.authenticationState = .error("Invalid email or password")
      }
    }
  }
  
  func signIn(email: String, password: String) {
    login(email: email, password: password)
  }
  
  func register(firstName: String, lastName: String, email: String, password: String, confirmPassword: String) {
    guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
      authenticationState = .error("All fields are required")
      return
    }
    
    guard isValidEmail(email) else {
      authenticationState = .error("Please enter a valid email address")
      return
    }
    
    guard password == confirmPassword else {
      authenticationState = .error("Passwords do not match")
      return
    }
    
    guard password.count >= 8 else {
      authenticationState = .error("Password must be at least 8 characters")
      return
    }
    
    authenticationState = .authenticating
    
    // Placeholder implementation - simulate API call
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      let user = User(
        email: email,
        role: .buyer, // Default role for registration
        firstName: firstName,
        lastName: lastName,
        isEmailVerified: false,
        isMFAEnabled: false
      )
      self?.currentUser = user
      self?.authenticationState = .authenticated
    }
  }
  
  func register(email: String, password: String, confirmPassword: String, role: User.UserRole) {
    guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
      authenticationState = .error("All fields are required")
      return
    }
    
    guard isValidEmail(email) else {
      authenticationState = .error("Please enter a valid email address")
      return
    }
    
    guard password == confirmPassword else {
      authenticationState = .error("Passwords do not match")
      return
    }
    
    guard password.count >= 8 else {
      authenticationState = .error("Password must be at least 8 characters")
      return
    }
    
    authenticationState = .authenticating
    
    // Placeholder implementation - simulate API call
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      let user = User(
        email: email,
        role: role,
        isEmailVerified: false,
        isMFAEnabled: false
      )
      self?.currentUser = user
      self?.authenticationState = .authenticated
    }
  }
  
  func register() {
    register(email: email, password: password, confirmPassword: confirmPassword, role: selectedRole)
  }
  
  func verifyMFA() {
    verifyMFA(code: mfaCode)
  }
  
  func verifyMFA(code: String) {
    guard !code.isEmpty, code.count == 6 else {
      authenticationState = .error("Please enter a valid 6-digit code")
      return
    }
    
    authenticationState = .authenticating
    
    // Placeholder implementation - simulate MFA verification
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      if code == "123456" {
        self?.authenticationState = .authenticated
      } else {
        self?.authenticationState = .error("Invalid verification code")
      }
    }
  }
  
  func requestPasswordReset(email: String) {
    guard !email.isEmpty else {
      authenticationState = .error("Email is required")
      return
    }
    
    guard isValidEmail(email) else {
      authenticationState = .error("Please enter a valid email address")
      return
    }
    
    authenticationState = .authenticating
    
    // Placeholder implementation - simulate password reset request
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.authenticationState = .unauthenticated
      // In a real app, we'd show a success message here
    }
  }
  
  @MainActor
  func resetPassword(email: String) async {
    guard !email.isEmpty else {
      authenticationState = .error("Email is required")
      return
    }
    
    guard isValidEmail(email) else {
      authenticationState = .error("Please enter a valid email address")
      return
    }
    
    authenticationState = .authenticating
    
    // Simulate API call
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    
    // In a real implementation, this would send a reset email
    // For now, we'll just reset the state to indicate success
    authenticationState = .unauthenticated
  }
  
  func logout() {
    currentUser = nil
    authenticationState = .unauthenticated
    errorMessage = nil
  }
  
  func clearError() {
    errorMessage = nil
    if case .error = authenticationState {
      authenticationState = .unauthenticated
    }
  }
  
  // MARK: - Helper Methods
  
  private func isValidEmail(_ email: String) -> Bool {
    let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return email.range(of: emailRegex, options: .regularExpression) != nil
  }
  
  var isAuthenticated: Bool {
    return authenticationState == .authenticated
  }
  
  var canAuthenticate: Bool {
    return authenticationState != .authenticating
  }
  
  // MARK: - MFA Methods
  
  func isValidMFACode(_ code: String) -> Bool {
    // MFA code should be exactly 6 digits
    let cleanedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
    return cleanedCode.count == 6 && cleanedCode.allSatisfy { $0.isNumber }
  }
  
  func formatMFACode(_ input: String) -> String {
    // Remove all non-digit characters and limit to 6 digits
    let digitsOnly = input.filter { $0.isNumber }
    return String(digitsOnly.prefix(6))
  }
  
  func verifyMFA(_ code: String) async {
    guard isValidMFACode(code) else {
      authenticationState = .error("Please enter a valid 6-digit code")
      return
    }
    
    authenticationState = .authenticating
    
    // Simulate API delay
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    
    await MainActor.run {
      // For demo purposes, accept "123456" as valid code
      if code == "123456" {
        authenticationState = .authenticated
      } else {
        authenticationState = .error("Invalid MFA code")
      }
    }
  }
  
  func resendMFACode() async {
    // Simulate resend API call
    try? await Task.sleep(nanoseconds: 500_000_000)
    
    await MainActor.run {
      // Clear any existing errors and stay in MFA required state
      authenticationState = .mfaRequired
    }
  }
  
  func navigateBackFromMFA() {
    navigationState = .login
    showingMFA = false
    showingLogin = true
    authenticationState = .unauthenticated
    mfaCode = ""
    clearError()
  }
}

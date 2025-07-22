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
  
  // MARK: - Authentication Actions
  
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
      } else {
        self?.authenticationState = .error("Invalid email or password")
      }
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
}

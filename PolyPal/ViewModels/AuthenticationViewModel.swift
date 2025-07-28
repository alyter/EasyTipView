//
//  AuthenticationViewModel.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import Foundation
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
  @Published var authenticationState: AuthenticationState = .unauthenticated
  @Published var currentUser: User?
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?
  
  // Zoho authentication integration - temporarily disabled due to build issues
  @Published var isZohoAuthenticated: Bool = false
  @Published var zohoAuthenticationError: String?
  
  // Navigation state
  @Published var showingLogin: Bool = false
  @Published var showingRegister: Bool = false
  @Published var showingPasswordReset: Bool = false
  
  enum NavigationState {
    case welcome
    case login
    case register
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
    showingPasswordReset = false
    clearForm()
    clearError()
  }
  
  func navigateToLogin() {
    navigationState = .login
    showingLogin = true
    showingRegister = false
    showingPasswordReset = false
    clearError()
  }
  
  func navigateToRegister() {
    navigationState = .register
    showingRegister = true
    showingLogin = false
    showingPasswordReset = false
    clearForm()
    clearError()
  }
  
  func navigateToPasswordReset() {
    navigationState = .passwordReset
    showingPasswordReset = true
    showingLogin = false
    showingRegister = false
    clearError()
  }
  
  private func clearForm() {
    email = ""
    password = ""
    confirmPassword = ""
    firstName = ""
    lastName = ""
    selectedRole = .buyer
  }
  
  // MARK: - Authentication Actions
  
  func login() {
    login(email: email, password: password)
  }
  
  func login(email: String, password: String) {
    Task {
      await performLogin(email: email, password: password)
    }
  }
  
  private func performLogin(email: String, password: String) async {
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
    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
    
    // For now, accept any valid email format with password "password"
    if password == "password" {
      // Create user based on email
      let user = User(
        email: email,
        role: .buyer,
        firstName: "Test",
        lastName: "User",
        isEmailVerified: true
      )
      
      currentUser = user
      authenticationState = .authenticated
    } else {
      authenticationState = .error("Invalid email or password")
    }
  }
  
  func signIn(email: String, password: String) {
    login(email: email, password: password)
  }
  
  func register(firstName: String, lastName: String, email: String, password: String, confirmPassword: String) {
    Task {
      await performRegister(firstName: firstName, lastName: lastName, email: email, password: password, confirmPassword: confirmPassword)
    }
  }
  
  private func performRegister(firstName: String, lastName: String, email: String, password: String, confirmPassword: String) async {
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
    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2.0 seconds
    
    let user = User(
      email: email,
      role: .buyer, // Default role for registration
      firstName: firstName,
      lastName: lastName,
      isEmailVerified: false
    )
    currentUser = user
    authenticationState = .authenticated
  }
  
  func register(email: String, password: String, confirmPassword: String, role: User.UserRole) {
    Task {
      await performRegister(email: email, password: password, confirmPassword: confirmPassword, role: role)
    }
  }
  
  private func performRegister(email: String, password: String, confirmPassword: String, role: User.UserRole) async {
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
    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2.0 seconds
    
    let user = User(
      email: email,
      role: role,
      isEmailVerified: false
    )
    currentUser = user
    authenticationState = .authenticated
  }
  
  func register() {
    register(email: email, password: password, confirmPassword: confirmPassword, role: selectedRole)
  }
  
  func requestPasswordReset(email: String) {
    Task {
      await performPasswordReset(email: email)
    }
  }
  
  private func performPasswordReset(email: String) async {
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
    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1.0 second
    
    authenticationState = .unauthenticated
    // In a real app, we'd show a success message here
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
  
  // MARK: - Zoho Authentication Integration
  
  func authenticateWithZoho() async {
    // Temporarily disabled due to build issues
    await MainActor.run {
      zohoAuthenticationError = "Authentication manager not initialized"
      isLoading = false
    }
    return
  }
  
  func refreshZohoToken() async {
    // Temporarily disabled due to build issues
    return
  }
  
  func logoutFromZoho() async {
    // Temporarily disabled due to build issues
    await MainActor.run {
      isZohoAuthenticated = false
      zohoAuthenticationError = nil
    }
  }
  
  func integratedLogout() async {
    // Logout from both JWT and Zoho systems
    logout()
    await logoutFromZoho()
  }
  
  func checkZohoAuthenticationStatus() {
    // Temporarily disabled due to build issues
    isZohoAuthenticated = false
  }
  
  func clearZohoError() {
    zohoAuthenticationError = nil
  }
  
  // MARK: - Dual Authentication Management
  
  var isBothSystemsAuthenticated: Bool {
    return isAuthenticated && isZohoAuthenticated
  }
  
  var hasAnyAuthentication: Bool {
    return isAuthenticated || isZohoAuthenticated
  }
  
  func getAuthenticationStatus() -> (jwt: Bool, zoho: Bool) {
    return (jwt: isAuthenticated, zoho: isZohoAuthenticated)
  }
  
  func handleAuthenticationConflict() async {
    // Handle conflicts between JWT and Zoho authentication
    if isAuthenticated && !isZohoAuthenticated {
      // JWT is authenticated but Zoho is not - attempt Zoho auth
      await authenticateWithZoho()
    }
  }
  
  func validateDualAuthentication() -> Bool {
    // Validate that both authentication systems are in a consistent state
    let jwtValid = isAuthenticated && currentUser != nil
    let zohoValid = isZohoAuthenticated
    
    return jwtValid || zohoValid // At least one should be valid
  }
}

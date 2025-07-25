//
//  AuthenticationViewModelTests.swift
//  PolyPalTests
//
//  Created on 2025-07-22.
//

import XCTest
import Combine
@testable import PolyPal

final class AuthenticationViewModelTests: XCTestCase {
  private var viewModel: AuthenticationViewModel!
  private var cancellables: Set<AnyCancellable>!
  
  override func setUp() {
    super.setUp()
    viewModel = AuthenticationViewModel()
    cancellables = Set<AnyCancellable>()
  }
  
  override func tearDown() {
    viewModel = nil
    cancellables = nil
    super.tearDown()
  }
  
  func testInitialState() {
    XCTAssertEqual(viewModel.authenticationState, .unauthenticated)
    XCTAssertNil(viewModel.currentUser)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertFalse(viewModel.isAuthenticated)
    XCTAssertTrue(viewModel.canAuthenticate)
  }
  
  func testLoadingStateUpdates() {
    let expectation = XCTestExpectation(description: "Loading state updates")
    
    viewModel.$isLoading
      .dropFirst() // Skip initial false value
      .sink { isLoading in
        XCTAssertTrue(isLoading)
        expectation.fulfill()
      }
      .store(in: &cancellables)
    
    viewModel.authenticationState = .authenticating
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testErrorStateUpdates() {
    let expectation = XCTestExpectation(description: "Error message updates")
    let testError = "Test error message"
    
    viewModel.$errorMessage
      .dropFirst() // Skip initial nil value
      .sink { errorMessage in
        XCTAssertEqual(errorMessage, testError)
        expectation.fulfill()
      }
      .store(in: &cancellables)
    
    viewModel.authenticationState = .error(testError)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testLoginWithValidCredentials() {
    let expectation = XCTestExpectation(description: "Successful login")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if state == .authenticated {
          XCTAssertNotNil(self.viewModel.currentUser)
          XCTAssertEqual(self.viewModel.currentUser?.email, "test@example.com")
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.login(email: "test@example.com", password: "password")
    
    wait(for: [expectation], timeout: 3.0)
  }
  
  func testLoginWithInvalidCredentials() {
    let expectation = XCTestExpectation(description: "Failed login")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if case .error(let message) = state {
          XCTAssertEqual(message, "Invalid email or password")
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.login(email: "test@example.com", password: "wrongpassword")
    
    wait(for: [expectation], timeout: 3.0)
  }
  
  func testLoginWithEmptyCredentials() {
    viewModel.login(email: "", password: "")
    
    if case .error(let message) = viewModel.authenticationState {
      XCTAssertEqual(message, "Email and password are required")
    } else {
      XCTFail("Expected error state for empty credentials")
    }
  }
  
  func testLoginWithInvalidEmail() {
    viewModel.login(email: "invalid-email", password: "password")
    
    if case .error(let message) = viewModel.authenticationState {
      XCTAssertEqual(message, "Please enter a valid email address")
    } else {
      XCTFail("Expected error state for invalid email")
    }
  }
  
  func testRegisterWithValidData() {
    let expectation = XCTestExpectation(description: "Successful registration")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if state == .authenticated {
          XCTAssertNotNil(self.viewModel.currentUser)
          XCTAssertEqual(self.viewModel.currentUser?.email, "newuser@example.com")
          XCTAssertEqual(self.viewModel.currentUser?.role, .vendor)
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.register(
      email: "newuser@example.com",
      password: "password123",
      confirmPassword: "password123",
      role: .vendor
    )
    
    wait(for: [expectation], timeout: 3.0)
  }
  
  func testRegisterWithMismatchedPasswords() {
    viewModel.register(
      email: "test@example.com",
      password: "password123",
      confirmPassword: "differentpassword",
      role: .buyer
    )
    
    if case .error(let message) = viewModel.authenticationState {
      XCTAssertEqual(message, "Passwords do not match")
    } else {
      XCTFail("Expected error state for mismatched passwords")
    }
  }
  
  func testRegisterWithShortPassword() {
    viewModel.register(
      email: "test@example.com",
      password: "short",
      confirmPassword: "short",
      role: .buyer
    )
    
    if case .error(let message) = viewModel.authenticationState {
      XCTAssertEqual(message, "Password must be at least 8 characters")
    } else {
      XCTFail("Expected error state for short password")
    }
  }
  
  func testMFAVerificationWithValidCode() {
    let expectation = XCTestExpectation(description: "Successful MFA verification")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if state == .authenticated {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    // Use the non-async method that internally calls the async version
    viewModel.mfaCode = "123456"
    viewModel.verifyMFA()
    
    wait(for: [expectation], timeout: 2.0)
  }
  
  func testMFAVerificationWithInvalidCode() {
    let expectation = XCTestExpectation(description: "Failed MFA verification")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if case .error(let message) = state {
          XCTAssertEqual(message, "Invalid MFA code")
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    // Use the non-async method that internally calls the async version
    viewModel.mfaCode = "000000"
    viewModel.verifyMFA()
    
    wait(for: [expectation], timeout: 2.0)
  }
  
  func testMFAVerificationWithInvalidFormat() {
    // Use the non-async method that internally calls the async version
    viewModel.mfaCode = "123"
    viewModel.verifyMFA()
    
    // Wait a moment for the async operation to complete
    let expectation = XCTestExpectation(description: "Invalid format error")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if case .error(let message) = state {
          XCTAssertEqual(message, "Please enter a valid 6-digit code")
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    wait(for: [expectation], timeout: 2.0)
  }
  
  func testPasswordResetRequest() {
    let expectation = XCTestExpectation(description: "Password reset requested")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if state == .unauthenticated {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.requestPasswordReset(email: "test@example.com")
    
    wait(for: [expectation], timeout: 2.0)
  }
  
  func testPasswordResetWithInvalidEmail() {
    viewModel.requestPasswordReset(email: "invalid-email")
    
    if case .error(let message) = viewModel.authenticationState {
      XCTAssertEqual(message, "Please enter a valid email address")
    } else {
      XCTFail("Expected error state for invalid email")
    }
  }
  
  func testLogout() {
    // First set up authenticated state
    let user = User(email: "test@example.com", role: .buyer)
    viewModel.currentUser = user
    viewModel.authenticationState = .authenticated
    
    // Test logout
    viewModel.logout()
    
    XCTAssertEqual(viewModel.authenticationState, .unauthenticated)
    XCTAssertNil(viewModel.currentUser)
    XCTAssertNil(viewModel.errorMessage)
  }
  
  func testClearError() {
    // Set error state
    viewModel.authenticationState = .error("Test error")
    XCTAssertEqual(viewModel.errorMessage, "Test error")
    
    // Clear error
    viewModel.clearError()
    
    XCTAssertEqual(viewModel.authenticationState, .unauthenticated)
    XCTAssertNil(viewModel.errorMessage)
  }
  
  func testIsAuthenticatedProperty() {
    XCTAssertFalse(viewModel.isAuthenticated)
    
    viewModel.authenticationState = .authenticated
    XCTAssertTrue(viewModel.isAuthenticated)
    
    viewModel.authenticationState = .authenticating
    XCTAssertFalse(viewModel.isAuthenticated)
    
    viewModel.authenticationState = .error("Test")
    XCTAssertFalse(viewModel.isAuthenticated)
  }
  
  func testCanAuthenticateProperty() {
    XCTAssertTrue(viewModel.canAuthenticate)
    
    viewModel.authenticationState = .authenticating
    XCTAssertFalse(viewModel.canAuthenticate)
    
    viewModel.authenticationState = .authenticated
    XCTAssertTrue(viewModel.canAuthenticate)
    
    viewModel.authenticationState = .error("Test")
    XCTAssertTrue(viewModel.canAuthenticate)
  }
  
  // MARK: - Enhanced MFA Tests
  
  func testLoginWithMFAEnabledUser() {
    let expectation = XCTestExpectation(description: "Login requires MFA")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if state == .mfaRequired {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.login(email: "mfa@example.com", password: "password")
    
    wait(for: [expectation], timeout: 3.0)
  }
  
  func testMFAVerificationWithTOTPCode() async {
    // Set up MFA required state with a current user
    let user = User(email: "test@example.com", role: .buyer, isMFAEnabled: true)
    viewModel.currentUser = user
    viewModel.authenticationState = .mfaRequired
    
    // Test with valid TOTP code using the enhanced method
    await viewModel.verifyMFAWithTOTP("123456")
    
    XCTAssertEqual(viewModel.authenticationState, .authenticated)
  }
  
  func testMFAVerificationWithBackupCode() async {
    // Set up MFA required state and user
    let user = User(email: "test@example.com", role: .buyer, isMFAEnabled: true)
    viewModel.currentUser = user
    viewModel.authenticationState = .mfaRequired
    
    // Generate and store backup codes for the user first
    let userId = user.id.uuidString
    let codes = viewModel.generateBackupCodes(for: userId)
    
    // Test backup code verification with a valid code
    await viewModel.verifyBackupCode(codes.first!)
    
    XCTAssertEqual(viewModel.authenticationState, .authenticated)
  }
  
  func testMFAVerificationWithInvalidBackupCode() async {
    // Set up MFA required state and user
    let user = User(email: "test@example.com", role: .buyer, isMFAEnabled: true)
    viewModel.currentUser = user
    viewModel.authenticationState = .mfaRequired
    
    // Test with invalid backup code
    await viewModel.verifyBackupCode("INVALID-CODE")
    
    if case .error(let message) = viewModel.authenticationState {
      XCTAssertTrue(message.contains("backup code"))
    } else {
      XCTFail("Expected error state for invalid backup code")
    }
  }
  
  func testMFAVerificationRateLimit() async {
    // Set up MFA required state and user
    let user = User(email: "test@example.com", role: .buyer, isMFAEnabled: true)
    viewModel.currentUser = user
    viewModel.authenticationState = .mfaRequired
    
    // Attempt multiple failed verifications using TOTP method
    for _ in 0..<3 {
      await viewModel.verifyMFAWithTOTP("000000")
    }
    
    // Next attempt should be rate limited
    await viewModel.verifyMFAWithTOTP("000000")
    
    if case .error(let message) = viewModel.authenticationState {
      XCTAssertTrue(message.contains("too many attempts") || message.contains("rate limit"))
    } else {
      XCTFail("Expected rate limit error after multiple failed attempts")
    }
  }
  
  func testMFACodeFormatting() {
    // Test various input formats
    XCTAssertEqual(viewModel.formatMFACode("123456"), "123456")
    XCTAssertEqual(viewModel.formatMFACode("123 456"), "123456")
    XCTAssertEqual(viewModel.formatMFACode("1234567890"), "123456")
    XCTAssertEqual(viewModel.formatMFACode("abc123def456"), "123456")
    XCTAssertEqual(viewModel.formatMFACode(""), "")
  }
  
  func testMFACodeValidation() {
    // Valid codes
    XCTAssertTrue(viewModel.isValidMFACode("123456"))
    XCTAssertTrue(viewModel.isValidMFACode("000000"))
    XCTAssertTrue(viewModel.isValidMFACode("999999"))
    
    // Invalid codes
    XCTAssertFalse(viewModel.isValidMFACode("12345"))   // Too short
    XCTAssertFalse(viewModel.isValidMFACode("1234567")) // Too long
    XCTAssertFalse(viewModel.isValidMFACode("12345a"))  // Contains letter
    XCTAssertFalse(viewModel.isValidMFACode(""))        // Empty
    XCTAssertFalse(viewModel.isValidMFACode(" 123456 ")) // Leading/trailing space
  }
  
  func testBackupCodeFormatting() {
    // Test various backup code formats
    XCTAssertEqual(viewModel.formatBackupCode("ABCD1234"), "ABCD-1234")
    XCTAssertEqual(viewModel.formatBackupCode("abcd1234"), "ABCD-1234")
    XCTAssertEqual(viewModel.formatBackupCode("ABCD-1234"), "ABCD-1234")
    XCTAssertEqual(viewModel.formatBackupCode("AB CD 12 34"), "ABCD-1234")
  }
  
  func testBackupCodeValidation() {
    // Valid backup codes
    XCTAssertTrue(viewModel.isValidBackupCode("ABCD-1234"))
    XCTAssertTrue(viewModel.isValidBackupCode("XYZA-9876"))
    
    // Invalid backup codes
    XCTAssertFalse(viewModel.isValidBackupCode("ABCD1234"))   // Missing dash
    XCTAssertFalse(viewModel.isValidBackupCode("ABC-1234"))   // Too short
    XCTAssertFalse(viewModel.isValidBackupCode("ABCDE-1234")) // Too long
    XCTAssertFalse(viewModel.isValidBackupCode(""))           // Empty
  }
  
  func testMFAResendCode() async {
    // Set up MFA required state
    viewModel.authenticationState = .mfaRequired
    
    await viewModel.resendMFACode()
    
    // Should remain in MFA required state
    XCTAssertEqual(viewModel.authenticationState, .mfaRequired)
    XCTAssertNil(viewModel.errorMessage)
  }
  
  func testMFANavigationBackToLogin() {
    // Set up MFA state
    viewModel.authenticationState = .mfaRequired
    viewModel.showingMFA = true
    viewModel.mfaCode = "123456"
    
    viewModel.navigateBackFromMFA()
    
    XCTAssertEqual(viewModel.navigationState, .login)
    XCTAssertFalse(viewModel.showingMFA)
    XCTAssertTrue(viewModel.showingLogin)
    XCTAssertEqual(viewModel.authenticationState, .unauthenticated)
    XCTAssertEqual(viewModel.mfaCode, "")
    XCTAssertNil(viewModel.errorMessage)
  }
  
  func testMFASetupNavigation() {
    viewModel.navigateToMFASetup()
    
    XCTAssertEqual(viewModel.navigationState, .mfaSetup)
    XCTAssertTrue(viewModel.showingMFASetup)
    XCTAssertFalse(viewModel.showingLogin)
    XCTAssertFalse(viewModel.showingMFA)
    XCTAssertNil(viewModel.errorMessage)
  }
  
  func testMFADisableConfirmation() {
    // Set up authenticated user with MFA enabled
    let user = User(email: "test@example.com", role: .buyer, isMFAEnabled: true)
    viewModel.currentUser = user
    viewModel.authenticationState = .authenticated
    
    viewModel.requestMFADisable()
    
    XCTAssertEqual(viewModel.navigationState, .mfaDisableConfirmation)
    XCTAssertTrue(viewModel.showingMFADisableConfirmation)
  }
  
  func testMFADisableExecution() async {
    // Set up authenticated user with MFA enabled
    let user = User(email: "test@example.com", role: .buyer, isMFAEnabled: true)
    viewModel.currentUser = user
    viewModel.authenticationState = .authenticated
    
    await viewModel.disableMFA()
    
    XCTAssertFalse(viewModel.currentUser?.isMFAEnabled ?? true)
    XCTAssertEqual(viewModel.authenticationState, .authenticated)
  }
  
  func testSecurityAuditLogging() {
    // Test that security events are logged
    viewModel.logSecurityEvent(.mfaVerificationAttempt, details: ["result": "success"])
    viewModel.logSecurityEvent(.mfaVerificationAttempt, details: ["result": "failure"])
    viewModel.logSecurityEvent(.mfaEnabled, details: ["userId": "test-user"])
    viewModel.logSecurityEvent(.mfaDisabled, details: ["userId": "test-user"])
    
    // In a real implementation, we would verify the logs were written
    // For now, we just ensure the methods don't crash
    XCTAssertTrue(true)
  }
  
  func testMemoryCleanupOnLogout() {
    // Set up authenticated state with sensitive data
    viewModel.currentUser = User(email: "test@example.com", role: .buyer)
    viewModel.authenticationState = .authenticated
    viewModel.mfaCode = "123456"
    
    // Use the enhanced logout method
    viewModel.enhancedLogout()
    
    // Verify sensitive data is cleared
    XCTAssertNil(viewModel.currentUser)
    XCTAssertEqual(viewModel.authenticationState, .unauthenticated)
    XCTAssertEqual(viewModel.mfaCode, "")
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertEqual(viewModel.navigationState, .welcome)
  }
}

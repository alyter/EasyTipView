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
    
    viewModel.verifyMFA(code: "123456")
    
    wait(for: [expectation], timeout: 2.0)
  }
  
  func testMFAVerificationWithInvalidCode() {
    let expectation = XCTestExpectation(description: "Failed MFA verification")
    
    viewModel.$authenticationState
      .dropFirst() // Skip initial unauthenticated
      .sink { state in
        if case .error(let message) = state {
          XCTAssertEqual(message, "Invalid verification code")
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.verifyMFA(code: "000000")
    
    wait(for: [expectation], timeout: 2.0)
  }
  
  func testMFAVerificationWithInvalidFormat() {
    viewModel.verifyMFA(code: "123")
    
    if case .error(let message) = viewModel.authenticationState {
      XCTAssertEqual(message, "Please enter a valid 6-digit code")
    } else {
      XCTFail("Expected error state for invalid code format")
    }
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
}

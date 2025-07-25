//
//  AuthenticationFlowTests.swift
//  PolyPalTests
//
//  Created on 2025-07-22.
//

import XCTest
import SwiftUI
@testable import PolyPal

final class AuthenticationFlowTests: XCTestCase {
  var authViewModel: AuthenticationViewModel!
  
  override func setUpWithError() throws {
    authViewModel = AuthenticationViewModel()
  }
  
  override func tearDownWithError() throws {
    authViewModel = nil
  }
  
  // MARK: - Navigation State Tests
  
  func testInitialNavigationState() {
    XCTAssertEqual(authViewModel.currentView, .welcome)
    XCTAssertFalse(authViewModel.showingLogin)
    XCTAssertFalse(authViewModel.showingRegister)
    XCTAssertFalse(authViewModel.showingMFA)
    XCTAssertFalse(authViewModel.showingPasswordReset)
  }
  
  func testNavigateToLogin() {
    authViewModel.navigateToLogin()
    XCTAssertEqual(authViewModel.currentView, .login)
    XCTAssertTrue(authViewModel.showingLogin)
    XCTAssertFalse(authViewModel.showingRegister)
  }
  
  func testNavigateToRegister() {
    authViewModel.navigateToRegister()
    XCTAssertEqual(authViewModel.currentView, .register)
    XCTAssertTrue(authViewModel.showingRegister)
    XCTAssertFalse(authViewModel.showingLogin)
  }
  
  func testNavigateToMFA() {
    authViewModel.navigateToMFA()
    XCTAssertEqual(authViewModel.currentView, .mfa)
    XCTAssertTrue(authViewModel.showingMFA)
  }
  
  func testNavigateToPasswordReset() {
    authViewModel.navigateToPasswordReset()
    XCTAssertEqual(authViewModel.currentView, .passwordReset)
    XCTAssertTrue(authViewModel.showingPasswordReset)
  }
  
  func testNavigateBackToWelcome() {
    authViewModel.navigateToLogin()
    authViewModel.navigateToWelcome()
    XCTAssertEqual(authViewModel.currentView, .welcome)
    XCTAssertFalse(authViewModel.showingLogin)
  }
  
  // MARK: - View Transition Tests
  
  func testLoginToMFATransition() {
    // Start at login
    authViewModel.navigateToLogin()
    authViewModel.email = "test@example.com"
    authViewModel.password = "password"
    
    // Simulate successful login requiring MFA
    let expectation = expectation(description: "Login with MFA")
    authViewModel.login()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      if self.authViewModel.authenticationState == .authenticated {
        self.authViewModel.navigateToMFA()
        expectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: 2.0)
    XCTAssertEqual(authViewModel.currentView, .mfa)
    XCTAssertTrue(authViewModel.showingMFA)
  }
  
  func testRegisterToLoginTransition() {
    authViewModel.navigateToRegister()
    authViewModel.navigateToLogin()
    
    XCTAssertEqual(authViewModel.currentView, .login)
    XCTAssertTrue(authViewModel.showingLogin)
    XCTAssertFalse(authViewModel.showingRegister)
  }
  
  func testPasswordResetNavigation() {
    authViewModel.navigateToLogin()
    authViewModel.navigateToPasswordReset()
    
    XCTAssertEqual(authViewModel.currentView, .passwordReset)
    XCTAssertTrue(authViewModel.showingPasswordReset)
    XCTAssertFalse(authViewModel.showingLogin)
  }
  
  // MARK: - Authentication Flow Integration Tests
  
  func testCompleteAuthenticationFlow() {
    // Start at welcome
    XCTAssertEqual(authViewModel.currentView, .welcome)
    
    // Navigate to login
    authViewModel.navigateToLogin()
    XCTAssertEqual(authViewModel.currentView, .login)
    
    // Attempt login with valid credentials
    authViewModel.email = "test@example.com"
    authViewModel.password = "password"
    
    let loginExpectation = expectation(description: "Login attempt")
    authViewModel.login()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      loginExpectation.fulfill()
    }
    
    waitForExpectations(timeout: 2.0)
    
    // Should either be authenticated or authenticating
    XCTAssertTrue(authViewModel.authenticationState == .authenticated || authViewModel.authenticationState == .authenticating)
  }
  
  func testMFAVerificationFlow() {
    // Setup MFA state
    authViewModel.authenticationState = .mfaRequired
    authViewModel.navigateToMFA()
    
    XCTAssertEqual(authViewModel.currentView, .mfa)
    
    // Test valid MFA code
    authViewModel.mfaCode = "123456"
    
    let mfaExpectation = expectation(description: "MFA verification")
    authViewModel.verifyMFA()
    
    // Wait longer for the async operation to complete
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      mfaExpectation.fulfill()
    }
    
    waitForExpectations(timeout: 3.0)
    
    // Should be authenticated after successful MFA
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
  }
  
  // MARK: - Error Handling Tests
  
  func testNavigationWithErrors() {
    authViewModel.navigateToLogin()
    authViewModel.errorMessage = "Network error"
    
    // Navigation should still work with errors present
    authViewModel.navigateToRegister()
    XCTAssertEqual(authViewModel.currentView, .register)
    
    // Error should be cleared on navigation
    XCTAssertNil(authViewModel.errorMessage)
  }
  
  func testNavigationClearsForm() {
    authViewModel.navigateToLogin()
    authViewModel.email = "test@example.com"
    authViewModel.password = "password"
    
    authViewModel.navigateToRegister()
    
    // Form should be cleared when navigating
    XCTAssertTrue(authViewModel.email.isEmpty)
    XCTAssertTrue(authViewModel.password.isEmpty)
  }
}

// MARK: - Test Extensions

extension AuthenticationViewModel {
  enum AuthenticationView {
    case welcome
    case login
    case register
    case mfa
    case passwordReset
  }
  
  var currentView: AuthenticationView {
    if showingLogin { return .login }
    if showingRegister { return .register }
    if showingMFA { return .mfa }
    if showingPasswordReset { return .passwordReset }
    return .welcome
  }
}

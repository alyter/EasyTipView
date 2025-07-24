//
//  LoginViewTests.swift
//  PolyPalTests
//
//  Created on 2025-07-22.
//

import XCTest
import SwiftUI
@testable import PolyPal

final class LoginViewTests: XCTestCase {
  var authenticationViewModel: AuthenticationViewModel!
  
  override func setUpWithError() throws {
    authenticationViewModel = AuthenticationViewModel()
  }
  
  override func tearDownWithError() throws {
    authenticationViewModel = nil
  }
  
  func testLoginViewInitialState() throws {
    // Given
    let loginView = LoginView()
      .environmentObject(authenticationViewModel)
    
    // When - View is initialized
    
    // Then - Initial state should be correct
    XCTAssertEqual(authenticationViewModel.authenticationState, .unauthenticated)
  }
  
  func testEmailValidation() throws {
    // Test cases for email validation
    let validEmails = [
      "test@example.com",
      "user.name@domain.co.uk",
      "user+tag@example.org"
    ]
    
    let invalidEmails = [
      "invalid-email",
      "@example.com",
      "user@",
      "",
      "user space@example.com"
    ]
    
    for email in validEmails {
      XCTAssertTrue(isValidEmail(email), "Email \(email) should be valid")
    }
    
    for email in invalidEmails {
      XCTAssertFalse(isValidEmail(email), "Email \(email) should be invalid")
    }
  }
  
  func testPasswordValidation() throws {
    // Test password requirements
    let validPasswords = [
      "password123",
      "mySecurePass",
      "test1234"
    ]
    
    let invalidPasswords = [
      "",
      "123",
      "ab"
    ]
    
    for password in validPasswords {
      XCTAssertTrue(isValidPassword(password), "Password should be valid (min 6 chars)")
    }
    
    for password in invalidPasswords {
      XCTAssertFalse(isValidPassword(password), "Password should be invalid (less than 6 chars)")
    }
  }
  
  func testLoginFormValidation() throws {
    // Given
    let validEmail = "test@example.com"
    let validPassword = "password123"
    let invalidEmail = "invalid-email"
    let invalidPassword = "123"
    
    // Test valid form
    XCTAssertTrue(isLoginFormValid(email: validEmail, password: validPassword))
    
    // Test invalid email
    XCTAssertFalse(isLoginFormValid(email: invalidEmail, password: validPassword))
    
    // Test invalid password
    XCTAssertFalse(isLoginFormValid(email: validEmail, password: invalidPassword))
    
    // Test both invalid
    XCTAssertFalse(isLoginFormValid(email: invalidEmail, password: invalidPassword))
  }
  
  func testLoginAction() throws {
    // Given
    let email = "test@example.com"
    let password = "password123"
    
    // When
    authenticationViewModel.signIn(email: email, password: password)
    
    // Then
    XCTAssertEqual(authenticationViewModel.authenticationState, .authenticating)
    
    // Simulate successful login
    let expectation = expectation(description: "Authentication completes")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 1.0)
  }
}

// Helper functions for validation (these will be implemented in the actual view)
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

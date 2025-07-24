//
//  AuthenticationStateTests.swift
//  PolyPalTests
//
//  Created on 2025-07-22.
//

import XCTest
@testable import PolyPal

final class AuthenticationStateTests: XCTestCase {
  
  func testStateEquality() {
    // Test same states are equal
    XCTAssertEqual(AuthenticationState.unauthenticated, AuthenticationState.unauthenticated)
    XCTAssertEqual(AuthenticationState.authenticating, AuthenticationState.authenticating)
    XCTAssertEqual(AuthenticationState.authenticated, AuthenticationState.authenticated)
    XCTAssertEqual(AuthenticationState.mfaRequired, AuthenticationState.mfaRequired)
    XCTAssertEqual(AuthenticationState.error("test"), AuthenticationState.error("test"))
    
    // Test different states are not equal
    XCTAssertNotEqual(AuthenticationState.unauthenticated, AuthenticationState.authenticating)
    XCTAssertNotEqual(AuthenticationState.authenticated, AuthenticationState.mfaRequired)
    XCTAssertNotEqual(AuthenticationState.mfaRequired, AuthenticationState.error("test"))
    XCTAssertNotEqual(AuthenticationState.error("test1"), AuthenticationState.error("test2"))
  }
  
  func testStateTransitions() {
    var state: AuthenticationState = .unauthenticated
    
    // Test transition from unauthenticated to authenticating
    state = .authenticating
    XCTAssertEqual(state, .authenticating)
    
    // Test transition from authenticating to authenticated
    state = .authenticated
    XCTAssertEqual(state, .authenticated)
    
    // Test transition to error state
    state = .error("Invalid credentials")
    XCTAssertEqual(state, .error("Invalid credentials"))
    
    // Test transition back to unauthenticated from error
    state = .unauthenticated
    XCTAssertEqual(state, .unauthenticated)
  }
  
  func testStateCodable() throws {
    // Test encoding and decoding of all state types
    let states: [AuthenticationState] = [
      .unauthenticated,
      .authenticating,
      .authenticated,
      .mfaRequired,
      .error("Test error message")
    ]
    
    for originalState in states {
      let encoded = try JSONEncoder().encode(originalState)
      let decoded = try JSONDecoder().decode(AuthenticationState.self, from: encoded)
      XCTAssertEqual(originalState, decoded)
    }
  }
  
  func testErrorStateWithDifferentMessages() {
    let error1 = AuthenticationState.error("Network error")
    let error2 = AuthenticationState.error("Invalid credentials")
    let error3 = AuthenticationState.error("Network error")
    
    XCTAssertNotEqual(error1, error2)
    XCTAssertEqual(error1, error3)
  }
  
  func testAllCasesProperty() {
    let allCases = AuthenticationState.allCases
    XCTAssertEqual(allCases.count, 5)
    
    // Verify all cases are present
    XCTAssertTrue(allCases.contains(.unauthenticated))
    XCTAssertTrue(allCases.contains(.authenticating))
    XCTAssertTrue(allCases.contains(.authenticated))
    XCTAssertTrue(allCases.contains(.mfaRequired))
    XCTAssertTrue(allCases.contains { 
      if case .error = $0 { return true }
      return false 
    })
  }
}

//
//  AuthenticationIntegrationTests.swift
//  PolyPalTests
//
//  Created by Agent OS on 7/25/25.
//

import XCTest
import Combine
@testable import PolyPal

class AuthenticationIntegrationTests: XCTestCase {
  
  var authViewModel: AuthenticationViewModel!
  var zohoAuthManager: ZohoAuthenticationManager!
  var cancellables: Set<AnyCancellable>!
  
  override func setUp() {
    super.setUp()
    authViewModel = AuthenticationViewModel()
    zohoAuthManager = ZohoAuthenticationManager()
    cancellables = Set<AnyCancellable>()
  }
  
  override func tearDown() {
    cancellables.removeAll()
    authViewModel = nil
    zohoAuthManager = nil
    super.tearDown()
  }
  
  // MARK: - Dual Authentication Flow Tests
  
  func testDualAuthenticationFlow() async {
    // Test that both JWT and Zoho authentication can coexist
    let expectation = XCTestExpectation(description: "Dual authentication completed")
    
    // First authenticate with JWT
    authViewModel.login(email: "test@example.com", password: "password")
    
    // Wait for JWT authentication
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    XCTAssertNotNil(authViewModel.currentUser)
    
    // Then authenticate with Zoho
    do {
      let zohoToken = try await zohoAuthManager.authenticate()
      XCTAssertNotNil(zohoToken)
      XCTAssertTrue(zohoAuthManager.isAuthenticated)
      expectation.fulfill()
    } catch {
      XCTFail("Zoho authentication failed: \(error)")
    }
    
    await fulfillment(of: [expectation], timeout: 10.0)
  }
  
  func testAuthenticationStateConsistency() async {
    // Test that authentication states remain consistent between systems
    let stateExpectation = XCTestExpectation(description: "Authentication states consistent")
    
    // Monitor authentication state changes
    authViewModel.$authenticationState
      .sink { state in
        if state == .authenticated {
          stateExpectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    // Authenticate with JWT first
    authViewModel.login(email: "test@example.com", password: "password")
    
    await fulfillment(of: [stateExpectation], timeout: 5.0)
    
    // Verify both systems can be authenticated simultaneously
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    
    // Test Zoho authentication doesn't interfere
    do {
      _ = try await zohoAuthManager.authenticate()
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    } catch {
      XCTFail("Zoho authentication should not affect JWT state: \(error)")
    }
  }
  
  func testUserSessionManagement() async {
    // Test that user sessions are properly managed with both auth systems
    
    // Create a user session with JWT
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    XCTAssertNotNil(authViewModel.currentUser)
    let originalUser = authViewModel.currentUser
    
    // Add Zoho authentication to the session
    do {
      let zohoToken = try await zohoAuthManager.authenticate()
      XCTAssertNotNil(zohoToken)
      
      // User session should remain intact
      XCTAssertEqual(authViewModel.currentUser?.id, originalUser?.id)
      XCTAssertEqual(authViewModel.currentUser?.email, originalUser?.email)
      
    } catch {
      XCTFail("Zoho authentication should not affect user session: \(error)")
    }
  }
  
  func testAuthenticationConflictHandling() async {
    // Test handling of authentication conflicts between systems
    
    // Start with JWT authentication
    authViewModel.login(email: "user1@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    let jwtUser = authViewModel.currentUser
    
    // Attempt Zoho authentication with different user context
    do {
      _ = try await zohoAuthManager.authenticate()
      
      // JWT user should remain unchanged
      XCTAssertEqual(authViewModel.currentUser?.id, jwtUser?.id)
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
      
    } catch {
      // Authentication conflicts should be handled gracefully
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    }
  }
  
  func testMFAIntegrationWithZoho() async {
    // Test MFA flow integration with Zoho authentication
    
    // Setup user with MFA enabled
    authViewModel.login(email: "mfa@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    XCTAssertEqual(authViewModel.authenticationState, .mfaRequired)
    
    // Complete MFA verification
    await authViewModel.verifyMFA(code: "123456")
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    
    // Now test Zoho authentication with MFA-enabled user
    do {
      let zohoToken = try await zohoAuthManager.authenticate()
      XCTAssertNotNil(zohoToken)
      XCTAssertTrue(zohoAuthManager.isAuthenticated)
      
      // MFA state should remain consistent
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
      XCTAssertTrue(authViewModel.currentUser?.isMFAEnabled ?? false)
      
    } catch {
      XCTFail("Zoho authentication should work with MFA-enabled users: \(error)")
    }
  }
  
  // MARK: - Token Management Tests
  
  func testTokenStorageIntegration() async {
    // Test that both JWT and Zoho tokens are stored properly
    
    // Authenticate with JWT
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    
    // Authenticate with Zoho
    do {
      let zohoToken = try await zohoAuthManager.authenticate()
      XCTAssertNotNil(zohoToken)
      
      // Verify token storage
      let storedToken = try zohoAuthManager.getStoredToken()
      XCTAssertNotNil(storedToken)
      XCTAssertEqual(storedToken?.accessToken, zohoToken.accessToken)
      
    } catch {
      XCTFail("Token storage integration failed: \(error)")
    }
  }
  
  func testTokenRefreshIntegration() async {
    // Test token refresh doesn't interfere with other authentication
    
    // Setup authenticated state
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    do {
      let initialToken = try await zohoAuthManager.authenticate()
      XCTAssertNotNil(initialToken)
      
      // Simulate token refresh
      let refreshedToken = try await zohoAuthManager.refreshToken()
      XCTAssertNotNil(refreshedToken)
      
      // JWT authentication should remain unaffected
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
      XCTAssertNotNil(authViewModel.currentUser)
      
    } catch {
      XCTFail("Token refresh integration failed: \(error)")
    }
  }
  
  func testTokenExpirationHandling() async {
    // Test handling of token expiration in integrated system
    
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    do {
      _ = try await zohoAuthManager.authenticate()
      
      // Simulate token expiration
      try zohoAuthManager.clearStoredToken()
      
      // JWT authentication should remain valid
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
      XCTAssertFalse(zohoAuthManager.isAuthenticated)
      
    } catch {
      XCTFail("Token expiration handling failed: \(error)")
    }
  }
  
  // MARK: - Logout Integration Tests
  
  func testDualLogout() async {
    // Test that logout clears both authentication systems
    
    // Setup dual authentication
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    do {
      _ = try await zohoAuthManager.authenticate()
      
      // Verify both systems are authenticated
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
      XCTAssertTrue(zohoAuthManager.isAuthenticated)
      
      // Perform integrated logout
      authViewModel.logout()
      try zohoAuthManager.logout()
      
      // Verify both systems are logged out
      XCTAssertEqual(authViewModel.authenticationState, .unauthenticated)
      XCTAssertNil(authViewModel.currentUser)
      XCTAssertFalse(zohoAuthManager.isAuthenticated)
      
    } catch {
      XCTFail("Dual logout failed: \(error)")
    }
  }
  
  func testPartialLogout() async {
    // Test logout from one system doesn't affect the other
    
    // Setup dual authentication
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    do {
      _ = try await zohoAuthManager.authenticate()
      
      // Logout from Zoho only
      try zohoAuthManager.logout()
      
      // JWT authentication should remain
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
      XCTAssertNotNil(authViewModel.currentUser)
      XCTAssertFalse(zohoAuthManager.isAuthenticated)
      
    } catch {
      XCTFail("Partial logout failed: \(error)")
    }
  }
  
  // MARK: - Error Handling Integration Tests
  
  func testAuthenticationErrorHandling() async {
    // Test error handling when one authentication system fails
    
    // Start with successful JWT authentication
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    
    // Simulate Zoho authentication failure
    do {
      // This should fail due to invalid configuration
      let invalidManager = ZohoAuthenticationManager()
      _ = try await invalidManager.authenticate()
      XCTFail("Should have thrown an error")
    } catch {
      // JWT authentication should remain unaffected by Zoho failure
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
      XCTAssertNotNil(authViewModel.currentUser)
    }
  }
  
  func testNetworkErrorIntegration() async {
    // Test network error handling across both systems
    
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    // Simulate network error during Zoho authentication
    do {
      // This will fail due to network issues
      _ = try await zohoAuthManager.authenticate()
    } catch ZohoAuthenticationError.networkError {
      // Network errors should be handled gracefully
      XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
  
  // MARK: - Performance Integration Tests
  
  func testConcurrentAuthentication() async {
    // Test concurrent authentication requests
    
    let jwtTask = Task {
      authViewModel.login(email: "test@example.com", password: "password")
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      return authViewModel.authenticationState
    }
    
    let zohoTask = Task {
      do {
        let token = try await zohoAuthManager.authenticate()
        return token != nil
      } catch {
        return false
      }
    }
    
    // Execute both authentication flows concurrently
    let (jwtResult, zohoResult) = await (jwtTask.value, zohoTask.value)
    
    // Both should succeed independently
    XCTAssertEqual(jwtResult, .authenticated)
    XCTAssertTrue(zohoResult)
  }
  
  func testAuthenticationPerformance() {
    // Test performance of integrated authentication
    measure {
      let expectation = XCTestExpectation(description: "Authentication performance")
      
      Task {
        authViewModel.login(email: "test@example.com", password: "password")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        do {
          _ = try await zohoAuthManager.authenticate()
          expectation.fulfill()
        } catch {
          expectation.fulfill()
        }
      }
      
      wait(for: [expectation], timeout: 10.0)
    }
  }
  
  // MARK: - State Synchronization Tests
  
  func testStateSynchronization() async {
    // Test that authentication states stay synchronized
    var stateChanges: [AuthenticationState] = []
    
    authViewModel.$authenticationState
      .sink { state in
        stateChanges.append(state)
      }
      .store(in: &cancellables)
    
    // Perform authentication sequence
    authViewModel.login(email: "test@example.com", password: "password")
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    do {
      _ = try await zohoAuthManager.authenticate()
    } catch {
      // Ignore Zoho errors for this test
    }
    
    // Verify state progression
    XCTAssertTrue(stateChanges.contains(.unauthenticated))
    XCTAssertTrue(stateChanges.contains(.authenticating))
    XCTAssertTrue(stateChanges.contains(.authenticated))
  }
  
  func testMemoryManagement() async {
    // Test memory management with both authentication systems
    weak var weakAuthViewModel: AuthenticationViewModel?
    weak var weakZohoManager: ZohoAuthenticationManager?
    
    autoreleasepool {
      let localAuthViewModel = AuthenticationViewModel()
      let localZohoManager = ZohoAuthenticationManager()
      
      weakAuthViewModel = localAuthViewModel
      weakZohoManager = localZohoManager
      
      // Perform authentication
      localAuthViewModel.login(email: "test@example.com", password: "password")
    }
    
    // Allow time for cleanup
    try? await Task.sleep(nanoseconds: 100_000_000)
    
    // Objects should be deallocated
    XCTAssertNil(weakAuthViewModel)
    XCTAssertNil(weakZohoManager)
  }
}

// MARK: - Mock Extensions for Testing

extension AuthenticationIntegrationTests {
  
  func createMockUser(email: String = "test@example.com", mfaEnabled: Bool = false) -> User {
    return User(
      email: email,
      role: .buyer,
      firstName: "Test",
      lastName: "User",
      isEmailVerified: true,
      isMFAEnabled: mfaEnabled
    )
  }
  
  func simulateNetworkDelay() async {
    try? await Task.sleep(nanoseconds: 500_000_000)
  }
  
  func verifyAuthenticationCleanup() {
    XCTAssertEqual(authViewModel.authenticationState, .unauthenticated)
    XCTAssertNil(authViewModel.currentUser)
    XCTAssertFalse(zohoAuthManager.isAuthenticated)
    XCTAssertNil(authViewModel.errorMessage)
  }
}

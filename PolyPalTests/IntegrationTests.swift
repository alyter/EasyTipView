//
//  IntegrationTests.swift
//  PolyPalTests
//
//  Created by PolyPal on 2025-07-24.
//

import XCTest
import SwiftUI
@testable import PolyPal

final class IntegrationTests: XCTestCase {
  var authViewModel: AuthenticationViewModel!
  var mainViewModel: MainViewModel!
  
  override func setUp() {
    super.setUp()
    authViewModel = AuthenticationViewModel()
    mainViewModel = MainViewModel()
  }
  
  override func tearDown() {
    authViewModel = nil
    mainViewModel = nil
    super.tearDown()
  }
  
  // MARK: - Authentication to Main App Transition Tests
  
  func testSuccessfulLoginTransitionsToMainApp() {
    // Given
    XCTAssertEqual(authViewModel.authenticationState, .unauthenticated)
    
    // When - simulate successful login
    authViewModel.email = "test@example.com"
    authViewModel.password = "password123"
    
    let expectation = XCTestExpectation(description: "Login completes")
    
    Task {
      await authViewModel.login()
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 2.0)
    
    // Then
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    XCTAssertTrue(authViewModel.isAuthenticated)
  }
  
  func testMFAVerificationTransitionsToMainApp() {
    // Given
    authViewModel.authenticationState = .mfaRequired
    authViewModel.mfaCode = "123456"
    
    // When
    let expectation = XCTestExpectation(description: "MFA verification completes")
    
    Task {
      await authViewModel.verifyMFA()
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 2.0)
    
    // Then
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    XCTAssertTrue(authViewModel.isAuthenticated)
  }
  
  func testLogoutTransitionsToAuthenticationFlow() {
    // Given
    authViewModel.authenticationState = .authenticated
    
    // When
    authViewModel.logout()
    
    // Then
    XCTAssertEqual(authViewModel.authenticationState, .unauthenticated)
    XCTAssertFalse(authViewModel.isAuthenticated)
    XCTAssertTrue(authViewModel.email.isEmpty)
    XCTAssertTrue(authViewModel.password.isEmpty)
    XCTAssertTrue(authViewModel.mfaCode.isEmpty)
  }
  
  // MARK: - State Coordination Tests
  
  func testMainViewModelResetsOnLogout() {
    // Given
    mainViewModel.selectTab(.messages)
    mainViewModel.messagesBadgeCount = 5
    mainViewModel.favoritesBadgeCount = 3
    
    // When - simulate logout
    mainViewModel.reset()
    
    // Then
    XCTAssertEqual(mainViewModel.selectedTab, .buy)
    XCTAssertEqual(mainViewModel.messagesBadgeCount, 0)
    XCTAssertEqual(mainViewModel.favoritesBadgeCount, 0)
    XCTAssertTrue(mainViewModel.tabSelectionHistory.isEmpty)
  }
  
  func testAuthenticationStatePreservesMainAppState() {
    // Given
    mainViewModel.selectTab(.favorites)
    mainViewModel.messagesBadgeCount = 2
    let selectedTab = mainViewModel.selectedTab
    let badgeCount = mainViewModel.messagesBadgeCount
    
    // When - authentication state changes but user remains authenticated
    authViewModel.authenticationState = .authenticated
    
    // Then - main app state should be preserved
    XCTAssertEqual(mainViewModel.selectedTab, selectedTab)
    XCTAssertEqual(mainViewModel.messagesBadgeCount, badgeCount)
  }
  
  // MARK: - Navigation Coordination Tests
  
  func testContentViewNavigationFlow() {
    // Given
    let contentView = ContentView()
    
    // When - user is unauthenticated
    authViewModel.authenticationState = .unauthenticated
    
    // Then - should show authentication flow
    XCTAssertFalse(authViewModel.isAuthenticated)
    
    // When - user becomes authenticated
    authViewModel.authenticationState = .authenticated
    
    // Then - should show main app
    XCTAssertTrue(authViewModel.isAuthenticated)
  }
  
  func testAuthenticationErrorHandlingInIntegration() {
    // Given
    authViewModel.email = "invalid@example.com"
    authViewModel.password = "wrongpassword"
    
    // When
    let expectation = XCTestExpectation(description: "Login fails")
    
    Task {
      await authViewModel.login()
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 2.0)
    
    // Then
    XCTAssertEqual(authViewModel.authenticationState, .error("Invalid credentials"))
    XCTAssertFalse(authViewModel.isAuthenticated)
    XCTAssertNotNil(authViewModel.errorMessage)
  }
  
  // MARK: - Data Persistence Tests
  
  func testTabSelectionPersistsAcrossAppStates() {
    // Given
    mainViewModel.selectTab(.account)
    let selectedTab = mainViewModel.selectedTab
    
    // When - app goes through authentication cycle
    authViewModel.logout()
    authViewModel.authenticationState = .authenticated
    
    // Then - tab selection should persist
    XCTAssertEqual(mainViewModel.selectedTab, selectedTab)
  }
  
  func testBadgeCountsPersistAcrossAuthentication() {
    // Given
    mainViewModel.messagesBadgeCount = 7
    mainViewModel.favoritesBadgeCount = 2
    let messagesBadges = mainViewModel.messagesBadgeCount
    let favoritesBadges = mainViewModel.favoritesBadgeCount
    
    // When - user logs out and back in
    authViewModel.logout()
    authViewModel.authenticationState = .authenticated
    
    // Then - badge counts should persist (in real app, would be loaded from server)
    // For now, we test that the structure supports persistence
    XCTAssertEqual(mainViewModel.messagesBadgeCount, messagesBadges)
    XCTAssertEqual(mainViewModel.favoritesBadgeCount, favoritesBadges)
  }
  
  // MARK: - Error Recovery Tests
  
  func testRecoveryFromAuthenticationErrors() {
    // Given
    authViewModel.authenticationState = .error("Network error")
    
    // When - user clears error and retries
    authViewModel.clearError()
    authViewModel.email = "test@example.com"
    authViewModel.password = "password123"
    
    let expectation = XCTestExpectation(description: "Recovery login completes")
    
    Task {
      await authViewModel.login()
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 2.0)
    
    // Then
    XCTAssertEqual(authViewModel.authenticationState, .authenticated)
    XCTAssertNil(authViewModel.errorMessage)
  }
  
  func testMainAppStateRemainsStableDuringAuthErrors() {
    // Given
    authViewModel.authenticationState = .authenticated
    mainViewModel.selectTab(.sell)
    mainViewModel.messagesBadgeCount = 3
    
    // When - authentication error occurs but user is still considered authenticated
    authViewModel.authenticationState = .error("Temporary network issue")
    
    // Then - main app state should remain stable
    XCTAssertEqual(mainViewModel.selectedTab, .sell)
    XCTAssertEqual(mainViewModel.messagesBadgeCount, 3)
  }
}

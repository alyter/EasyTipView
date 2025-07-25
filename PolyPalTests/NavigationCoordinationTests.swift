//
//  NavigationCoordinationTests.swift
//  PolyPalTests
//
//  Created on 2025-07-22.
//

import XCTest
import SwiftUI
@testable import PolyPal

final class NavigationCoordinationTests: XCTestCase {
    var authViewModel: AuthenticationViewModel!
    
    override func setUp() {
        super.setUp()
        authViewModel = AuthenticationViewModel()
    }
    
    override func tearDown() {
        authViewModel = nil
        super.tearDown()
    }
    
    func testInitialNavigationState() {
        XCTAssertEqual(authViewModel.navigationState, .welcome)
    }
    
    func testNavigationToLogin() {
        authViewModel.navigateToLogin()
        XCTAssertEqual(authViewModel.navigationState, .login)
    }
    
    func testNavigationToRegister() {
        authViewModel.navigateToRegister()
        XCTAssertEqual(authViewModel.navigationState, .register)
    }
    
    func testNavigationToPasswordReset() {
        authViewModel.navigateToPasswordReset()
        XCTAssertEqual(authViewModel.navigationState, .passwordReset)
    }
    
    func testNavigationToMFA() {
        authViewModel.navigateToMFA()
        XCTAssertEqual(authViewModel.navigationState, .mfa)
    }
    
    func testNavigationFromRegisterToLogin() {
        // Start from register state
        authViewModel.navigateToRegister()
        XCTAssertEqual(authViewModel.navigationState, .register)
        
        // Navigate to login
        authViewModel.navigateToLogin()
        XCTAssertEqual(authViewModel.navigationState, .login)
    }
    
    func testNavigationFromMFAToLogin() {
        // Setup MFA state
        authViewModel.navigateToMFA()
        XCTAssertEqual(authViewModel.navigationState, .mfa)
        
        // Navigate to login
        authViewModel.navigateToLogin()
        XCTAssertEqual(authViewModel.navigationState, .login)
    }
    
    func testNavigationFromPasswordResetToLogin() {
        // Setup password reset state
        authViewModel.navigateToPasswordReset()
        XCTAssertEqual(authViewModel.navigationState, .passwordReset)
        
        // Navigate to login
        authViewModel.navigateToLogin()
        XCTAssertEqual(authViewModel.navigationState, .login)
    }
    
    func testNavigationStateChangesResetAuthenticationState() {
        // Set an error state
        authViewModel.authenticationState = .error("Some error")
        
        // Navigate to a different state
        authViewModel.navigateToLogin()
        
        // Should reset authentication state
        XCTAssertEqual(authViewModel.authenticationState, .unauthenticated)
    }
    
    func testNavigationFlow() {
        // Test a complete navigation flow
        authViewModel.navigateToLogin()
        XCTAssertEqual(authViewModel.navigationState, .login)
        
        authViewModel.navigateToRegister()
        XCTAssertEqual(authViewModel.navigationState, .register)
        
        authViewModel.navigateToLogin()
        XCTAssertEqual(authViewModel.navigationState, .login)
        
        authViewModel.navigateToPasswordReset()
        XCTAssertEqual(authViewModel.navigationState, .passwordReset)
        
        authViewModel.navigateToLogin()
        XCTAssertEqual(authViewModel.navigationState, .login)
    }
    
    func testNavigationConsistency() {
        // Test that navigation state is consistent across multiple changes
        let states: [AuthenticationViewModel.NavigationState] = [.welcome, .login, .register, .passwordReset, .mfa]
        
        for state in states {
            authViewModel.navigationState = state
            XCTAssertEqual(authViewModel.navigationState, state)
        }
    }
    
    func testNavigationStateProperty() {
        // Test that navigationState property works correctly
        authViewModel.navigationState = .register
        XCTAssertEqual(authViewModel.navigationState, .register)
        
        authViewModel.navigationState = .passwordReset
        XCTAssertEqual(authViewModel.navigationState, .passwordReset)
        
        authViewModel.navigationState = .mfa
        XCTAssertEqual(authViewModel.navigationState, .mfa)
    }
    
    func testNavigationFromWelcome() {
        // Test navigation from welcome state
        XCTAssertEqual(authViewModel.navigationState, .welcome)
        
        authViewModel.navigateToLogin()
        XCTAssertEqual(authViewModel.navigationState, .login)
        
        // Reset to welcome
        authViewModel.navigationState = .welcome
        
        authViewModel.navigateToRegister()
        XCTAssertEqual(authViewModel.navigationState, .register)
    }
}

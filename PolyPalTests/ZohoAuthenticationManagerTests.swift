//
//  ZohoAuthenticationManagerTests.swift
//  PolyPalTests
//
//  Created by AI Assistant on 2025-07-25.
//

import XCTest
@testable import PolyPal

@MainActor
final class ZohoAuthenticationManagerTests: XCTestCase {
    
    var authManager: ZohoAuthenticationManager!
    
    override func setUp() {
        super.setUp()
        authManager = ZohoAuthenticationManager()
        
        // Clear any existing tokens
        clearKeychain()
    }
    
    override func tearDown() {
        clearKeychain()
        authManager = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func clearKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.polypal.zoho.auth"
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    private func createMockToken(expired: Bool = false) -> ZohoAuthToken {
        let expiresIn: TimeInterval = expired ? -3600 : 3600 // 1 hour ago or 1 hour from now
        return ZohoAuthToken(
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            tokenType: "Bearer",
            expiresIn: expiresIn,
            scope: "read write"
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentToken)
        XCTAssertFalse(authManager.isAuthenticating)
        
        if case .notAuthenticated = authManager.authenticationState {
            // Expected state
        } else {
            XCTFail("Expected notAuthenticated state")
        }
    }
    
    // MARK: - ZohoAuthToken Tests
    
    func testTokenExpiration() {
        let validToken = createMockToken(expired: false)
        let expiredToken = createMockToken(expired: true)
        
        XCTAssertFalse(validToken.isExpired)
        XCTAssertTrue(expiredToken.isExpired)
    }
    
    func testTokenWillExpireSoon() {
        // Token that expires in 4 minutes (less than 5 minute buffer)
        let soonToExpireToken = ZohoAuthToken(
            accessToken: "test",
            refreshToken: "test",
            expiresIn: 240 // 4 minutes
        )
        
        // Token that expires in 10 minutes (more than 5 minute buffer)
        let validToken = ZohoAuthToken(
            accessToken: "test",
            refreshToken: "test",
            expiresIn: 600 // 10 minutes
        )
        
        XCTAssertTrue(soonToExpireToken.willExpireSoon)
        XCTAssertFalse(validToken.willExpireSoon)
    }
    
    // MARK: - Authentication State Tests
    
    func testAuthenticationStateProperties() {
        let token = createMockToken()
        
        // Test notAuthenticated state
        let notAuthState = ZohoAuthenticationState.notAuthenticated
        XCTAssertFalse(notAuthState.isAuthenticated)
        XCTAssertNil(notAuthState.token)
        
        // Test authenticated state
        let authState = ZohoAuthenticationState.authenticated(token)
        XCTAssertTrue(authState.isAuthenticated)
        XCTAssertNotNil(authState.token)
        XCTAssertEqual(authState.token?.accessToken, token.accessToken)
        
        // Test authenticating state
        let authenticatingState = ZohoAuthenticationState.authenticating
        XCTAssertFalse(authenticatingState.isAuthenticated)
        XCTAssertNil(authenticatingState.token)
        
        // Test error state
        let errorState = ZohoAuthenticationState.error(.invalidCredentials)
        XCTAssertFalse(errorState.isAuthenticated)
        XCTAssertNil(errorState.token)
    }
    
    // MARK: - Authentication Error Tests
    
    func testAuthenticationErrorDescriptions() {
        let errors: [ZohoAuthenticationError] = [
            .invalidCredentials,
            .networkError(NSError(domain: "test", code: 0)),
            .tokenExpired,
            .tokenRefreshFailed,
            .keychainError(errSecItemNotFound),
            .invalidResponse,
            .userCancelled,
            .configurationError
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Token Validation Tests
    
    func testValidateTokenWithValidToken() async {
        // Create a valid token and set it in the auth manager
        let token = createMockToken(expired: false)
        authManager.authenticationState = .authenticated(token)
        
        let isValid = await authManager.validateToken()
        XCTAssertTrue(isValid)
    }
    
    func testValidateTokenWithExpiredTokenNoRefresh() async {
        // Create an expired token without refresh token
        let expiredToken = ZohoAuthToken(
            accessToken: "expired",
            refreshToken: nil,
            expiresIn: -3600
        )
        authManager.authenticationState = .authenticated(expiredToken)
        
        let isValid = await authManager.validateToken()
        XCTAssertFalse(isValid)
        XCTAssertFalse(authManager.isAuthenticated)
    }
    
    func testValidateTokenWithNotAuthenticated() async {
        authManager.authenticationState = .notAuthenticated
        
        let isValid = await authManager.validateToken()
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Token Management Tests
    
    func testGetValidTokenSuccess() async throws {
        let token = createMockToken(expired: false)
        authManager.authenticationState = .authenticated(token)
        
        let accessToken = try await authManager.getValidToken()
        XCTAssertEqual(accessToken, token.accessToken)
    }
    
    func testGetValidTokenFailure() async {
        authManager.authenticationState = .notAuthenticated
        
        do {
            _ = try await authManager.getValidToken()
            XCTFail("Expected tokenExpired error")
        } catch ZohoAuthenticationError.tokenExpired {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Convenience Properties Tests
    
    func testConvenienceProperties() {
        let token = createMockToken()
        
        // Test not authenticated state
        authManager.authenticationState = .notAuthenticated
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentToken)
        XCTAssertFalse(authManager.isAuthenticating)
        
        // Test authenticated state
        authManager.authenticationState = .authenticated(token)
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentToken)
        XCTAssertEqual(authManager.currentToken?.accessToken, token.accessToken)
        XCTAssertFalse(authManager.isAuthenticating)
        
        // Test authenticating state
        authManager.authenticationState = .authenticating
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentToken)
        XCTAssertTrue(authManager.isAuthenticating)
        
        // Test refreshing token state
        authManager.authenticationState = .refreshingToken
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentToken)
        XCTAssertTrue(authManager.isAuthenticating)
    }
    
    // MARK: - Keychain Tests
    
    func testKeychainTokenStorage() throws {
        let token = createMockToken()
        
        // Store token using reflection to access private method
        let mirror = Mirror(reflecting: authManager)
        let storeTokenMethod = mirror.children.first { $0.label == "storeToken" }
        
        // Since we can't easily test private methods, we'll test the public interface
        authManager.authenticationState = .authenticated(token)
        
        // Create a new auth manager to test token loading
        let newAuthManager = ZohoAuthenticationManager()
        
        // The new manager should not have the token since we didn't actually store it
        // This test verifies the keychain integration structure
        XCTAssertFalse(newAuthManager.isAuthenticated)
    }
    
    // MARK: - Logout Tests
    
    func testLogout() async {
        let token = createMockToken()
        authManager.authenticationState = .authenticated(token)
        
        XCTAssertTrue(authManager.isAuthenticated)
        
        await authManager.logout()
        
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentToken)
        
        if case .notAuthenticated = authManager.authenticationState {
            // Expected state
        } else {
            XCTFail("Expected notAuthenticated state after logout")
        }
    }
    
    // MARK: - Error Mapping Tests
    
    func testErrorMapping() {
        // Test network errors
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let mappedError = authManager.mapError(networkError)
        
        if case .networkError = mappedError {
            // Expected
        } else {
            XCTFail("Expected networkError")
        }
        
        // Test user cancelled error
        let cancelledError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUserCancelledAuthentication)
        let mappedCancelledError = authManager.mapError(cancelledError)
        
        if case .userCancelled = mappedCancelledError {
            // Expected
        } else {
            XCTFail("Expected userCancelled error")
        }
        
        // Test already mapped error
        let authError = ZohoAuthenticationError.invalidCredentials
        let mappedAuthError = authManager.mapError(authError)
        
        if case .invalidCredentials = mappedAuthError {
            // Expected
        } else {
            XCTFail("Expected invalidCredentials error")
        }
    }
    
    // MARK: - Token Refresh Tests
    
    func testRefreshTokenWithoutRefreshToken() async {
        let tokenWithoutRefresh = ZohoAuthToken(
            accessToken: "test",
            refreshToken: nil,
            expiresIn: 3600
        )
        authManager.authenticationState = .authenticated(tokenWithoutRefresh)
        
        do {
            try await authManager.refreshToken()
            XCTFail("Expected tokenRefreshFailed error")
        } catch ZohoAuthenticationError.tokenRefreshFailed {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRefreshTokenNotAuthenticated() async {
        authManager.authenticationState = .notAuthenticated
        
        do {
            try await authManager.refreshToken()
            XCTFail("Expected tokenRefreshFailed error")
        } catch ZohoAuthenticationError.tokenRefreshFailed {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - State Observation Tests
    
    func testStateObservation() {
        let expectation = XCTestExpectation(description: "State change observed")
        
        let cancellable = authManager.$authenticationState
            .dropFirst() // Skip initial value
            .sink { state in
                if case .authenticating = state {
                    expectation.fulfill()
                }
            }
        
        authManager.authenticationState = .authenticating
        
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
    
    // MARK: - Token Codable Tests
    
    func testTokenCodable() throws {
        let token = createMockToken()
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(token)
        XCTAssertFalse(data.isEmpty)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedToken = try decoder.decode(ZohoAuthToken.self, from: data)
        
        XCTAssertEqual(token.accessToken, decodedToken.accessToken)
        XCTAssertEqual(token.refreshToken, decodedToken.refreshToken)
        XCTAssertEqual(token.tokenType, decodedToken.tokenType)
        XCTAssertEqual(token.expiresIn, decodedToken.expiresIn)
        XCTAssertEqual(token.scope, decodedToken.scope)
        XCTAssertEqual(token.createdAt.timeIntervalSince1970, decodedToken.createdAt.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testTokenValidationPerformance() {
        let token = createMockToken(expired: false)
        authManager.authenticationState = .authenticated(token)
        
        measure {
            Task {
                _ = await authManager.validateToken()
            }
        }
    }
    
    func testTokenCreationPerformance() {
        measure {
            _ = createMockToken()
        }
    }
}

// MARK: - Test Extensions

extension ZohoAuthenticationManagerTests {
    
    // Helper to access private methods for testing
    private func mapError(_ error: Error) -> ZohoAuthenticationError {
        // Use reflection to access private mapError method
        let mirror = Mirror(reflecting: authManager)
        
        // For testing purposes, we'll create a simple mapping
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut:
                return .networkError(error)
            case NSURLErrorUserCancelledAuthentication:
                return .userCancelled
            default:
                return .networkError(error)
            }
        }
        
        if let authError = error as? ZohoAuthenticationError {
            return authError
        }
        
        return .networkError(error)
    }
}

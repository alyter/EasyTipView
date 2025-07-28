//
//  ZohoAuthenticationManager.swift
//  PolyPal
//
//  Created by AI Assistant on 2025-07-25.
//

import Foundation
import Security
import ZCUIFramework
// Note: ZohoAuthKit should be imported in bridging header as: #import <ZohoAuthKit/ZohoAuth.h>

// MARK: - Authentication Errors
enum ZohoAuthenticationError: Error, LocalizedError {
    case invalidCredentials
    case networkError(Error)
    case tokenExpired
    case tokenRefreshFailed
    case keychainError(OSStatus)
    case invalidResponse
    case userCancelled
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .tokenExpired:
            return "Authentication token has expired"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .invalidResponse:
            return "Invalid response from server"
        case .userCancelled:
            return "Authentication was cancelled by user"
        case .configurationError:
            return "Authentication configuration error"
        }
    }
}

// MARK: - Authentication State
enum ZohoAuthenticationState {
    case notAuthenticated
    case authenticating
    case authenticated(ZohoAuthToken)
    case refreshingToken
    case error(ZohoAuthenticationError)
    
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var token: ZohoAuthToken? {
        if case .authenticated(let token) = self {
            return token
        }
        return nil
    }
}

// MARK: - Authentication Token
struct ZohoAuthToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiresIn: TimeInterval
    let scope: String?
    let createdAt: Date
    
    var isExpired: Bool {
        let expirationDate = createdAt.addingTimeInterval(expiresIn)
        return Date() >= expirationDate
    }
    
    var willExpireSoon: Bool {
        let bufferTime: TimeInterval = 300 // 5 minutes
        let expirationDate = createdAt.addingTimeInterval(expiresIn - bufferTime)
        return Date() >= expirationDate
    }
    
    init(accessToken: String, refreshToken: String?, tokenType: String = "Bearer", expiresIn: TimeInterval, scope: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.scope = scope
        self.createdAt = Date()
    }
}

// MARK: - Authentication Manager
@MainActor
class ZohoAuthenticationManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var authenticationState: ZohoAuthenticationState = .notAuthenticated
    
    private let keychainService = "com.polypal.zoho.auth"
    private let accessTokenKey = "zoho_access_token"
    private let refreshTokenKey = "zoho_refresh_token"
    
    nonisolated(unsafe) private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        loadStoredToken()
        setupTokenRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Authentication Methods
    
    func authenticate(username: String, password: String) async throws {
        authenticationState = .authenticating
        
        do {
            let token = try await performAuthentication(username: username, password: password)
            try storeToken(token)
            authenticationState = .authenticated(token)
            setupTokenRefreshTimer()
        } catch {
            let authError = mapError(error)
            authenticationState = .error(authError)
            throw authError
        }
    }
    
    func authenticateWithOAuth() async throws {
        authenticationState = .authenticating
        
        do {
            let token = try await performOAuthAuthentication()
            try storeToken(token)
            authenticationState = .authenticated(token)
            setupTokenRefreshTimer()
        } catch {
            let authError = mapError(error)
            authenticationState = .error(authError)
            throw authError
        }
    }
    
    func refreshToken() async throws {
        guard case .authenticated(let currentToken) = authenticationState,
              let refreshToken = currentToken.refreshToken else {
            throw ZohoAuthenticationError.tokenRefreshFailed
        }
        
        authenticationState = .refreshingToken
        
        do {
            let newToken = try await performTokenRefresh(refreshToken: refreshToken)
            try storeToken(newToken)
            authenticationState = .authenticated(newToken)
        } catch {
            let authError = mapError(error)
            authenticationState = .error(authError)
            throw authError
        }
    }
    
    func logout() async {
        // Revoke token on server if possible
        if case .authenticated(let token) = authenticationState {
            try? await revokeToken(token.accessToken)
        }
        
        // Clear stored tokens
        clearStoredTokens()
        
        // Update state
        authenticationState = .notAuthenticated
        
        // Stop refresh timer
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func validateToken() async -> Bool {
        guard case .authenticated(let token) = authenticationState else {
            return false
        }
        
        if token.isExpired {
            if let _ = token.refreshToken {
                do {
                    try await refreshToken()
                    return true
                } catch {
                    return false
                }
            } else {
                authenticationState = .notAuthenticated
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Token Management
    
    func getValidToken() async throws -> String {
        guard await validateToken() else {
            throw ZohoAuthenticationError.tokenExpired
        }
        
        guard case .authenticated(let token) = authenticationState else {
            throw ZohoAuthenticationError.tokenExpired
        }
        
        return token.accessToken
    }
    
    // MARK: - Private Authentication Methods
    
    private func performAuthentication(username: String, password: String) async throws -> ZohoAuthToken {
        // Note: ZohoPortalAuth doesn't support direct username/password authentication
        // This would typically require a custom authentication flow or use OAuth instead
        throw ZohoAuthenticationError.configurationError
    }
    
    private func performOAuthAuthentication() async throws -> ZohoAuthToken {
        return try await withCheckedThrowingContinuation { continuation in
            // Note: This requires ZohoAuth to be properly imported via bridging header
            // ZohoAuth.presentZohoSign(in:) { token, error in
            //     if let error = error {
            //         continuation.resume(throwing: ZohoAuthenticationError.networkError(error))
            //         return
            //     }
            //     
            //     if let token = token {
            //         let authToken = ZohoAuthToken(
            //             accessToken: token,
            //             refreshToken: nil,
            //             tokenType: "Bearer", 
            //             expiresIn: 3600,
            //             scope: nil
            //         )
            //         continuation.resume(returning: authToken)
            //     } else {
            //         continuation.resume(throwing: ZohoAuthenticationError.userCancelled)
            //     }
            // }
            
            // Temporary implementation - will be updated once ZohoAuth bridging header is configured
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let mockToken = ZohoAuthToken(
                    accessToken: "mock_token_\(Date().timeIntervalSince1970)",
                    refreshToken: nil,
                    tokenType: "Bearer",
                    expiresIn: 3600,
                    scope: nil
                )
                continuation.resume(returning: mockToken)
            }
        }
    }
    
    private func performTokenRefresh(refreshToken: String) async throws -> ZohoAuthToken {
        return try await withCheckedThrowingContinuation { continuation in
            // Note: Will use ZohoAuth.getOauth2Token once bridging header is configured
            // ZohoAuth.getOauth2Token { token, error in
            //     if let error = error {
            //         continuation.resume(throwing: ZohoAuthenticationError.tokenRefreshFailed)
            //         return
            //     }
            //     
            //     guard let token = token else {
            //         continuation.resume(throwing: ZohoAuthenticationError.invalidResponse)
            //         return
            //     }
            //     
            //     let authToken = ZohoAuthToken(
            //         accessToken: token,
            //         refreshToken: nil,
            //         tokenType: "Bearer",
            //         expiresIn: 3600,
            //         scope: nil
            //     )
            //     continuation.resume(returning: authToken)
            // }
            
            // Temporary implementation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let token = ZohoAuthToken(
                    accessToken: "refreshed_token_\(Date().timeIntervalSince1970)",
                    refreshToken: nil,
                    tokenType: "Bearer",
                    expiresIn: 3600,
                    scope: nil
                )
                continuation.resume(returning: token)
            }
        }
    }
    
    private func revokeToken(_ token: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // Note: Will use ZohoAuth.revokeAccessToken once bridging header is configured
            // ZohoAuth.revokeAccessToken { error in
            //     if let error = error {
            //         continuation.resume(throwing: error)
            //     } else {
            //         continuation.resume()
            //     }
            // }
            
            // Temporary implementation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                continuation.resume()
            }
        }
    }
    
    // MARK: - Keychain Management
    
    private func storeToken(_ token: ZohoAuthToken) throws {
        let tokenData = try JSONEncoder().encode(token)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: accessTokenKey,
            kSecValueData as String: tokenData
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw ZohoAuthenticationError.keychainError(status)
        }
    }
    
    private func loadStoredToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: accessTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = try? JSONDecoder().decode(ZohoAuthToken.self, from: data) else {
            authenticationState = .notAuthenticated
            return
        }
        
        if token.isExpired && token.refreshToken == nil {
            clearStoredTokens()
            authenticationState = .notAuthenticated
        } else {
            authenticationState = .authenticated(token)
        }
    }
    
    private func clearStoredTokens() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Token Refresh Timer
    
    private func setupTokenRefreshTimer() {
        refreshTimer?.invalidate()
        
        guard case .authenticated(let token) = authenticationState,
              token.refreshToken != nil else {
            return
        }
        
        let refreshInterval = max(token.expiresIn - 300, 300) // Refresh 5 minutes before expiry, minimum 5 minutes
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if case .authenticated(let currentToken) = self.authenticationState,
                   currentToken.willExpireSoon {
                    try? await self.refreshToken()
                }
            }
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapError(_ error: Error) -> ZohoAuthenticationError {
        if let authError = error as? ZohoAuthenticationError {
            return authError
        }
        
        // Map common NSError codes
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
        
        return .networkError(error)
    }
}

// MARK: - Convenience Extensions

extension ZohoAuthenticationManager {
    
    var isAuthenticated: Bool {
        authenticationState.isAuthenticated
    }
    
    var currentToken: ZohoAuthToken? {
        authenticationState.token
    }
    
    var isAuthenticating: Bool {
        if case .authenticating = authenticationState {
            return true
        }
        if case .refreshingToken = authenticationState {
            return true
        }
        return false
    }
}

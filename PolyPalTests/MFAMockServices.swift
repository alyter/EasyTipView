import Foundation
import CryptoKit
@testable import PolyPal

// MARK: - Mock MFA Manager

/// Mock MFA Manager for testing purposes
class MockMFAManager: MFAManager {
  
  var shouldGenerateValidTOTP = true
  var shouldValidateTOTP = true
  var generatedSecrets: [String] = []
  var validationAttempts: [(code: String, secret: String)] = []
  var mockSecretKey = "JBSWY3DPEHPK3PXP"
  
  override func generateSecretKey() -> String {
    let secret = shouldGenerateValidTOTP ? mockSecretKey : "INVALID"
    generatedSecrets.append(secret)
    return secret
  }
  
  override func generateTOTP(secret: String, timeInterval: TimeInterval? = nil) -> String {
    if shouldGenerateValidTOTP {
      return "123456"
    } else {
      return "000000"
    }
  }
  
  override func validateTOTP(_ code: String, secret: String, timeInterval: TimeInterval? = nil) -> Bool {
    validationAttempts.append((code: code, secret: secret))
    return shouldValidateTOTP && code == "123456"
  }
  
  func reset() {
    shouldGenerateValidTOTP = true
    shouldValidateTOTP = true
    generatedSecrets.removeAll()
    validationAttempts.removeAll()
  }
}

// MARK: - Mock Backup Code Manager

/// Mock Backup Code Manager for testing purposes
class MockBackupCodeManager: BackupCodeManager {
  
  var shouldGenerateValidCodes = true
  var shouldValidateCode = true
  var mockBackupCodes = ["ABC123", "DEF456", "GHI789", "JKL012", "MNO345"]
  var storedCodes: [String: [String]] = [:]
  var usedCodes: [String: Set<String>] = [:]
  var generationAttempts = 0
  var validationAttempts: [(code: String, userId: String)] = []
  
  override func generateBackupCodes() -> [String] {
    generationAttempts += 1
    return shouldGenerateValidCodes ? mockBackupCodes : []
  }
  
  override func storeBackupCodes(_ codes: [String], for userId: String) {
    storedCodes[userId] = codes
    usedCodes[userId] = Set<String>()
  }
  
  override func validateBackupCode(_ code: String, for userId: String) -> Bool {
    validationAttempts.append((code: code, userId: userId))
    
    guard shouldValidateCode,
          let codes = storedCodes[userId],
          codes.contains(code),
          !(usedCodes[userId]?.contains(code) ?? false) else {
      return false
    }
    
    usedCodes[userId]?.insert(code)
    return true
  }
  
  override func getStoredBackupCodes(for userId: String) -> [String]? {
    return storedCodes[userId]
  }
  
  override func getRemainingBackupCodeCount(for userId: String) -> Int {
    guard let codes = storedCodes[userId] else { return 0 }
    let used = usedCodes[userId] ?? Set<String>()
    return codes.count - used.count
  }
  
  override func regenerateBackupCodes(for userId: String) -> [String] {
    let newCodes = generateBackupCodes()
    storeBackupCodes(newCodes, for: userId)
    return newCodes
  }
  
  func reset() {
    shouldGenerateValidCodes = true
    shouldValidateCode = true
    storedCodes.removeAll()
    usedCodes.removeAll()
    generationAttempts = 0
    validationAttempts.removeAll()
  }
}

// MARK: - Mock QR Code Manager

/// Mock QR Code Manager for testing purposes
class MockQRCodeManager: QRCodeManager {
  
  var shouldGenerateQRCode = true
  var shouldGenerateURL = true
  var qrCodeGenerationAttempts = 0
  var urlGenerationAttempts = 0
  var lastGeneratedURL: String?
  
  override func generateQRCode(for secret: String, accountName: String, issuer: String) -> Data? {
    qrCodeGenerationAttempts += 1
    
    if shouldGenerateQRCode {
      // Return mock QR code data
      return "Mock QR Code Data".data(using: .utf8)
    } else {
      return nil
    }
  }
  
  override func generateOTPAuthURL(secret: String, accountName: String, issuer: String) -> String {
    urlGenerationAttempts += 1
    
    if shouldGenerateURL {
      let url = "otpauth://totp/\(issuer):\(accountName)?secret=\(secret)&issuer=\(issuer)"
      lastGeneratedURL = url
      return url
    } else {
      return ""
    }
  }
  
  func reset() {
    shouldGenerateQRCode = true
    shouldGenerateURL = true
    qrCodeGenerationAttempts = 0
    urlGenerationAttempts = 0
    lastGeneratedURL = nil
  }
}

// MARK: - Mock Rate Limiter

/// Mock Rate Limiter for testing purposes
class MockMFARateLimiter: MFARateLimiter {
  
  var shouldAllowAttempt = true
  var attemptCounts: [String: Int] = [:]
  var recordedAttempts: [String] = []
  var recordedFailures: [(String, String)] = []
  
  override func shouldAllowAttempt(for userId: String) -> Bool {
    recordedAttempts.append(userId)
    attemptCounts[userId, default: 0] += 1
    return shouldAllowAttempt
  }
  
  override func recordFailedAttempt(for userId: String, reason: String) {
    recordedFailures.append((userId, reason))
  }
  
  override func resetAttempts(for userId: String) {
    attemptCounts[userId] = 0
  }
  
  override func getRemainingDelay(for userId: String) -> TimeInterval {
    return shouldAllowAttempt ? 0 : 30
  }
  
  func reset() {
    shouldAllowAttempt = true
    attemptCounts.removeAll()
    recordedAttempts.removeAll()
    recordedFailures.removeAll()
  }
}

// MARK: - Mock Security Manager

/// Mock Security Manager for testing purposes
class MockMFASecurityManager: MFASecurityManager {
  
  var shouldStoreSecurely = true
  var shouldRetrieveSecurely = true
  var storedData: [String: Data] = [:]
  var auditLogs: [MFASecurityManager.AuditEvent] = []
  var secureComparisonResults = true
  
  override func storeSecurely(_ data: Data, key: String) -> Bool {
    if shouldStoreSecurely {
      storedData[key] = data
      return true
    }
    return false
  }
  
  override func retrieveSecurely(key: String) -> Data? {
    return shouldRetrieveSecurely ? storedData[key] : nil
  }
  
  override func deleteSecurely(key: String) -> Bool {
    storedData.removeValue(forKey: key)
    return true
  }
  
  override func auditLog(event: MFASecurityManager.AuditEvent) {
    auditLogs.append(event)
  }
  
  override func secureCompare(_ lhs: String, _ rhs: String) -> Bool {
    return secureComparisonResults ? (lhs == rhs) : false
  }
  
  override func secureCompare(_ lhs: Data, _ rhs: Data) -> Bool {
    return secureComparisonResults ? (lhs == rhs) : false
  }
  
  func reset() {
    shouldStoreSecurely = true
    shouldRetrieveSecurely = true
    storedData.removeAll()
    auditLogs.removeAll()
    secureComparisonResults = true
  }
}

// MARK: - Mock Authentication View Model

/// Mock Authentication View Model for testing MFA integration
class MockAuthenticationViewModel: ObservableObject {
  
  @Published var authenticationState: AuthenticationState = .unauthenticated
  @Published var showingMFASetup = false
  @Published var showingMFAVerification = false
  @Published var mfaEnabled = false
  @Published var errorMessage: String?
  
  var loginAttempts: [(email: String, password: String)] = []
  var mfaVerificationAttempts: [String] = []
  var mfaSetupAttempts = 0
  
  func login(email: String, password: String) {
    loginAttempts.append((email: email, password: password))
    
    // Simulate successful login
    if email == "test@example.com" && password == "password" {
      if mfaEnabled {
        showingMFAVerification = true
      } else {
        authenticationState = .authenticated
      }
    } else {
      errorMessage = "Invalid credentials"
    }
  }
  
  func verifyMFA(code: String) {
    mfaVerificationAttempts.append(code)
    
    if code == "123456" {
      authenticationState = .authenticated
      showingMFAVerification = false
    } else {
      errorMessage = "Invalid MFA code"
    }
  }
  
  func setupMFA() {
    mfaSetupAttempts += 1
    showingMFASetup = true
  }
  
  func completeMFASetup() {
    mfaEnabled = true
    showingMFASetup = false
  }
  
  func disableMFA() {
    mfaEnabled = false
  }
  
  func reset() {
    authenticationState = .unauthenticated
    showingMFASetup = false
    showingMFAVerification = false
    mfaEnabled = false
    errorMessage = nil
    loginAttempts.removeAll()
    mfaVerificationAttempts.removeAll()
    mfaSetupAttempts = 0
  }
}

// MARK: - Mock Network Service

/// Mock Network Service for testing API interactions
class MockNetworkService {
  
  var shouldSucceed = true
  var networkDelay: TimeInterval = 0.1
  var apiCalls: [String] = []
  var lastRequestData: Data?
  
  func enableMFA(userId: String, secret: String) async throws -> Bool {
    apiCalls.append("enableMFA")
    
    try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
    
    if shouldSucceed {
      return true
    } else {
      throw NetworkError.serverError
    }
  }
  
  func disableMFA(userId: String) async throws -> Bool {
    apiCalls.append("disableMFA")
    
    try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
    
    if shouldSucceed {
      return true
    } else {
      throw NetworkError.serverError
    }
  }
  
  func verifyMFA(userId: String, code: String) async throws -> Bool {
    apiCalls.append("verifyMFA")
    
    try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
    
    if shouldSucceed && code == "123456" {
      return true
    } else if shouldSucceed {
      return false
    } else {
      throw NetworkError.serverError
    }
  }
  
  func reset() {
    shouldSucceed = true
    networkDelay = 0.1
    apiCalls.removeAll()
    lastRequestData = nil
  }
  
  enum NetworkError: Error {
    case serverError
    case networkUnavailable
    case invalidResponse
  }
}

// MARK: - Mock Keychain Service

/// Mock Keychain Service for testing secure storage
class MockKeychainService {
  
  var shouldSucceed = true
  var storage: [String: Data] = [:]
  var accessAttempts: [String] = []
  
  func store(_ data: Data, key: String) -> Bool {
    accessAttempts.append("store:\(key)")
    
    if shouldSucceed {
      storage[key] = data
      return true
    }
    return false
  }
  
  func retrieve(key: String) -> Data? {
    accessAttempts.append("retrieve:\(key)")
    
    if shouldSucceed {
      return storage[key]
    }
    return nil
  }
  
  func delete(key: String) -> Bool {
    accessAttempts.append("delete:\(key)")
    
    if shouldSucceed {
      storage.removeValue(forKey: key)
      return true
    }
    return false
  }
  
  func reset() {
    shouldSucceed = true
    storage.removeAll()
    accessAttempts.removeAll()
  }
}

// MARK: - Test Data Factory

/// Factory for creating test data
struct MFATestDataFactory {
  
  static func createValidSecret() -> String {
    return "JBSWY3DPEHPK3PXP"
  }
  
  static func createValidTOTP() -> String {
    return "123456"
  }
  
  static func createValidBackupCodes() -> [String] {
    return ["ABC123", "DEF456", "GHI789", "JKL012", "MNO345"]
  }
  
  static func createTestUserId() -> String {
    return "test-user-\(UUID().uuidString)"
  }
  
  static func createTestUserProfile(withMFA: Bool = false) -> UserProfile {
    return UserProfile(
      id: UUID().uuidString,
      email: "test@example.com",
      firstName: "Test",
      lastName: "User",
      mfaEnabled: withMFA
    )
  }
  
  static func createMockQRCodeData() -> Data {
    return "Mock QR Code Data".data(using: .utf8)!
  }
  
  static func createOTPAuthURL(secret: String = "JBSWY3DPEHPK3PXP") -> String {
    return "otpauth://totp/PolyPal:test@example.com?secret=\(secret)&issuer=PolyPal"
  }
}

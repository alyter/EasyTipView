//
//  MFASecurityManager.swift
//  PolyPal
//
//  Created by Agent OS on 7/24/25.
//

import Foundation
import Security
import CryptoKit

/// Security manager for MFA operations
class MFASecurityManager {
  private let auditLogger = MFASecurityAuditLogger()
  
  // MARK: - Secure Memory Management
  
  /// Secure data container that zeros memory on deallocation
  class SecureData {
    private var data: Data
    private let capacity: Int
    
    init(data: Data) {
      self.capacity = data.count
      self.data = data
    }
    
    func getData() -> Data {
      return data
    }
    
    func zero() {
      data.withUnsafeMutableBytes { bytes in
        memset(bytes.baseAddress, 0, bytes.count)
      }
    }
    
    deinit {
      zero()
    }
  }
  
  /// Secure string container that zeros memory on deallocation
  class SecureString {
    private var string: String
    
    init(string: String) {
      self.string = string
    }
    
    func getString() -> String {
      return string
    }
    
    func clear() {
      // Convert to mutable data and zero it
      if var data = string.data(using: .utf8) {
        data.withUnsafeMutableBytes { bytes in
          memset(bytes.baseAddress, 0, bytes.count)
        }
      }
      string = ""
    }
    
    deinit {
      clear()
    }
  }
  
  func createSecureData(from data: Data) -> SecureData {
    return SecureData(data: data)
  }
  
  func getSecureData(_ secureData: SecureData) -> Data {
    return secureData.getData()
  }
  
  func zeroSecureData(_ secureData: SecureData) {
    secureData.zero()
  }
  
  func createSecureString(_ string: String) -> SecureString {
    return SecureString(string: string)
  }
  
  func getSecureString(_ secureString: SecureString) -> String {
    return secureString.getString()
  }
  
  func clearSecureString(_ secureString: SecureString) {
    secureString.clear()
  }
  
  // MARK: - Keychain Security
  
  enum KeychainAccessControl {
    case biometryAny
    case biometryCurrentSet
    case devicePasscode
    case none
    
    var secAccessControl: SecAccessControl? {
      switch self {
      case .biometryAny:
        return SecAccessControlCreateWithFlags(
          nil,
          kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
          .biometryAny,
          nil
        )
      case .biometryCurrentSet:
        return SecAccessControlCreateWithFlags(
          nil,
          kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
          .biometryCurrentSet,
          nil
        )
      case .devicePasscode:
        return SecAccessControlCreateWithFlags(
          nil,
          kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
          .devicePasscode,
          nil
        )
      case .none:
        return nil
      }
    }
  }
  
  func storeInKeychain(data: Data, key: String, accessControl: KeychainAccessControl = .none) -> Bool {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: "com.polypal.mfa",
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    if let secAccessControl = accessControl.secAccessControl {
      query[kSecAttrAccessControl as String] = secAccessControl
      query.removeValue(forKey: kSecAttrAccessible as String)
    }
    
    // Delete any existing item first
    deleteFromKeychain(key: key)
    
    let status = SecItemAdd(query as CFDictionary, nil)
    
    if status == errSecSuccess {
      auditLogger.logSecurityEvent(.keychainStoreSuccess, details: ["key": key])
    } else {
      auditLogger.logSecurityEvent(.keychainStoreFailure, details: ["key": key, "status": "\(status)"])
    }
    
    return status == errSecSuccess
  }
  
  func retrieveFromKeychain(key: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: "com.polypal.mfa",
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    if status == errSecSuccess {
      auditLogger.logSecurityEvent(.keychainRetrieveSuccess, details: ["key": key])
      return result as? Data
    } else {
      auditLogger.logSecurityEvent(.keychainRetrieveFailure, details: ["key": key, "status": "\(status)"])
      return nil
    }
  }
  
  func deleteFromKeychain(key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: "com.polypal.mfa"
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }
  
  // MARK: - Timing Attack Resistance
  
  /// Constant-time string comparison to resist timing attacks
  func constantTimeCompare(_ a: String, _ b: String) -> Bool {
    let aData = a.data(using: .utf8) ?? Data()
    let bData = b.data(using: .utf8) ?? Data()
    
    return constantTimeCompare(aData, bData)
  }
  
  /// Constant-time data comparison to resist timing attacks
  func constantTimeCompare(_ a: Data, _ b: Data) -> Bool {
    // Ensure both arrays are the same length by padding with zeros
    let maxLength = max(a.count, b.count)
    let paddedA = a + Data(repeating: 0, count: maxLength - a.count)
    let paddedB = b + Data(repeating: 0, count: maxLength - b.count)
    
    var result: UInt8 = 0
    
    // XOR all bytes - result will be 0 only if all bytes match
    for i in 0..<maxLength {
      result |= paddedA[i] ^ paddedB[i]
    }
    
    // Also XOR the length difference to prevent length-based timing attacks
    let lengthDiff = UInt8(abs(a.count - b.count) & 0xFF)
    result |= lengthDiff
    
    return result == 0
  }
  
  /// Generate secure hash for comparison
  func secureHash(_ input: String) -> String {
    let data = input.data(using: .utf8) ?? Data()
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }
  
  // MARK: - Security Audit Logging
  
  func getAuditLogger() -> MFASecurityAuditLogger {
    return auditLogger
  }
}

/// Security event types for audit logging
enum MFASecurityEvent {
  case mfaEnabled
  case mfaDisabled
  case mfaVerificationSuccess
  case mfaVerificationFailed
  case rateLimitTriggered
  case keychainStoreSuccess
  case keychainStoreFailure
  case keychainRetrieveSuccess
  case keychainRetrieveFailure
  case suspiciousActivity
  case securityPolicyViolation
}

/// Security audit log entry
struct MFASecurityLogEntry {
  let timestamp: Date
  let event: MFASecurityEvent
  let details: [String: String]
  let severity: LogSeverity
  
  enum LogSeverity {
    case info
    case warning
    case error
    case critical
  }
}

/// Security audit logger for MFA operations
class MFASecurityAuditLogger {
  private var logs: [MFASecurityLogEntry] = []
  private let maxLogEntries = 100
  private let queue = DispatchQueue(label: "com.polypal.mfa.audit", attributes: .concurrent)
  
  func logSecurityEvent(_ event: MFASecurityEvent, details: [String: String] = [:]) {
    let severity = getSeverity(for: event)
    let entry = MFASecurityLogEntry(
      timestamp: Date(),
      event: event,
      details: details,
      severity: severity
    )
    
    queue.async(flags: .barrier) {
      self.logs.insert(entry, at: 0)
      
      // Maintain maximum log size
      if self.logs.count > self.maxLogEntries {
        self.logs = Array(self.logs.prefix(self.maxLogEntries))
      }
    }
    
    // Log critical events to system log
    if severity == .critical {
      NSLog("MFA Security Critical Event: \(event) - \(details)")
    }
  }
  
  func getRecentLogs(limit: Int = 50) -> [MFASecurityLogEntry] {
    return queue.sync {
      return Array(logs.prefix(limit))
    }
  }
  
  func getLogsByEvent(_ event: MFASecurityEvent, limit: Int = 20) -> [MFASecurityLogEntry] {
    return queue.sync {
      return Array(logs.filter { $0.event == event }.prefix(limit))
    }
  }
  
  func getLogsBySeverity(_ severity: MFASecurityLogEntry.LogSeverity, limit: Int = 20) -> [MFASecurityLogEntry] {
    return queue.sync {
      return Array(logs.filter { $0.severity == severity }.prefix(limit))
    }
  }
  
  func clearLogs() {
    queue.async(flags: .barrier) {
      self.logs.removeAll()
    }
  }
  
  private func getSeverity(for event: MFASecurityEvent) -> MFASecurityLogEntry.LogSeverity {
    switch event {
    case .mfaEnabled, .mfaDisabled, .mfaVerificationSuccess:
      return .info
    case .mfaVerificationFailed, .keychainRetrieveFailure:
      return .warning
    case .rateLimitTriggered, .keychainStoreFailure:
      return .error
    case .suspiciousActivity, .securityPolicyViolation:
      return .critical
    case .keychainStoreSuccess, .keychainRetrieveSuccess:
      return .info
    }
  }
}

/// Extension to integrate security manager with existing MFA components
extension MFAManager {
  private static let securityManager = MFASecurityManager()
  private static let rateLimiter = ThreadSafeMFARateLimiter()
  
  /// Verify TOTP with security measures
  func verifyTOTPSecurely(_ code: String, secret: String) -> Bool {
    // Check rate limiting
    guard Self.rateLimiter.canAttempt() else {
      Self.securityManager.getAuditLogger().logSecurityEvent(
        .rateLimitTriggered,
        details: ["reason": "too_many_attempts"]
      )
      return false
    }
    
    // Use constant-time comparison
    let expectedCode = generateTOTP(secret: secret)
    let isValid = Self.securityManager.constantTimeCompare(code, expectedCode)
    
    if isValid {
      Self.rateLimiter.recordSuccessfulAttempt()
      Self.securityManager.getAuditLogger().logSecurityEvent(
        .mfaVerificationSuccess,
        details: ["method": "totp"]
      )
    } else {
      Self.rateLimiter.recordFailedAttempt()
      Self.securityManager.getAuditLogger().logSecurityEvent(
        .mfaVerificationFailed,
        details: ["method": "totp", "reason": "invalid_code"]
      )
    }
    
    return isValid
  }
  
  /// Get rate limiter for external access
  static func getRateLimiter() -> ThreadSafeMFARateLimiter {
    return rateLimiter
  }
  
  /// Get security manager for external access
  static func getSecurityManager() -> MFASecurityManager {
    return securityManager
  }
}

/// Extension to integrate security manager with backup codes
extension BackupCodeManager {
  private static let securityManager = MFASecurityManager()
  private static let rateLimiter = ThreadSafeMFARateLimiter()
  
  /// Validate backup code with security measures
  func validateBackupCodeSecurely(_ code: String) -> Bool {
    // Check rate limiting
    guard Self.rateLimiter.canAttempt() else {
      Self.securityManager.getAuditLogger().logSecurityEvent(
        .rateLimitTriggered,
        details: ["reason": "too_many_backup_attempts"]
      )
      return false
    }
    
    let isValid = validateBackupCode(code)
    
    if isValid {
      Self.rateLimiter.recordSuccessfulAttempt()
      Self.securityManager.getAuditLogger().logSecurityEvent(
        .mfaVerificationSuccess,
        details: ["method": "backup_code"]
      )
    } else {
      Self.rateLimiter.recordFailedAttempt()
      Self.securityManager.getAuditLogger().logSecurityEvent(
        .mfaVerificationFailed,
        details: ["method": "backup_code", "reason": "invalid_code"]
      )
    }
    
    return isValid
  }
}

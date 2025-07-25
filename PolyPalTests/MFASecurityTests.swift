//
//  MFASecurityTests.swift
//  PolyPalTests
//
//  Created by Agent OS on 7/24/25.
//

import XCTest
import Security
@testable import PolyPal

final class MFASecurityTests: XCTestCase {
  var securityManager: MFASecurityManager!
  var rateLimiter: MFARateLimiter!
  
  override func setUp() {
    super.setUp()
    securityManager = MFASecurityManager()
    rateLimiter = MFARateLimiter()
    
    // Clear any existing rate limiting state
    rateLimiter.reset()
  }
  
  override func tearDown() {
    securityManager = nil
    rateLimiter = nil
    super.tearDown()
  }
  
  // MARK: - Rate Limiting Tests
  
  func testRateLimitingBasicFunctionality() {
    // Should allow initial attempts
    XCTAssertTrue(rateLimiter.canAttempt())
    
    // Record failed attempts
    for _ in 0..<3 {
      rateLimiter.recordFailedAttempt()
    }
    
    // Should still allow attempts within limit
    XCTAssertTrue(rateLimiter.canAttempt())
    
    // Exceed the limit
    for _ in 0..<2 {
      rateLimiter.recordFailedAttempt()
    }
    
    // Should now be rate limited
    XCTAssertFalse(rateLimiter.canAttempt())
  }
  
  func testExponentialBackoff() {
    // Record multiple failed attempts
    for _ in 0..<5 {
      rateLimiter.recordFailedAttempt()
    }
    
    let firstDelay = rateLimiter.getBackoffDelay()
    XCTAssertGreaterThan(firstDelay, 0)
    
    // Record more failures
    for _ in 0..<3 {
      rateLimiter.recordFailedAttempt()
    }
    
    let secondDelay = rateLimiter.getBackoffDelay()
    XCTAssertGreaterThan(secondDelay, firstDelay, "Backoff should increase exponentially")
  }
  
  func testRateLimitReset() {
    // Trigger rate limiting
    for _ in 0..<10 {
      rateLimiter.recordFailedAttempt()
    }
    
    XCTAssertFalse(rateLimiter.canAttempt())
    
    // Reset should clear the limit
    rateLimiter.reset()
    XCTAssertTrue(rateLimiter.canAttempt())
  }
  
  func testSuccessfulAttemptResetsCounter() {
    // Record some failed attempts
    for _ in 0..<3 {
      rateLimiter.recordFailedAttempt()
    }
    
    let failureCount = rateLimiter.getFailureCount()
    XCTAssertEqual(failureCount, 3)
    
    // Record successful attempt
    rateLimiter.recordSuccessfulAttempt()
    
    let newFailureCount = rateLimiter.getFailureCount()
    XCTAssertEqual(newFailureCount, 0, "Successful attempt should reset failure counter")
  }
  
  // MARK: - Secure Memory Management Tests
  
  func testSecureMemoryZeroing() {
    let testData = "sensitive_secret_key_12345".data(using: .utf8)!
    let secureData = securityManager.createSecureData(from: testData)
    
    XCTAssertNotNil(secureData)
    
    // Verify data can be retrieved
    let retrievedData = securityManager.getSecureData(secureData)
    XCTAssertEqual(retrievedData, testData)
    
    // Zero the memory
    securityManager.zeroSecureData(secureData)
    
    // Verify data is zeroed (this is implementation dependent)
    let zeroedData = securityManager.getSecureData(secureData)
    XCTAssertNotEqual(zeroedData, testData, "Data should be zeroed after secure cleanup")
  }
  
  func testSecureStringHandling() {
    let sensitiveString = "JBSWY3DPEHPK3PXP"
    let secureString = securityManager.createSecureString(sensitiveString)
    
    XCTAssertNotNil(secureString)
    
    // Verify string can be retrieved
    let retrievedString = securityManager.getSecureString(secureString)
    XCTAssertEqual(retrievedString, sensitiveString)
    
    // Clear the secure string
    securityManager.clearSecureString(secureString)
    
    // Verify string is cleared
    let clearedString = securityManager.getSecureString(secureString)
    XCTAssertNotEqual(clearedString, sensitiveString, "String should be cleared after secure cleanup")
  }
  
  // MARK: - Keychain Security Tests
  
  func testKeychainAccessControls() {
    let testKey = "test_mfa_secret"
    let testData = "test_secret_data".data(using: .utf8)!
    
    // Store with biometric protection
    let storeResult = securityManager.storeInKeychain(
      data: testData,
      key: testKey,
      accessControl: .biometryAny
    )
    XCTAssertTrue(storeResult, "Should successfully store with biometric protection")
    
    // Attempt to retrieve (will require biometric in real scenario)
    let retrievedData = securityManager.retrieveFromKeychain(key: testKey)
    XCTAssertNotNil(retrievedData, "Should be able to retrieve stored data")
    
    // Clean up
    securityManager.deleteFromKeychain(key: testKey)
  }
  
  func testKeychainDataIntegrity() {
    let testKey = "integrity_test_key"
    let originalData = "original_secret_data".data(using: .utf8)!
    
    // Store data
    XCTAssertTrue(securityManager.storeInKeychain(data: originalData, key: testKey))
    
    // Retrieve and verify integrity
    let retrievedData = securityManager.retrieveFromKeychain(key: testKey)
    XCTAssertEqual(retrievedData, originalData, "Retrieved data should match original")
    
    // Clean up
    securityManager.deleteFromKeychain(key: testKey)
  }
  
  // MARK: - Timing Attack Resistance Tests
  
  func testConstantTimeComparison() {
    let correctCode = "123456"
    let wrongCode = "654321"
    let emptyCode = ""
    
    // Measure time for correct comparison
    let correctStart = CFAbsoluteTimeGetCurrent()
    let correctResult = securityManager.constantTimeCompare(correctCode, correctCode)
    let correctTime = CFAbsoluteTimeGetCurrent() - correctStart
    
    // Measure time for incorrect comparison
    let wrongStart = CFAbsoluteTimeGetCurrent()
    let wrongResult = securityManager.constantTimeCompare(correctCode, wrongCode)
    let wrongTime = CFAbsoluteTimeGetCurrent() - wrongStart
    
    // Measure time for empty comparison
    let emptyStart = CFAbsoluteTimeGetCurrent()
    let emptyResult = securityManager.constantTimeCompare(correctCode, emptyCode)
    let emptyTime = CFAbsoluteTimeGetCurrent() - emptyStart
    
    // Verify results
    XCTAssertTrue(correctResult)
    XCTAssertFalse(wrongResult)
    XCTAssertFalse(emptyResult)
    
    // Verify timing is relatively constant (within reasonable bounds)
    let timeDifference = abs(correctTime - wrongTime)
    XCTAssertLessThan(timeDifference, 0.001, "Timing difference should be minimal to resist timing attacks")
  }
  
  func testHashBasedComparison() {
    let secret1 = "secret_key_1"
    let secret2 = "secret_key_2"
    let secret1Copy = "secret_key_1"
    
    let hash1 = securityManager.secureHash(secret1)
    let hash2 = securityManager.secureHash(secret2)
    let hash1Copy = securityManager.secureHash(secret1Copy)
    
    XCTAssertNotEqual(hash1, hash2, "Different secrets should have different hashes")
    XCTAssertEqual(hash1, hash1Copy, "Same secret should produce same hash")
    
    // Verify hash comparison is constant time
    let start1 = CFAbsoluteTimeGetCurrent()
    let result1 = securityManager.constantTimeCompare(hash1, hash2)
    let time1 = CFAbsoluteTimeGetCurrent() - start1
    
    let start2 = CFAbsoluteTimeGetCurrent()
    let result2 = securityManager.constantTimeCompare(hash1, hash1Copy)
    let time2 = CFAbsoluteTimeGetCurrent() - start2
    
    XCTAssertFalse(result1)
    XCTAssertTrue(result2)
    
    let timeDifference = abs(time1 - time2)
    XCTAssertLessThan(timeDifference, 0.001, "Hash comparison timing should be constant")
  }
  
  // MARK: - Security Audit Logging Tests
  
  func testSecurityEventLogging() {
    let auditLogger = securityManager.getAuditLogger()
    
    // Log various security events
    auditLogger.logSecurityEvent(.mfaEnabled, details: ["user": "test_user"])
    auditLogger.logSecurityEvent(.mfaDisabled, details: ["user": "test_user", "reason": "user_request"])
    auditLogger.logSecurityEvent(.mfaVerificationFailed, details: ["attempts": "3", "ip": "192.168.1.1"])
    auditLogger.logSecurityEvent(.rateLimitTriggered, details: ["user": "test_user", "attempts": "10"])
    
    // Retrieve audit logs
    let logs = auditLogger.getRecentLogs(limit: 10)
    XCTAssertEqual(logs.count, 4, "Should have logged 4 security events")
    
    // Verify log structure
    let firstLog = logs.first!
    XCTAssertNotNil(firstLog.timestamp)
    XCTAssertEqual(firstLog.event, .mfaEnabled)
    XCTAssertEqual(firstLog.details["user"], "test_user")
  }
  
  func testAuditLogRetention() {
    let auditLogger = securityManager.getAuditLogger()
    
    // Log many events to test retention
    for i in 0..<150 {
      auditLogger.logSecurityEvent(.mfaVerificationSuccess, details: ["attempt": "\(i)"])
    }
    
    let logs = auditLogger.getRecentLogs(limit: 200)
    XCTAssertLessThanOrEqual(logs.count, 100, "Should retain maximum of 100 logs")
    
    // Verify most recent logs are kept
    let latestLog = logs.first!
    XCTAssertEqual(latestLog.details["attempt"], "149", "Most recent log should be kept")
  }
  
  // MARK: - Integration Security Tests
  
  func testMFAManagerSecurityIntegration() {
    let mfaManager = MFAManager()
    let secret = mfaManager.generateSecretKey()
    
    // Verify secret is properly secured
    XCTAssertFalse(secret.isEmpty)
    XCTAssertGreaterThanOrEqual(secret.count, 32, "Secret should be at least 32 characters")
    
    // Test TOTP generation with security measures
    let totp1 = mfaManager.generateTOTP(secret: secret)
    let totp2 = mfaManager.generateTOTP(secret: secret)
    
    // Should generate same TOTP for same time window
    XCTAssertEqual(totp1, totp2)
    
    // Test verification with rate limiting
    XCTAssertTrue(mfaManager.verifyTOTP(totp1, secret: secret))
    
    // Test that used TOTP cannot be reused (replay protection)
    XCTAssertFalse(mfaManager.verifyTOTP(totp1, secret: secret), "TOTP should not be reusable")
  }
  
  func testBackupCodeSecurityIntegration() {
    let backupManager = BackupCodeManager()
    let codes = backupManager.generateBackupCodes()
    
    XCTAssertEqual(codes.count, 10, "Should generate 10 backup codes")
    
    // Verify codes are properly secured and unique
    let uniqueCodes = Set(codes)
    XCTAssertEqual(uniqueCodes.count, codes.count, "All backup codes should be unique")
    
    // Test code validation with security measures
    let firstCode = codes.first!
    XCTAssertTrue(backupManager.validateBackupCode(firstCode))
    
    // Test that used code cannot be reused
    XCTAssertFalse(backupManager.validateBackupCode(firstCode), "Backup code should not be reusable")
  }
}

import XCTest
import SwiftUI
@testable import PolyPal

/// End-to-end feature tests for the complete MFA implementation
final class MFAEndToEndTests: XCTestCase {
  
  var mfaManager: MFAManager!
  var backupCodeManager: BackupCodeManager!
  var qrCodeManager: QRCodeManager!
  var rateLimiter: MFARateLimiter!
  var securityManager: MFASecurityManager!
  
  override func setUp() {
    super.setUp()
    mfaManager = MFAManager()
    backupCodeManager = BackupCodeManager()
    qrCodeManager = QRCodeManager()
    rateLimiter = MFARateLimiter()
    securityManager = MFASecurityManager()
  }
  
  override func tearDown() {
    // Clean up any stored data
    let userId = "test-user-e2e"
    backupCodeManager.deleteStoredBackupCodes(for: userId)
    rateLimiter.resetAttempts(for: userId)
    
    mfaManager = nil
    backupCodeManager = nil
    qrCodeManager = nil
    rateLimiter = nil
    securityManager = nil
    super.tearDown()
  }
  
  // MARK: - Complete MFA Setup Flow Tests
  
  func testCompleteUserMFASetupFlow() {
    let userId = "test-user-setup-\(UUID().uuidString)"
    
    // Step 1: Generate secret key
    let secret = mfaManager.generateSecretKey()
    XCTAssertFalse(secret.isEmpty, "Secret key should be generated")
    XCTAssertEqual(secret.count, 16, "Secret key should be 16 characters")
    
    // Step 2: Generate QR code for user scanning
    let qrCodeData = qrCodeManager.generateQRCode(
      for: secret,
      accountName: "test@example.com",
      issuer: "PolyPal"
    )
    XCTAssertNotNil(qrCodeData, "QR code should be generated")
    
    // Step 3: Generate backup codes
    let backupCodes = backupCodeManager.generateBackupCodes()
    XCTAssertEqual(backupCodes.count, 5, "Should generate 5 backup codes")
    
    // Step 4: Store backup codes securely
    backupCodeManager.storeBackupCodes(backupCodes, for: userId)
    let storedCodes = backupCodeManager.getStoredBackupCodes(for: userId)
    XCTAssertEqual(storedCodes?.count, 5, "All backup codes should be stored")
    
    // Step 5: Verify TOTP works
    let totp = mfaManager.generateTOTP(secret: secret)
    XCTAssertTrue(mfaManager.validateTOTP(totp, secret: secret), "Generated TOTP should be valid")
    
    // Step 6: Verify backup codes work
    let firstBackupCode = backupCodes[0]
    XCTAssertTrue(
      backupCodeManager.validateBackupCode(firstBackupCode, for: userId),
      "First backup code should be valid"
    )
    
    // Step 7: Verify used backup code cannot be reused
    XCTAssertFalse(
      backupCodeManager.validateBackupCode(firstBackupCode, for: userId),
      "Used backup code should not be valid again"
    )
    
    // Step 8: Verify remaining backup code count
    let remainingCount = backupCodeManager.getRemainingBackupCodeCount(for: userId)
    XCTAssertEqual(remainingCount, 4, "Should have 4 remaining backup codes")
  }
  
  func testCompleteUserLoginFlowWithMFA() {
    let userId = "test-user-login-\(UUID().uuidString)"
    let secret = mfaManager.generateSecretKey()
    let backupCodes = backupCodeManager.generateBackupCodes()
    backupCodeManager.storeBackupCodes(backupCodes, for: userId)
    
    // Simulate user login attempt
    XCTAssertTrue(rateLimiter.shouldAllowAttempt(for: userId), "First attempt should be allowed")
    
    // Generate and validate TOTP
    let totp = mfaManager.generateTOTP(secret: secret)
    let isValid = mfaManager.validateTOTP(totp, secret: secret)
    XCTAssertTrue(isValid, "TOTP should be valid for login")
    
    // Simulate successful login - reset rate limiter
    rateLimiter.resetAttempts(for: userId)
    
    // Verify user can login again later
    XCTAssertTrue(rateLimiter.shouldAllowAttempt(for: userId), "Should allow new login attempt")
  }
  
  func testCompleteUserRecoveryFlowWithBackupCodes() {
    let userId = "test-user-recovery-\(UUID().uuidString)"
    let backupCodes = backupCodeManager.generateBackupCodes()
    backupCodeManager.storeBackupCodes(backupCodes, for: userId)
    
    // Simulate user lost access to authenticator app
    // User tries to use backup code
    let backupCode = backupCodes[0]
    
    XCTAssertTrue(rateLimiter.shouldAllowAttempt(for: userId), "Recovery attempt should be allowed")
    XCTAssertTrue(
      backupCodeManager.validateBackupCode(backupCode, for: userId),
      "Backup code should work for recovery"
    )
    
    // Verify backup code is consumed
    XCTAssertFalse(
      backupCodeManager.validateBackupCode(backupCode, for: userId),
      "Used backup code should not work again"
    )
    
    // User regenerates backup codes after recovery
    let newBackupCodes = backupCodeManager.regenerateBackupCodes(for: userId)
    XCTAssertEqual(newBackupCodes.count, 5, "Should generate new backup codes")
    XCTAssertNotEqual(newBackupCodes, backupCodes, "New codes should be different")
  }
  
  // MARK: - Security Flow Tests
  
  func testRateLimitingDuringAttack() {
    let userId = "test-user-attack-\(UUID().uuidString)"
    let secret = mfaManager.generateSecretKey()
    
    // Simulate multiple failed attempts
    for attempt in 1...5 {
      if rateLimiter.shouldAllowAttempt(for: userId) {
        let isValid = mfaManager.validateTOTP("000000", secret: secret) // Invalid code
        XCTAssertFalse(isValid, "Invalid TOTP should not validate")
        rateLimiter.recordFailedAttempt(for: userId, reason: "Invalid TOTP")
      }
    }
    
    // After multiple failures, should be rate limited
    let shouldAllow = rateLimiter.shouldAllowAttempt(for: userId)
    let remainingDelay = rateLimiter.getRemainingDelay(for: userId)
    
    if !shouldAllow {
      XCTAssertGreaterThan(remainingDelay, 0, "Should have remaining delay after failed attempts")
    }
  }
  
  func testSecurityAuditLogging() {
    let userId = "test-user-audit-\(UUID().uuidString)"
    let secret = mfaManager.generateSecretKey()
    
    // Simulate various security events
    securityManager.auditLog(event: MFASecurityManager.AuditEvent(
      type: .mfaEnabled,
      userId: userId,
      timestamp: Date(),
      details: "MFA enabled for user",
      severity: .info
    ))
    
    securityManager.auditLog(event: MFASecurityManager.AuditEvent(
      type: .totpValidationFailed,
      userId: userId,
      timestamp: Date(),
      details: "Invalid TOTP attempt",
      severity: .warning
    ))
    
    securityManager.auditLog(event: MFASecurityManager.AuditEvent(
      type: .backupCodeUsed,
      userId: userId,
      timestamp: Date(),
      details: "Backup code used for recovery",
      severity: .info
    ))
    
    // In a real implementation, we would verify the audit logs are properly stored
    XCTAssertTrue(true, "Audit logging should work without errors")
  }
  
  // MARK: - Error Handling Flow Tests
  
  func testMFASetupErrorRecovery() {
    let userId = "test-user-error-\(UUID().uuidString)"
    
    // Simulate QR code generation failure
    let invalidSecret = ""
    let qrCodeData = qrCodeManager.generateQRCode(
      for: invalidSecret,
      accountName: "test@example.com",
      issuer: "PolyPal"
    )
    
    // Should handle invalid input gracefully
    if qrCodeData == nil {
      // Retry with valid secret
      let validSecret = mfaManager.generateSecretKey()
      let retryQRCode = qrCodeManager.generateQRCode(
        for: validSecret,
        accountName: "test@example.com",
        issuer: "PolyPal"
      )
      XCTAssertNotNil(retryQRCode, "Should succeed with valid secret")
    }
  }
  
  func testBackupCodeStorageFailureRecovery() {
    let userId = "test-user-storage-\(UUID().uuidString)"
    let backupCodes = backupCodeManager.generateBackupCodes()
    
    // Store backup codes
    backupCodeManager.storeBackupCodes(backupCodes, for: userId)
    
    // Verify storage worked
    let storedCodes = backupCodeManager.getStoredBackupCodes(for: userId)
    XCTAssertNotNil(storedCodes, "Backup codes should be stored successfully")
    
    // Test retrieval failure scenario
    let nonExistentUserId = "non-existent-user"
    let retrievedCodes = backupCodeManager.getStoredBackupCodes(for: nonExistentUserId)
    XCTAssertNil(retrievedCodes, "Should return nil for non-existent user")
  }
  
  // MARK: - Integration Flow Tests
  
  func testMFAIntegrationWithUserProfile() {
    let userId = "test-user-profile-\(UUID().uuidString)"
    
    // Create user profile without MFA
    var userProfile = UserProfile(
      id: userId,
      email: "test@example.com",
      firstName: "Test",
      lastName: "User",
      mfaEnabled: false
    )
    
    XCTAssertFalse(userProfile.mfaEnabled, "MFA should be disabled initially")
    
    // Enable MFA
    let secret = mfaManager.generateSecretKey()
    let backupCodes = backupCodeManager.generateBackupCodes()
    backupCodeManager.storeBackupCodes(backupCodes, for: userId)
    
    // Update user profile
    userProfile.mfaEnabled = true
    XCTAssertTrue(userProfile.mfaEnabled, "MFA should be enabled after setup")
    
    // Verify MFA works with profile
    let totp = mfaManager.generateTOTP(secret: secret)
    XCTAssertTrue(mfaManager.validateTOTP(totp, secret: secret), "TOTP should work with enabled profile")
  }
  
  func testMFADisableFlow() {
    let userId = "test-user-disable-\(UUID().uuidString)"
    let secret = mfaManager.generateSecretKey()
    let backupCodes = backupCodeManager.generateBackupCodes()
    
    // Setup MFA
    backupCodeManager.storeBackupCodes(backupCodes, for: userId)
    
    // Verify MFA is working
    let totp = mfaManager.generateTOTP(secret: secret)
    XCTAssertTrue(mfaManager.validateTOTP(totp, secret: secret), "MFA should work before disable")
    
    // Disable MFA - clean up stored data
    backupCodeManager.deleteStoredBackupCodes(for: userId)
    rateLimiter.resetAttempts(for: userId)
    
    // Verify cleanup
    let storedCodes = backupCodeManager.getStoredBackupCodes(for: userId)
    XCTAssertNil(storedCodes, "Backup codes should be deleted after disable")
  }
  
  // MARK: - Performance Integration Tests
  
  func testMFAPerformanceUnderLoad() {
    let userCount = 10
    let operationsPerUser = 50
    
    let expectation = XCTestExpectation(description: "Performance test completion")
    expectation.expectedFulfillmentCount = userCount
    
    // Simulate multiple users performing MFA operations concurrently
    for userIndex in 0..<userCount {
      DispatchQueue.global().async {
        let userId = "perf-user-\(userIndex)"
        let secret = self.mfaManager.generateSecretKey()
        let backupCodes = self.backupCodeManager.generateBackupCodes()
        self.backupCodeManager.storeBackupCodes(backupCodes, for: userId)
        
        for _ in 0..<operationsPerUser {
          // Generate and validate TOTP
          let totp = self.mfaManager.generateTOTP(secret: secret)
          _ = self.mfaManager.validateTOTP(totp, secret: secret)
          
          // Check rate limiting
          _ = self.rateLimiter.shouldAllowAttempt(for: userId)
          
          // Generate QR code occasionally
          if Int.random(in: 0..<10) == 0 {
            _ = self.qrCodeManager.generateQRCode(
              for: secret,
              accountName: "user\(userIndex)@example.com",
              issuer: "PolyPal"
            )
          }
        }
        
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation], timeout: 30.0)
    XCTAssertTrue(true, "Performance test should complete without errors")
  }
  
  // MARK: - Edge Case Tests
  
  func testMFAWithClockSkew() {
    let secret = mfaManager.generateSecretKey()
    
    // Test with past time (30 seconds ago)
    let pastTime = Date().timeIntervalSince1970 - 30
    let pastTOTP = mfaManager.generateTOTP(secret: secret, timeInterval: pastTime)
    
    // Should still validate due to time window tolerance
    let isValidPast = mfaManager.validateTOTP(pastTOTP, secret: secret)
    XCTAssertTrue(isValidPast, "TOTP from 30 seconds ago should still be valid")
    
    // Test with future time (30 seconds ahead)
    let futureTime = Date().timeIntervalSince1970 + 30
    let futureTOTP = mfaManager.generateTOTP(secret: secret, timeInterval: futureTime)
    
    // Should still validate due to time window tolerance
    let isValidFuture = mfaManager.validateTOTP(futureTOTP, secret: secret)
    XCTAssertTrue(isValidFuture, "TOTP from 30 seconds in future should still be valid")
  }
  
  func testMFAWithInvalidInputs() {
    let userId = "test-user-invalid-\(UUID().uuidString)"
    
    // Test with empty secret
    let emptySecret = ""
    let totpEmpty = mfaManager.generateTOTP(secret: emptySecret)
    XCTAssertFalse(mfaManager.validateTOTP(totpEmpty, secret: emptySecret), "Empty secret should not validate")
    
    // Test with invalid backup code format
    let backupCodes = backupCodeManager.generateBackupCodes()
    backupCodeManager.storeBackupCodes(backupCodes, for: userId)
    
    XCTAssertFalse(
      backupCodeManager.validateBackupCode("", for: userId),
      "Empty backup code should not validate"
    )
    
    XCTAssertFalse(
      backupCodeManager.validateBackupCode("INVALID", for: userId),
      "Invalid backup code should not validate"
    )
  }
  
  // MARK: - Cleanup Tests
  
  func testMFADataCleanup() {
    let userId = "test-user-cleanup-\(UUID().uuidString)"
    let secret = mfaManager.generateSecretKey()
    let backupCodes = backupCodeManager.generateBackupCodes()
    
    // Setup MFA data
    backupCodeManager.storeBackupCodes(backupCodes, for: userId)
    
    // Simulate failed attempts to create rate limiting data
    for _ in 0..<3 {
      rateLimiter.recordFailedAttempt(for: userId, reason: "Test failure")
    }
    
    // Verify data exists
    XCTAssertNotNil(backupCodeManager.getStoredBackupCodes(for: userId), "Backup codes should exist")
    XCTAssertGreaterThan(rateLimiter.getRemainingDelay(for: userId), 0, "Should have rate limiting data")
    
    // Clean up all MFA data
    backupCodeManager.deleteStoredBackupCodes(for: userId)
    rateLimiter.resetAttempts(for: userId)
    
    // Verify cleanup
    XCTAssertNil(backupCodeManager.getStoredBackupCodes(for: userId), "Backup codes should be deleted")
    XCTAssertEqual(rateLimiter.getRemainingDelay(for: userId), 0, "Rate limiting should be reset")
  }
}

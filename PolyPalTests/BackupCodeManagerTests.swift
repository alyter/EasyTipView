import XCTest
@testable import PolyPal

final class BackupCodeManagerTests: XCTestCase {
  
  var backupCodeManager: BackupCodeManager!
  
  override func setUp() {
    super.setUp()
    backupCodeManager = BackupCodeManager()
  }
  
  override func tearDown() {
    backupCodeManager = nil
    super.tearDown()
  }
  
  // MARK: - Backup Code Generation Tests
  
  func testGenerateBackupCodes() {
    // Test generating backup codes
    let codes = backupCodeManager.generateBackupCodes()
    
    XCTAssertEqual(codes.count, 10, "Should generate exactly 10 backup codes")
    
    // Verify each code format
    for code in codes {
      XCTAssertEqual(code.count, 8, "Each backup code should be 8 characters long")
      XCTAssertTrue(code.allSatisfy { $0.isLetter || $0.isNumber }, "Backup codes should only contain alphanumeric characters")
      XCTAssertTrue(code.allSatisfy { $0.isUppercase || $0.isNumber }, "Backup codes should be uppercase")
    }
    
    // Verify codes are unique
    let uniqueCodes = Set(codes)
    XCTAssertEqual(codes.count, uniqueCodes.count, "All backup codes should be unique")
  }
  
  func testBackupCodeFormat() {
    // Test backup code format consistency
    let codes = backupCodeManager.generateBackupCodes()
    
    for code in codes {
      // Should match pattern: XXXXXXXX (8 alphanumeric characters)
      let pattern = "^[A-Z0-9]{8}$"
      let regex = try! NSRegularExpression(pattern: pattern)
      let range = NSRange(location: 0, length: code.utf16.count)
      let matches = regex.matches(in: code, range: range)
      
      XCTAssertEqual(matches.count, 1, "Backup code '\(code)' should match expected format")
    }
  }
  
  func testBackupCodeRandomness() {
    // Test that generated codes are sufficiently random
    let codes1 = backupCodeManager.generateBackupCodes()
    let codes2 = backupCodeManager.generateBackupCodes()
    
    // Should be extremely unlikely to generate identical sets
    XCTAssertNotEqual(Set(codes1), Set(codes2), "Generated backup code sets should be different")
    
    // Test entropy - no code should appear in both sets
    let intersection = Set(codes1).intersection(Set(codes2))
    XCTAssertTrue(intersection.isEmpty, "No codes should be duplicated across generations")
  }
  
  // MARK: - Backup Code Validation Tests
  
  func testValidateBackupCodeSuccess() {
    // Test successful backup code validation
    let codes = backupCodeManager.generateBackupCodes()
    let testCode = codes.first!
    
    // Store codes for validation
    backupCodeManager.storeBackupCodes(codes, for: "test-user")
    
    // Validate the code
    let isValid = backupCodeManager.validateBackupCode(testCode, for: "test-user")
    XCTAssertTrue(isValid, "Valid backup code should be accepted")
    
    // Code should be marked as used and no longer valid
    let isValidAgain = backupCodeManager.validateBackupCode(testCode, for: "test-user")
    XCTAssertFalse(isValidAgain, "Used backup code should not be valid again")
  }
  
  func testValidateBackupCodeInvalid() {
    // Test validation with invalid codes
    let codes = backupCodeManager.generateBackupCodes()
    backupCodeManager.storeBackupCodes(codes, for: "test-user")
    
    // Test with completely invalid code
    let invalidCode = "INVALID1"
    let isValid = backupCodeManager.validateBackupCode(invalidCode, for: "test-user")
    XCTAssertFalse(isValid, "Invalid backup code should be rejected")
    
    // Test with code for different user
    let isValidForWrongUser = backupCodeManager.validateBackupCode(codes.first!, for: "wrong-user")
    XCTAssertFalse(isValidForWrongUser, "Backup code should not be valid for different user")
  }
  
  func testValidateBackupCodeCaseInsensitive() {
    // Test that validation is case-insensitive
    let codes = backupCodeManager.generateBackupCodes()
    let testCode = codes.first!
    
    backupCodeManager.storeBackupCodes(codes, for: "test-user")
    
    // Test with lowercase version
    let lowercaseCode = testCode.lowercased()
    let isValid = backupCodeManager.validateBackupCode(lowercaseCode, for: "test-user")
    XCTAssertTrue(isValid, "Backup code validation should be case-insensitive")
  }
  
  func testValidateBackupCodeWithWhitespace() {
    // Test validation with whitespace
    let codes = backupCodeManager.generateBackupCodes()
    let testCode = codes.first!
    
    backupCodeManager.storeBackupCodes(codes, for: "test-user")
    
    // Test with leading/trailing whitespace
    let codeWithWhitespace = "  \(testCode)  "
    let isValid = backupCodeManager.validateBackupCode(codeWithWhitespace, for: "test-user")
    XCTAssertTrue(isValid, "Backup code validation should handle whitespace")
  }
  
  // MARK: - Usage Tracking Tests
  
  func testBackupCodeUsageTracking() {
    // Test that backup codes are properly tracked when used
    let codes = backupCodeManager.generateBackupCodes()
    backupCodeManager.storeBackupCodes(codes, for: "test-user")
    
    let initialRemainingCount = backupCodeManager.getRemainingBackupCodeCount(for: "test-user")
    XCTAssertEqual(initialRemainingCount, 10, "Should start with 10 unused backup codes")
    
    // Use first code
    _ = backupCodeManager.validateBackupCode(codes[0], for: "test-user")
    let afterFirstUse = backupCodeManager.getRemainingBackupCodeCount(for: "test-user")
    XCTAssertEqual(afterFirstUse, 9, "Should have 9 remaining codes after using one")
    
    // Use second code
    _ = backupCodeManager.validateBackupCode(codes[1], for: "test-user")
    let afterSecondUse = backupCodeManager.getRemainingBackupCodeCount(for: "test-user")
    XCTAssertEqual(afterSecondUse, 8, "Should have 8 remaining codes after using two")
  }
  
  func testGetUsedBackupCodes() {
    // Test retrieving used backup codes
    let codes = backupCodeManager.generateBackupCodes()
    backupCodeManager.storeBackupCodes(codes, for: "test-user")
    
    // Use some codes
    _ = backupCodeManager.validateBackupCode(codes[0], for: "test-user")
    _ = backupCodeManager.validateBackupCode(codes[2], for: "test-user")
    
    let usedCodes = backupCodeManager.getUsedBackupCodes(for: "test-user")
    XCTAssertEqual(usedCodes.count, 2, "Should track 2 used codes")
    XCTAssertTrue(usedCodes.contains(codes[0]), "Should contain first used code")
    XCTAssertTrue(usedCodes.contains(codes[2]), "Should contain second used code")
  }
  
  // MARK: - Keychain Storage Tests
  
  func testKeychainStorage() {
    // Test storing and retrieving backup codes from Keychain
    let codes = backupCodeManager.generateBackupCodes()
    let userId = "test-user-keychain"
    
    // Store codes
    let storeResult = backupCodeManager.storeBackupCodes(codes, for: userId)
    XCTAssertTrue(storeResult, "Should successfully store backup codes in Keychain")
    
    // Retrieve codes
    let retrievedCodes = backupCodeManager.getStoredBackupCodes(for: userId)
    XCTAssertNotNil(retrievedCodes, "Should retrieve stored backup codes")
    XCTAssertEqual(Set(codes), Set(retrievedCodes!), "Retrieved codes should match stored codes")
  }
  
  func testKeychainStorageOverwrite() {
    // Test overwriting existing backup codes
    let originalCodes = backupCodeManager.generateBackupCodes()
    let newCodes = backupCodeManager.generateBackupCodes()
    let userId = "test-user-overwrite"
    
    // Store original codes
    _ = backupCodeManager.storeBackupCodes(originalCodes, for: userId)
    
    // Store new codes (should overwrite)
    let overwriteResult = backupCodeManager.storeBackupCodes(newCodes, for: userId)
    XCTAssertTrue(overwriteResult, "Should successfully overwrite backup codes")
    
    // Verify new codes are stored
    let retrievedCodes = backupCodeManager.getStoredBackupCodes(for: userId)
    XCTAssertEqual(Set(newCodes), Set(retrievedCodes!), "Should retrieve new codes, not original")
  }
  
  func testKeychainDeletion() {
    // Test deleting backup codes from Keychain
    let codes = backupCodeManager.generateBackupCodes()
    let userId = "test-user-delete"
    
    // Store codes
    _ = backupCodeManager.storeBackupCodes(codes, for: userId)
    
    // Verify codes exist
    XCTAssertNotNil(backupCodeManager.getStoredBackupCodes(for: userId))
    
    // Delete codes
    let deleteResult = backupCodeManager.deleteBackupCodes(for: userId)
    XCTAssertTrue(deleteResult, "Should successfully delete backup codes")
    
    // Verify codes are gone
    XCTAssertNil(backupCodeManager.getStoredBackupCodes(for: userId), "Backup codes should be deleted")
  }
  
  // MARK: - Regeneration Tests
  
  func testRegenerateBackupCodes() {
    // Test regenerating backup codes
    let originalCodes = backupCodeManager.generateBackupCodes()
    let userId = "test-user-regen"
    
    // Store original codes and use some
    backupCodeManager.storeBackupCodes(originalCodes, for: userId)
    _ = backupCodeManager.validateBackupCode(originalCodes[0], for: userId)
    _ = backupCodeManager.validateBackupCode(originalCodes[1], for: userId)
    
    XCTAssertEqual(backupCodeManager.getRemainingBackupCodeCount(for: userId), 8)
    
    // Regenerate codes
    let newCodes = backupCodeManager.regenerateBackupCodes(for: userId)
    XCTAssertEqual(newCodes.count, 10, "Should generate 10 new backup codes")
    
    // Verify all codes are fresh
    XCTAssertEqual(backupCodeManager.getRemainingBackupCodeCount(for: userId), 10)
    
    // Verify old codes no longer work
    let oldCodeValid = backupCodeManager.validateBackupCode(originalCodes[2], for: userId)
    XCTAssertFalse(oldCodeValid, "Old backup codes should no longer be valid after regeneration")
    
    // Verify new codes work
    let newCodeValid = backupCodeManager.validateBackupCode(newCodes[0], for: userId)
    XCTAssertTrue(newCodeValid, "New backup codes should be valid")
  }
  
  // MARK: - Security Tests
  
  func testBackupCodeEntropy() {
    // Test that backup codes have sufficient entropy
    let codes = backupCodeManager.generateBackupCodes()
    
    // Check character distribution
    var characterCounts: [Character: Int] = [:]
    for code in codes {
      for char in code {
        characterCounts[char, default: 0] += 1
      }
    }
    
    // Should use a good variety of characters (not heavily biased)
    let totalChars = codes.joined().count
    let averageCount = Double(totalChars) / Double(characterCounts.count)
    
    // No single character should appear more than 3x the average
    for (_, count) in characterCounts {
      XCTAssertLessThan(Double(count), averageCount * 3.0, "Character distribution should be reasonably uniform")
    }
  }
  
  func testSecureMemoryHandling() {
    // Test that sensitive data is handled securely
    let codes = backupCodeManager.generateBackupCodes()
    let userId = "test-user-security"
    
    // Store codes
    backupCodeManager.storeBackupCodes(codes, for: userId)
    
    // Use a code
    let testCode = codes.first!
    _ = backupCodeManager.validateBackupCode(testCode, for: userId)
    
    // This test mainly ensures the methods complete without crashing
    // Actual memory clearing verification would require lower-level testing
    XCTAssertTrue(true, "Security methods should complete without errors")
  }
  
  // MARK: - Edge Cases
  
  func testEmptyUserIdHandling() {
    // Test handling of empty user IDs
    let codes = backupCodeManager.generateBackupCodes()
    
    let storeResult = backupCodeManager.storeBackupCodes(codes, for: "")
    XCTAssertFalse(storeResult, "Should not store backup codes for empty user ID")
    
    let validateResult = backupCodeManager.validateBackupCode("TESTCODE", for: "")
    XCTAssertFalse(validateResult, "Should not validate codes for empty user ID")
  }
  
  func testNonexistentUserHandling() {
    // Test handling of nonexistent users
    let validateResult = backupCodeManager.validateBackupCode("TESTCODE", for: "nonexistent-user")
    XCTAssertFalse(validateResult, "Should not validate codes for nonexistent user")
    
    let remainingCount = backupCodeManager.getRemainingBackupCodeCount(for: "nonexistent-user")
    XCTAssertEqual(remainingCount, 0, "Should return 0 remaining codes for nonexistent user")
  }
}

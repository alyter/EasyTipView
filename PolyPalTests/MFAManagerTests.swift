import XCTest
import CryptoKit
@testable import PolyPal

final class MFAManagerTests: XCTestCase {
  
  var mfaManager: MFAManager!
  
  override func setUp() {
    super.setUp()
    mfaManager = MFAManager()
  }
  
  override func tearDown() {
    mfaManager = nil
    super.tearDown()
  }
  
  // MARK: - Secret Key Generation Tests
  
  func testGenerateSecretKey_ReturnsValidKey() {
    // Given & When
    let secretKey = mfaManager.generateSecretKey()
    
    // Then
    XCTAssertFalse(secretKey.isEmpty, "Secret key should not be empty")
    XCTAssertEqual(secretKey.count, 32, "Secret key should be 32 bytes (160 bits)")
  }
  
  func testGenerateSecretKey_ReturnsUniqueKeys() {
    // Given & When
    let key1 = mfaManager.generateSecretKey()
    let key2 = mfaManager.generateSecretKey()
    
    // Then
    XCTAssertNotEqual(key1, key2, "Generated secret keys should be unique")
  }
  
  // MARK: - Base32 Encoding/Decoding Tests
  
  func testBase32Encode_ValidData() {
    // Given
    let testData = "Hello World".data(using: .utf8)!
    
    // When
    let encoded = mfaManager.base32Encode(testData)
    
    // Then
    XCTAssertEqual(encoded, "JBSWY3DPEBLW64TMMQ======", "Base32 encoding should match expected value")
  }
  
  func testBase32Decode_ValidString() {
    // Given
    let testString = "JBSWY3DPEBLW64TMMQ======"
    
    // When
    let decoded = mfaManager.base32Decode(testString)
    let decodedString = String(data: decoded!, encoding: .utf8)
    
    // Then
    XCTAssertNotNil(decoded, "Base32 decoding should succeed")
    XCTAssertEqual(decodedString, "Hello World", "Decoded data should match original")
  }
  
  func testBase32Decode_InvalidString() {
    // Given
    let invalidString = "Invalid@Base32!"
    
    // When
    let decoded = mfaManager.base32Decode(invalidString)
    
    // Then
    XCTAssertNil(decoded, "Invalid Base32 string should return nil")
  }
  
  func testBase32RoundTrip_PreservesData() {
    // Given
    let originalData = mfaManager.generateSecretKey()
    
    // When
    let encoded = mfaManager.base32Encode(originalData)
    let decoded = mfaManager.base32Decode(encoded)
    
    // Then
    XCTAssertEqual(originalData, decoded, "Base32 round trip should preserve original data")
  }
  
  // MARK: - TOTP Generation Tests
  
  func testGenerateTOTP_ValidSecret() {
    // Given
    let secretKey = Data([0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x21, 0xde, 0xad, 0xbe, 0xef, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x21, 0xde, 0xad, 0xbe, 0xef])
    let timestamp: TimeInterval = 1234567890 // Fixed timestamp for consistent testing
    
    // When
    let totp = mfaManager.generateTOTP(secretKey: secretKey, timestamp: timestamp)
    
    // Then
    XCTAssertNotNil(totp, "TOTP generation should succeed")
    XCTAssertEqual(totp?.count, 6, "TOTP should be 6 digits")
    XCTAssertTrue(totp?.allSatisfy { $0.isNumber } ?? false, "TOTP should contain only digits")
  }
  
  func testGenerateTOTP_ConsistentOutput() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let timestamp: TimeInterval = 1234567890
    
    // When
    let totp1 = mfaManager.generateTOTP(secretKey: secretKey, timestamp: timestamp)
    let totp2 = mfaManager.generateTOTP(secretKey: secretKey, timestamp: timestamp)
    
    // Then
    XCTAssertEqual(totp1, totp2, "TOTP should be consistent for same secret and timestamp")
  }
  
  func testGenerateTOTP_DifferentTimestamps() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let timestamp1: TimeInterval = 1234567890
    let timestamp2: TimeInterval = 1234567920 // 30 seconds later
    
    // When
    let totp1 = mfaManager.generateTOTP(secretKey: secretKey, timestamp: timestamp1)
    let totp2 = mfaManager.generateTOTP(secretKey: secretKey, timestamp: timestamp2)
    
    // Then
    XCTAssertNotEqual(totp1, totp2, "TOTP should be different for different time windows")
  }
  
  func testGenerateTOTP_EmptySecret() {
    // Given
    let emptySecret = Data()
    let timestamp: TimeInterval = 1234567890
    
    // When
    let totp = mfaManager.generateTOTP(secretKey: emptySecret, timestamp: timestamp)
    
    // Then
    XCTAssertNil(totp, "TOTP generation should fail with empty secret")
  }
  
  // MARK: - TOTP Validation Tests
  
  func testValidateTOTP_ValidCode() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let currentTime = Date().timeIntervalSince1970
    let validCode = mfaManager.generateTOTP(secretKey: secretKey, timestamp: currentTime)!
    
    // When
    let isValid = mfaManager.validateTOTP(code: validCode, secretKey: secretKey, timestamp: currentTime)
    
    // Then
    XCTAssertTrue(isValid, "Valid TOTP code should be accepted")
  }
  
  func testValidateTOTP_InvalidCode() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let currentTime = Date().timeIntervalSince1970
    let invalidCode = "000000"
    
    // When
    let isValid = mfaManager.validateTOTP(code: invalidCode, secretKey: secretKey, timestamp: currentTime)
    
    // Then
    XCTAssertFalse(isValid, "Invalid TOTP code should be rejected")
  }
  
  func testValidateTOTP_ClockDriftTolerance() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let baseTime = Date().timeIntervalSince1970
    let validCode = mfaManager.generateTOTP(secretKey: secretKey, timestamp: baseTime)!
    
    // When - Test with +30 seconds (1 time window drift)
    let validWithPastDrift = mfaManager.validateTOTP(code: validCode, secretKey: secretKey, timestamp: baseTime + 30)
    
    // Then
    XCTAssertTrue(validWithPastDrift, "TOTP should be valid with past clock drift")
  }
  
  func testValidateTOTP_ClockDriftTolerance_Future() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let baseTime = Date().timeIntervalSince1970
    let validCode = mfaManager.generateTOTP(secretKey: secretKey, timestamp: baseTime)!
    
    // When - Test with -30 seconds (1 time window drift)
    let validWithFutureDrift = mfaManager.validateTOTP(code: validCode, secretKey: secretKey, timestamp: baseTime - 30)
    
    // Then
    XCTAssertTrue(validWithFutureDrift, "TOTP should be valid with future clock drift")
  }
  
  func testValidateTOTP_ExcessiveClockDrift() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let baseTime = Date().timeIntervalSince1970
    let validCode = mfaManager.generateTOTP(secretKey: secretKey, timestamp: baseTime)!
    
    // When - Test with ±90 seconds (3 time windows)
    let invalidWithExcessiveDrift = mfaManager.validateTOTP(code: validCode, secretKey: secretKey, timestamp: baseTime + 90)
    
    // Then
    XCTAssertFalse(invalidWithExcessiveDrift, "TOTP should be invalid with excessive clock drift")
  }
  
  func testValidateTOTP_WrongLength() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let currentTime = Date().timeIntervalSince1970
    
    // When
    let tooShort = mfaManager.validateTOTP(code: "123", secretKey: secretKey, timestamp: currentTime)
    let tooLong = mfaManager.validateTOTP(code: "1234567", secretKey: secretKey, timestamp: currentTime)
    
    // Then
    XCTAssertFalse(tooShort, "TOTP code that's too short should be rejected")
    XCTAssertFalse(tooLong, "TOTP code that's too long should be rejected")
  }
  
  func testValidateTOTP_NonNumericCode() {
    // Given
    let secretKey = mfaManager.generateSecretKey()
    let currentTime = Date().timeIntervalSince1970
    let nonNumericCode = "abc123"
    
    // When
    let isValid = mfaManager.validateTOTP(code: nonNumericCode, secretKey: secretKey, timestamp: currentTime)
    
    // Then
    XCTAssertFalse(isValid, "Non-numeric TOTP code should be rejected")
  }
  
  // MARK: - Time Window Tests
  
  func testGetTimeWindow_CorrectCalculation() {
    // Given
    let timestamp: TimeInterval = 1234567890 // Unix timestamp
    let expectedWindow = Int64(timestamp / 30) // 30-second windows
    
    // When
    let actualWindow = mfaManager.getTimeWindow(timestamp: timestamp)
    
    // Then
    XCTAssertEqual(actualWindow, expectedWindow, "Time window calculation should be correct")
  }
  
  func testGetTimeWindow_DifferentTimestamps() {
    // Given
    let timestamp1: TimeInterval = 1234567890
    let timestamp2: TimeInterval = 1234567920 // 30 seconds later
    
    // When
    let window1 = mfaManager.getTimeWindow(timestamp: timestamp1)
    let window2 = mfaManager.getTimeWindow(timestamp: timestamp2)
    
    // Then
    XCTAssertEqual(window2, window1 + 1, "Time windows should increment every 30 seconds")
  }
  
  // MARK: - RFC 6238 Compliance Tests
  
  func testRFC6238_TestVectors() {
    // Given - RFC 6238 test vectors
    let secret = "12345678901234567890".data(using: .ascii)!
    let testCases: [(TimeInterval, String)] = [
      (59, "287082"),
      (1111111109, "081804"),
      (1111111111, "050471"),
      (1234567890, "005924"),
      (2000000000, "279037"),
      (20000000000, "353130")
    ]
    
    // When & Then
    for (timestamp, expectedCode) in testCases {
      let generatedCode = mfaManager.generateTOTP(secretKey: secret, timestamp: timestamp)
      XCTAssertEqual(generatedCode, expectedCode, "TOTP should match RFC 6238 test vector for timestamp \(timestamp)")
    }
  }
}

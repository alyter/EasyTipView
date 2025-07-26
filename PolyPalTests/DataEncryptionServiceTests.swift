//
//  DataEncryptionServiceTests.swift
//  PolyPalTests
//
//  Created by Agent on 7/25/25.
//

import XCTest
import Security
@testable import PolyPal

class DataEncryptionServiceTests: XCTestCase {
    
    var encryptionService: DataEncryptionService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        encryptionService = DataEncryptionService()
    }
    
    override func tearDownWithError() throws {
        // Clean up keychain
        encryptionService.clearEncryptionKey()
        encryptionService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Encryption/Decryption Tests
    
    func testDataEncryptionDecryption() throws {
        // Given
        let originalData = "Hello, World! This is a test string with special characters: 🚀🔐".data(using: .utf8)!
        
        // When
        let encryptedData = try encryptionService.encrypt(originalData)
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then
        XCTAssertNotEqual(originalData, encryptedData, "Encrypted data should be different from original")
        XCTAssertEqual(originalData, decryptedData, "Decrypted data should match original")
        XCTAssertGreaterThan(encryptedData.count, originalData.count, "Encrypted data should be larger due to IV")
    }
    
    func testStringEncryptionDecryption() throws {
        // Given
        let originalString = "Test string with émojis 🔐 and special chars: !@#$%^&*()"
        
        // When
        let encryptedString = try encryptionService.encryptString(originalString)
        let decryptedString = try encryptionService.decryptString(encryptedString)
        
        // Then
        XCTAssertNotEqual(originalString, encryptedString, "Encrypted string should be different")
        XCTAssertEqual(originalString, decryptedString, "Decrypted string should match original")
        XCTAssertTrue(encryptedString.count > 0, "Encrypted string should not be empty")
    }
    
    func testEmptyDataEncryption() throws {
        // Given
        let emptyData = Data()
        
        // When
        let encryptedData = try encryptionService.encrypt(emptyData)
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then
        XCTAssertEqual(emptyData, decryptedData, "Empty data should decrypt to empty data")
        XCTAssertGreaterThan(encryptedData.count, 0, "Encrypted empty data should still have IV")
    }
    
    func testEmptyStringEncryption() throws {
        // Given
        let emptyString = ""
        
        // When
        let encryptedString = try encryptionService.encryptString(emptyString)
        let decryptedString = try encryptionService.decryptString(encryptedString)
        
        // Then
        XCTAssertEqual(emptyString, decryptedString, "Empty string should decrypt to empty string")
        XCTAssertGreaterThan(encryptedString.count, 0, "Encrypted empty string should still produce output")
    }
    
    // MARK: - Object Encryption Tests
    
    func testObjectEncryptionDecryption() throws {
        // Given
        struct TestObject: Codable, Equatable {
            let id: String
            let name: String
            let value: Int
            let isActive: Bool
        }
        
        let originalObject = TestObject(id: "123", name: "Test Object", value: 42, isActive: true)
        
        // When
        let encryptedData = try encryptionService.encryptObject(originalObject)
        let decryptedObject = try encryptionService.decryptObject(encryptedData, as: TestObject.self)
        
        // Then
        XCTAssertEqual(originalObject, decryptedObject, "Decrypted object should match original")
        XCTAssertGreaterThan(encryptedData.count, 0, "Encrypted data should not be empty")
    }
    
    func testComplexObjectEncryption() throws {
        // Given
        struct ComplexObject: Codable, Equatable {
            let strings: [String]
            let dictionary: [String: String]
            let optionalValue: String?
            let nestedObject: NestedObject
        }
        
        struct NestedObject: Codable, Equatable {
            let id: Int
            let data: [String: Int]
        }
        
        let originalObject = ComplexObject(
            strings: ["one", "two", "three"],
            dictionary: ["key1": "value1", "key2": "value2"],
            optionalValue: "optional",
            nestedObject: NestedObject(id: 456, data: ["count": 10, "total": 100])
        )
        
        // When
        let encryptedData = try encryptionService.encryptObject(originalObject)
        let decryptedObject = try encryptionService.decryptObject(encryptedData, as: ComplexObject.self)
        
        // Then
        XCTAssertEqual(originalObject, decryptedObject, "Complex object should decrypt correctly")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidEncryptedDataDecryption() {
        // Given
        let invalidData = Data([1, 2, 3, 4, 5]) // Too small to contain valid encrypted data
        
        // When/Then
        XCTAssertThrowsError(try encryptionService.decrypt(invalidData)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
            if let encryptionError = error as? EncryptionError {
                XCTAssertEqual(encryptionError, EncryptionError.invalidDataSize)
            }
        }
    }
    
    func testInvalidBase64StringDecryption() {
        // Given
        let invalidBase64 = "This is not valid base64!"
        
        // When/Then
        XCTAssertThrowsError(try encryptionService.decryptString(invalidBase64)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
            if let encryptionError = error as? EncryptionError {
                XCTAssertEqual(encryptionError, EncryptionError.base64DecodingFailed)
            }
        }
    }
    
    func testCorruptedEncryptedDataDecryption() {
        // Given
        let originalData = "Test data".data(using: .utf8)!
        let encryptedData = try! encryptionService.encrypt(originalData)
        
        // Corrupt the encrypted data
        var corruptedData = encryptedData
        corruptedData[corruptedData.count - 1] = corruptedData[corruptedData.count - 1] ^ 0xFF
        
        // When/Then
        XCTAssertThrowsError(try encryptionService.decrypt(corruptedData)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError for corrupted data")
        }
    }
    
    // MARK: - Key Management Tests
    
    func testKeyPersistence() throws {
        // Given
        let testData = "Test persistence".data(using: .utf8)!
        
        // When - Encrypt with first service instance
        let encryptedData = try encryptionService.encrypt(testData)
        
        // Create new service instance (should use same key from keychain)
        let newEncryptionService = DataEncryptionService()
        let decryptedData = try newEncryptionService.decrypt(encryptedData)
        
        // Then
        XCTAssertEqual(testData, decryptedData, "New service instance should use same key")
    }
    
    func testKeyRotation() throws {
        // Given
        let testData = "Test key rotation".data(using: .utf8)!
        let encryptedData = try encryptionService.encrypt(testData)
        
        // When
        try encryptionService.rotateEncryptionKey()
        
        // Then - Old encrypted data should not decrypt with new key
        XCTAssertThrowsError(try encryptionService.decrypt(encryptedData)) { _ in
            // Expected to fail with new key
        }
        
        // But new encryption should work
        let newEncryptedData = try encryptionService.encrypt(testData)
        let newDecryptedData = try encryptionService.decrypt(newEncryptedData)
        XCTAssertEqual(testData, newDecryptedData, "New key should work for new encryption")
    }
    
    func testKeyClearance() throws {
        // Given
        let testData = "Test key clearance".data(using: .utf8)!
        let encryptedData = try encryptionService.encrypt(testData)
        
        // When
        encryptionService.clearEncryptionKey()
        
        // Create new service instance (should generate new key)
        let newEncryptionService = DataEncryptionService()
        
        // Then - Old encrypted data should not decrypt with new key
        XCTAssertThrowsError(try newEncryptionService.decrypt(encryptedData)) { _ in
            // Expected to fail with new key
        }
    }
    
    // MARK: - Memory Security Tests
    
    func testSecureDataWipe() {
        // Given
        var sensitiveData = Data("Sensitive information".utf8)
        let originalCount = sensitiveData.count
        
        // When
        encryptionService.secureWipe(&sensitiveData)
        
        // Then
        XCTAssertEqual(sensitiveData.count, 0, "Data should be empty after secure wipe")
        XCTAssertNotEqual(sensitiveData.count, originalCount, "Data count should change")
    }
    
    func testSecureStringWipe() {
        // Given
        var sensitiveString = "Sensitive password"
        
        // When
        encryptionService.secureWipe(&sensitiveString)
        
        // Then
        XCTAssertEqual(sensitiveString, "", "String should be empty after secure wipe")
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformance() {
        // Given
        let largeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB of data
        
        // When/Then
        measure {
            do {
                let encryptedData = try encryptionService.encrypt(largeData)
                _ = try encryptionService.decrypt(encryptedData)
            } catch {
                XCTFail("Encryption/decryption should not fail: \(error)")
            }
        }
    }
    
    func testMultipleEncryptionConsistency() throws {
        // Given
        let testData = "Consistency test".data(using: .utf8)!
        
        // When - Encrypt same data multiple times
        let encrypted1 = try encryptionService.encrypt(testData)
        let encrypted2 = try encryptionService.encrypt(testData)
        let encrypted3 = try encryptionService.encrypt(testData)
        
        // Then - Each encryption should be different (due to random IV)
        XCTAssertNotEqual(encrypted1, encrypted2, "Each encryption should be unique")
        XCTAssertNotEqual(encrypted2, encrypted3, "Each encryption should be unique")
        XCTAssertNotEqual(encrypted1, encrypted3, "Each encryption should be unique")
        
        // But all should decrypt to same original data
        let decrypted1 = try encryptionService.decrypt(encrypted1)
        let decrypted2 = try encryptionService.decrypt(encrypted2)
        let decrypted3 = try encryptionService.decrypt(encrypted3)
        
        XCTAssertEqual(testData, decrypted1, "All should decrypt to original")
        XCTAssertEqual(testData, decrypted2, "All should decrypt to original")
        XCTAssertEqual(testData, decrypted3, "All should decrypt to original")
    }
    
    // MARK: - CryptoKit Tests (iOS 13+)
    
    @available(iOS 13.0, *)
    func testCryptoKitEncryption() throws {
        // Given
        let testData = "CryptoKit test data".data(using: .utf8)!
        
        // When
        let encryptedData = try encryptionService.encryptWithCryptoKit(testData)
        let decryptedData = try encryptionService.decryptWithCryptoKit(encryptedData)
        
        // Then
        XCTAssertEqual(testData, decryptedData, "CryptoKit encryption should work correctly")
        XCTAssertNotEqual(testData, encryptedData, "Encrypted data should be different")
    }
    
    @available(iOS 13.0, *)
    func testCryptoKitCompatibility() throws {
        // Given
        let testData = "Compatibility test".data(using: .utf8)!
        
        // When - Encrypt with CryptoKit, decrypt with CommonCrypto (should fail)
        let cryptoKitEncrypted = try encryptionService.encryptWithCryptoKit(testData)
        
        // Then - Should not be compatible
        XCTAssertThrowsError(try encryptionService.decrypt(cryptoKitEncrypted)) { _ in
            // Expected to fail - different encryption formats
        }
        
        // And vice versa
        let commonCryptoEncrypted = try encryptionService.encrypt(testData)
        XCTAssertThrowsError(try encryptionService.decryptWithCryptoKit(commonCryptoEncrypted)) { _ in
            // Expected to fail - different encryption formats
        }
    }
    
    // MARK: - Edge Cases
    
    func testLargeDataEncryption() throws {
        // Given
        let largeString = String(repeating: "A", count: 100000) // 100KB string
        
        // When
        let encryptedString = try encryptionService.encryptString(largeString)
        let decryptedString = try encryptionService.decryptString(encryptedString)
        
        // Then
        XCTAssertEqual(largeString, decryptedString, "Large data should encrypt/decrypt correctly")
    }
    
    func testUnicodeStringEncryption() throws {
        // Given
        let unicodeString = "🚀 Test with émojis and spëcial chärs: 中文 العربية русский 🔐"
        
        // When
        let encryptedString = try encryptionService.encryptString(unicodeString)
        let decryptedString = try encryptionService.decryptString(encryptedString)
        
        // Then
        XCTAssertEqual(unicodeString, decryptedString, "Unicode strings should encrypt/decrypt correctly")
    }
}

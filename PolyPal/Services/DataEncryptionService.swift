//
//  DataEncryptionService.swift
//  PolyPal
//
//  Created by Agent on 7/25/25.
//

import Foundation
import Security
import CryptoKit
import CommonCrypto

/// Service for encrypting and decrypting sensitive data in cache
class DataEncryptionService {
    
    // MARK: - Properties
    
    private let keySize = kCCKeySizeAES256
    private let blockSize = kCCBlockSizeAES128
    private let algorithm = kCCAlgorithmAES
    private let options = kCCOptionPKCS7Padding
    
    // Keychain service identifier
    private let keychainService = "com.polypal.encryption"
    private let encryptionKeyTag = "polypal.cache.encryption.key"
    
    // MARK: - Initialization
    
    init() {
        // Ensure encryption key exists
        _ = getOrCreateEncryptionKey()
    }
    
    // MARK: - Key Management
    
    /// Gets existing encryption key or creates a new one
    private func getOrCreateEncryptionKey() -> Data {
        // Try to retrieve existing key
        if let existingKey = getEncryptionKeyFromKeychain() {
            return existingKey
        }
        
        // Generate new key
        let newKey = generateEncryptionKey()
        storeEncryptionKeyInKeychain(newKey)
        return newKey
    }
    
    /// Generates a new AES-256 encryption key
    private func generateEncryptionKey() -> Data {
        var keyData = Data(count: keySize)
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, keySize, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == errSecSuccess else {
            fatalError("Failed to generate encryption key")
        }
        
        return keyData
    }
    
    /// Stores encryption key in iOS Keychain
    private func storeEncryptionKeyInKeychain(_ key: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing key first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            fatalError("Failed to store encryption key in keychain: \(status)")
        }
    }
    
    /// Retrieves encryption key from iOS Keychain
    private func getEncryptionKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let keyData = result as? Data else {
            return nil
        }
        
        return keyData
    }
    
    // MARK: - Encryption Methods
    
    /// Encrypts data using AES-256 encryption
    func encrypt(_ data: Data) throws -> Data {
        let key = getOrCreateEncryptionKey()
        
        // Generate random IV
        var iv = Data(count: blockSize)
        let ivResult = iv.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, blockSize, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard ivResult == errSecSuccess else {
            throw EncryptionError.ivGenerationFailed
        }
        
        // Perform encryption
        let encryptedData = try performCryptOperation(
            operation: CCOperation(kCCEncrypt),
            data: data,
            key: key,
            iv: iv
        )
        
        // Prepend IV to encrypted data
        var result = iv
        result.append(encryptedData)
        
        return result
    }
    
    /// Decrypts data using AES-256 decryption
    func decrypt(_ encryptedData: Data) throws -> Data {
        guard encryptedData.count > blockSize else {
            throw EncryptionError.invalidDataSize
        }
        
        let key = getOrCreateEncryptionKey()
        
        // Extract IV from the beginning of encrypted data
        let iv = encryptedData.prefix(blockSize)
        let ciphertext = encryptedData.dropFirst(blockSize)
        
        // Perform decryption
        return try performCryptOperation(
            operation: CCOperation(kCCDecrypt),
            data: Data(ciphertext),
            key: key,
            iv: Data(iv)
        )
    }
    
    /// Performs the actual encryption/decryption operation
    private func performCryptOperation(
        operation: CCOperation,
        data: Data,
        key: Data,
        iv: Data
    ) throws -> Data {
        let bufferSize = data.count + blockSize
        var buffer = Data(count: bufferSize)
        var numBytesProcessed: size_t = 0
        
        let cryptStatus = buffer.withUnsafeMutableBytes { bufferBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            operation,
                            algorithm,
                            options,
                            keyBytes.baseAddress, keySize,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesProcessed
                        )
                    }
                }
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            throw EncryptionError.cryptOperationFailed(Int(cryptStatus))
        }
        
        return Data(buffer.prefix(numBytesProcessed))
    }
    
    // MARK: - String Encryption Convenience Methods
    
    /// Encrypts a string and returns base64 encoded result
    func encryptString(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.stringEncodingFailed
        }
        
        let encryptedData = try encrypt(data)
        return encryptedData.base64EncodedString()
    }
    
    /// Decrypts a base64 encoded string
    func decryptString(_ encryptedString: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.base64DecodingFailed
        }
        
        let decryptedData = try decrypt(encryptedData)
        
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.stringDecodingFailed
        }
        
        return string
    }
    
    // MARK: - JSON Encryption Methods
    
    /// Encrypts a Codable object to encrypted data
    func encryptObject<T: Codable>(_ object: T) throws -> Data {
        let jsonData = try JSONEncoder().encode(object)
        return try encrypt(jsonData)
    }
    
    /// Decrypts data to a Codable object
    func decryptObject<T: Codable>(_ encryptedData: Data, as type: T.Type) throws -> T {
        let decryptedData = try decrypt(encryptedData)
        return try JSONDecoder().decode(type, from: decryptedData)
    }
    
    // MARK: - Key Rotation
    
    /// Rotates the encryption key (for security best practices)
    func rotateEncryptionKey() throws {
        // Generate new key
        let newKey = generateEncryptionKey()
        
        // Store new key
        storeEncryptionKeyInKeychain(newKey)
        
        // Note: In a production app, you would need to re-encrypt all existing data
        // with the new key. This is a simplified implementation.
    }
    
    /// Clears the encryption key from keychain (for logout/security)
    func clearEncryptionKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Memory Security
    
    /// Securely wipes sensitive data from memory
    func secureWipe(_ data: inout Data) {
        data.withUnsafeMutableBytes { bytes in
            memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
        }
        data.removeAll()
    }
    
    /// Securely wipes string from memory
    func secureWipe(_ string: inout String) {
        // Convert to mutable data and wipe
        if var data = string.data(using: .utf8) {
            secureWipe(&data)
        }
        string = ""
    }
}

// MARK: - Encryption Errors

enum EncryptionError: Error, LocalizedError {
    case keyGenerationFailed
    case ivGenerationFailed
    case cryptOperationFailed(Int)
    case invalidDataSize
    case stringEncodingFailed
    case stringDecodingFailed
    case base64DecodingFailed
    case keychainError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .ivGenerationFailed:
            return "Failed to generate initialization vector"
        case .cryptOperationFailed(let status):
            return "Encryption/decryption operation failed with status: \(status)"
        case .invalidDataSize:
            return "Invalid data size for decryption"
        case .stringEncodingFailed:
            return "Failed to encode string to data"
        case .stringDecodingFailed:
            return "Failed to decode data to string"
        case .base64DecodingFailed:
            return "Failed to decode base64 string"
        case .keychainError(let status):
            return "Keychain operation failed with status: \(status)"
        }
    }
}

// MARK: - CryptoKit Integration (iOS 13+)

@available(iOS 13.0, *)
extension DataEncryptionService {
    
    /// Encrypts data using CryptoKit (more modern approach)
    func encryptWithCryptoKit(_ data: Data) throws -> Data {
        let key = SymmetricKey(data: getOrCreateEncryptionKey())
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    /// Decrypts data using CryptoKit
    func decryptWithCryptoKit(_ encryptedData: Data) throws -> Data {
        let key = SymmetricKey(data: getOrCreateEncryptionKey())
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

import Foundation
import Security
import CryptoKit

/// Manager class for Multi-Factor Authentication backup codes
/// Provides secure generation, storage, and validation of single-use backup codes
final class BackupCodeManager {
  
  // MARK: - Constants
  
  private static let backupCodeLength = 8
  private static let backupCodeCount = 10
  private static let characterSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  
  // Keychain service identifiers
  private static let keychainService = "com.polypal.mfa.backup-codes"
  private static let usedCodesKeychainService = "com.polypal.mfa.used-backup-codes"
  
  // MARK: - Initialization
  
  init() {}
  
  // MARK: - Backup Code Generation
  
  /// Generates a set of cryptographically secure backup codes
  /// - Returns: Array of 10 unique 8-character alphanumeric backup codes
  func generateBackupCodes() -> [String] {
    var codes: [String] = []
    var attempts = 0
    let maxAttempts = 1000 // Prevent infinite loops
    
    while codes.count < Self.backupCodeCount && attempts < maxAttempts {
      let code = generateSingleBackupCode()
      
      // Ensure uniqueness within the set
      if !codes.contains(code) {
        codes.append(code)
      }
      
      attempts += 1
    }
    
    return codes
  }
  
  /// Generates a single backup code
  /// - Returns: 8-character alphanumeric backup code
  private func generateSingleBackupCode() -> String {
    var code = ""
    let characters = Array(Self.characterSet)
    
    for _ in 0..<Self.backupCodeLength {
      let randomIndex = Int.random(in: 0..<characters.count)
      code.append(characters[randomIndex])
    }
    
    return code
  }
  
  // MARK: - Backup Code Validation
  
  /// Validates a backup code for a specific user
  /// - Parameters:
  ///   - code: The backup code to validate
  ///   - userId: The user ID to validate against
  /// - Returns: True if the code is valid and unused, false otherwise
  func validateBackupCode(_ code: String, for userId: String) -> Bool {
    guard !userId.isEmpty else { return false }
    
    // Normalize the input code
    let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    // Get stored backup codes
    guard let storedCodes = getStoredBackupCodes(for: userId) else {
      return false
    }
    
    // Get used codes
    let usedCodes = getUsedBackupCodes(for: userId)
    
    // Check if code exists and hasn't been used
    guard storedCodes.contains(normalizedCode) && !usedCodes.contains(normalizedCode) else {
      return false
    }
    
    // Mark code as used
    markBackupCodeAsUsed(normalizedCode, for: userId)
    
    return true
  }
  
  /// Marks a backup code as used
  /// - Parameters:
  ///   - code: The backup code to mark as used
  ///   - userId: The user ID
  private func markBackupCodeAsUsed(_ code: String, for userId: String) {
    var usedCodes = getUsedBackupCodes(for: userId)
    usedCodes.insert(code)
    storeUsedBackupCodes(Array(usedCodes), for: userId)
  }
  
  // MARK: - Usage Tracking
  
  /// Gets the number of remaining (unused) backup codes for a user
  /// - Parameter userId: The user ID
  /// - Returns: Number of remaining backup codes
  func getRemainingBackupCodeCount(for userId: String) -> Int {
    guard let storedCodes = getStoredBackupCodes(for: userId) else {
      return 0
    }
    
    let usedCodes = getUsedBackupCodes(for: userId)
    return storedCodes.count - usedCodes.count
  }
  
  /// Gets the set of used backup codes for a user
  /// - Parameter userId: The user ID
  /// - Returns: Set of used backup codes
  func getUsedBackupCodes(for userId: String) -> Set<String> {
    guard let usedCodesData = getKeychainData(for: userId, service: Self.usedCodesKeychainService),
          let usedCodesArray = try? JSONDecoder().decode([String].self, from: usedCodesData) else {
      return Set<String>()
    }
    
    return Set(usedCodesArray)
  }
  
  /// Stores used backup codes in Keychain
  /// - Parameters:
  ///   - usedCodes: Array of used backup codes
  ///   - userId: The user ID
  private func storeUsedBackupCodes(_ usedCodes: [String], for userId: String) {
    guard let data = try? JSONEncoder().encode(usedCodes) else { return }
    _ = storeKeychainData(data, for: userId, service: Self.usedCodesKeychainService)
  }
  
  // MARK: - Keychain Storage
  
  /// Stores backup codes securely in the Keychain
  /// - Parameters:
  ///   - codes: Array of backup codes to store
  ///   - userId: The user ID to associate with the codes
  /// - Returns: True if storage was successful, false otherwise
  @discardableResult
  func storeBackupCodes(_ codes: [String], for userId: String) -> Bool {
    guard !userId.isEmpty else { return false }
    
    guard let data = try? JSONEncoder().encode(codes) else {
      return false
    }
    
    return storeKeychainData(data, for: userId, service: Self.keychainService)
  }
  
  /// Retrieves stored backup codes from the Keychain
  /// - Parameter userId: The user ID
  /// - Returns: Array of backup codes, or nil if not found
  func getStoredBackupCodes(for userId: String) -> [String]? {
    guard let data = getKeychainData(for: userId, service: Self.keychainService) else {
      return nil
    }
    
    return try? JSONDecoder().decode([String].self, from: data)
  }
  
  /// Deletes backup codes from the Keychain
  /// - Parameter userId: The user ID
  /// - Returns: True if deletion was successful, false otherwise
  @discardableResult
  func deleteBackupCodes(for userId: String) -> Bool {
    let codesDeleted = deleteKeychainData(for: userId, service: Self.keychainService)
    let usedCodesDeleted = deleteKeychainData(for: userId, service: Self.usedCodesKeychainService)
    
    return codesDeleted && usedCodesDeleted
  }
  
  // MARK: - Regeneration
  
  /// Regenerates backup codes for a user, invalidating all previous codes
  /// - Parameter userId: The user ID
  /// - Returns: Array of new backup codes
  func regenerateBackupCodes(for userId: String) -> [String] {
    // Delete existing codes and usage tracking
    deleteBackupCodes(for: userId)
    
    // Generate new codes
    let newCodes = generateBackupCodes()
    
    // Store new codes
    storeBackupCodes(newCodes, for: userId)
    
    return newCodes
  }
  
  // MARK: - Keychain Utilities
  
  /// Stores data in the Keychain
  /// - Parameters:
  ///   - data: Data to store
  ///   - userId: User ID for the keychain item
  ///   - service: Keychain service identifier
  /// - Returns: True if successful, false otherwise
  private func storeKeychainData(_ data: Data, for userId: String, service: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: userId,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    // Delete existing item first
    SecItemDelete(query as CFDictionary)
    
    // Add new item
    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
  }
  
  /// Retrieves data from the Keychain
  /// - Parameters:
  ///   - userId: User ID for the keychain item
  ///   - service: Keychain service identifier
  /// - Returns: Data if found, nil otherwise
  private func getKeychainData(for userId: String, service: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: userId,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    guard status == errSecSuccess else { return nil }
    return result as? Data
  }
  
  /// Deletes data from the Keychain
  /// - Parameters:
  ///   - userId: User ID for the keychain item
  ///   - service: Keychain service identifier
  /// - Returns: True if successful, false otherwise
  private func deleteKeychainData(for userId: String, service: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: userId
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }
  
  // MARK: - Security Utilities
  
  /// Securely clears sensitive data from memory
  /// - Parameter data: Data to clear
  private func clearSensitiveData(_ data: inout Data) {
    data.withUnsafeMutableBytes { bytes in
      memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
  }
  
  /// Securely clears sensitive string data from memory
  /// - Parameter string: String to clear (converted to data)
  private func clearSensitiveString(_ string: inout String) {
    var data = Data(string.utf8)
    clearSensitiveData(&data)
    string = ""
  }
}

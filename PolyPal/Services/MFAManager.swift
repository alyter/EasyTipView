import Foundation
import CryptoKit
import Security

/// Manager class for Multi-Factor Authentication using Time-based One-Time Passwords (TOTP)
/// Implements RFC 6238 compliant TOTP generation and validation
final class MFAManager {
  
  // MARK: - Constants
  
  private static let timeWindow: TimeInterval = 30 // 30-second time windows
  private static let codeLength = 6 // 6-digit TOTP codes
  private static let clockDriftTolerance = 1 // ±1 time window tolerance
  private static let secretKeyLength = 32 // 160 bits as recommended by RFC 6238
  
  // MARK: - Base32 Character Set
  
  private static let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
  private static let base32CharacterSet = CharacterSet(charactersIn: base32Alphabet + "=")
  
  // MARK: - Initialization
  
  init() {}
  
  // MARK: - Secret Key Generation
  
  /// Generates a cryptographically secure random secret key for TOTP
  /// - Returns: 32-byte (160-bit) secret key as Data
  func generateSecretKey() -> Data {
    var keyData = Data(count: Self.secretKeyLength)
    let result = keyData.withUnsafeMutableBytes { bytes in
      SecRandomCopyBytes(kSecRandomDefault, Self.secretKeyLength, bytes.bindMemory(to: UInt8.self).baseAddress!)
    }
    
    guard result == errSecSuccess else {
      // Fallback to CryptoKit if SecRandomCopyBytes fails
      return Data((0..<Self.secretKeyLength).map { _ in UInt8.random(in: 0...255) })
    }
    
    return keyData
  }
  
  // MARK: - Base32 Encoding/Decoding
  
  /// Encodes data to Base32 string format
  /// - Parameter data: Data to encode
  /// - Returns: Base32 encoded string
  func base32Encode(_ data: Data) -> String {
    guard !data.isEmpty else { return "" }
    
    let bytes = Array(data)
    var result = ""
    var buffer = 0
    var bitsLeft = 0
    
    for byte in bytes {
      buffer = (buffer << 8) | Int(byte)
      bitsLeft += 8
      
      while bitsLeft >= 5 {
        let index = (buffer >> (bitsLeft - 5)) & 0x1F
        result.append(Self.base32Alphabet[Self.base32Alphabet.index(Self.base32Alphabet.startIndex, offsetBy: index)])
        bitsLeft -= 5
      }
    }
    
    if bitsLeft > 0 {
      let index = (buffer << (5 - bitsLeft)) & 0x1F
      result.append(Self.base32Alphabet[Self.base32Alphabet.index(Self.base32Alphabet.startIndex, offsetBy: index)])
    }
    
    // Add padding
    let paddingLength = (8 - (result.count % 8)) % 8
    result += String(repeating: "=", count: paddingLength)
    
    return result
  }
  
  /// Decodes Base32 string to data
  /// - Parameter string: Base32 encoded string
  /// - Returns: Decoded data, or nil if invalid
  func base32Decode(_ string: String) -> Data? {
    let cleanString = string.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Validate character set
    guard cleanString.rangeOfCharacter(from: Self.base32CharacterSet.inverted) == nil else {
      return nil
    }
    
    // Remove padding
    let noPadding = cleanString.trimmingCharacters(in: CharacterSet(charactersIn: "="))
    
    guard !noPadding.isEmpty else { return Data() }
    
    var result = Data()
    var buffer = 0
    var bitsLeft = 0
    
    for char in noPadding {
      guard let index = Self.base32Alphabet.firstIndex(of: char) else {
        return nil
      }
      
      let value = Self.base32Alphabet.distance(from: Self.base32Alphabet.startIndex, to: index)
      buffer = (buffer << 5) | value
      bitsLeft += 5
      
      if bitsLeft >= 8 {
        let byte = UInt8((buffer >> (bitsLeft - 8)) & 0xFF)
        result.append(byte)
        bitsLeft -= 8
      }
    }
    
    return result
  }
  
  // MARK: - Time Window Calculation
  
  /// Calculates the time window for a given timestamp
  /// - Parameter timestamp: Unix timestamp
  /// - Returns: Time window number
  func getTimeWindow(timestamp: TimeInterval) -> Int64 {
    return Int64(timestamp / Self.timeWindow)
  }
  
  // MARK: - TOTP Generation
  
  /// Generates a TOTP code for the given secret key and timestamp
  /// - Parameters:
  ///   - secretKey: Secret key data
  ///   - timestamp: Unix timestamp (defaults to current time)
  /// - Returns: 6-digit TOTP code, or nil if generation fails
  func generateTOTP(secretKey: Data, timestamp: TimeInterval = Date().timeIntervalSince1970) -> String? {
    guard !secretKey.isEmpty else { return nil }
    
    let timeWindow = getTimeWindow(timestamp: timestamp)
    let timeData = withUnsafeBytes(of: timeWindow.bigEndian) { Data($0) }
    
    // Generate HMAC-SHA1
    let key = SymmetricKey(data: secretKey)
    let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: timeData, using: key)
    let hmacData = Data(hmac)
    
    // Dynamic truncation as per RFC 6238
    let offset = Int(hmacData[hmacData.count - 1] & 0x0F)
    let truncatedHash = hmacData.subdata(in: offset..<(offset + 4))
    
    let code = truncatedHash.withUnsafeBytes { bytes in
      let pointer = bytes.bindMemory(to: UInt32.self)
      return UInt32(bigEndian: pointer[0]) & 0x7FFFFFFF
    }
    
    let totpCode = code % UInt32(pow(10, Double(Self.codeLength)))
    return String(format: "%0\(Self.codeLength)d", totpCode)
  }
  
  // MARK: - TOTP Validation
  
  /// Validates a TOTP code against the secret key
  /// - Parameters:
  ///   - code: TOTP code to validate
  ///   - secretKey: Secret key data
  ///   - timestamp: Unix timestamp (defaults to current time)
  /// - Returns: True if code is valid, false otherwise
  func validateTOTP(code: String, secretKey: Data, timestamp: TimeInterval = Date().timeIntervalSince1970) -> Bool {
    // Validate code format
    guard code.count == Self.codeLength,
          code.allSatisfy({ $0.isNumber }) else {
      return false
    }
    
    // Check current time window and adjacent windows for clock drift tolerance
    let currentWindow = getTimeWindow(timestamp: timestamp)
    
    for windowOffset in -Self.clockDriftTolerance...Self.clockDriftTolerance {
      let testWindow = currentWindow + Int64(windowOffset)
      let testTimestamp = TimeInterval(testWindow) * Self.timeWindow
      
      if let expectedCode = generateTOTP(secretKey: secretKey, timestamp: testTimestamp),
         expectedCode == code {
        return true
      }
    }
    
    return false
  }
  
  // MARK: - Utility Methods
  
  /// Securely clears sensitive data from memory
  /// - Parameter data: Data to clear
  private func clearSensitiveData(_ data: inout Data) {
    data.withUnsafeMutableBytes { bytes in
      memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
  }
}

// MARK: - Extensions

extension MFAManager {
  
  /// Generates an otpauth:// URL for QR code generation
  /// - Parameters:
  ///   - secretKey: Base32 encoded secret key
  ///   - accountName: User's account identifier (email)
  ///   - issuer: Service name (defaults to "PolyPal")
  /// - Returns: otpauth URL string
  func generateOTPAuthURL(secretKey: String, accountName: String, issuer: String = "PolyPal") -> String {
    let encodedAccount = accountName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? accountName
    let encodedIssuer = issuer.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? issuer
    
    return "otpauth://totp/\(encodedIssuer):\(encodedAccount)?secret=\(secretKey)&issuer=\(encodedIssuer)&algorithm=SHA1&digits=\(Self.codeLength)&period=\(Int(Self.timeWindow))"
  }
}

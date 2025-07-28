import Foundation
import CoreImage

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Manages QR code generation for MFA setup
class QRCodeManager {
  
  // MARK: - Properties
  
  private let context = CIContext()
  
  // MARK: - Initialization
  
  init() {}
  
  // MARK: - OTPAuth URL Generation
  
  /// Generates an OTPAuth URL for TOTP setup
  /// - Parameters:
  ///   - secret: Base32 encoded secret key
  ///   - accountName: User's account identifier (usually email)
  ///   - issuer: Service name (e.g., "PolyPal")
  ///   - period: Time period in seconds (default: 30)
  ///   - digits: Number of digits in TOTP code (default: 6)
  ///   - algorithm: Hash algorithm (default: SHA1)
  /// - Returns: OTPAuth URL or nil if invalid parameters
  func generateOTPAuthURL(
    secret: String,
    accountName: String,
    issuer: String,
    period: Int = 30,
    digits: Int = 6,
    algorithm: String = "SHA1"
  ) -> URL? {
    // Validate required parameters
    guard !secret.isEmpty,
          !accountName.isEmpty,
          !issuer.isEmpty else {
      return nil
    }
    
    // URL encode the components
    guard let encodedAccountName = accountName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let encodedIssuer = issuer.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
      return nil
    }
    
    // Build the OTPAuth URL
    var components = URLComponents()
    components.scheme = "otpauth"
    components.host = "totp"
    components.path = "/\(encodedIssuer):\(encodedAccountName)"
    
    // Add query parameters
    components.queryItems = [
      URLQueryItem(name: "secret", value: secret),
      URLQueryItem(name: "issuer", value: issuer),
      URLQueryItem(name: "algorithm", value: algorithm),
      URLQueryItem(name: "digits", value: String(digits)),
      URLQueryItem(name: "period", value: String(period))
    ]
    
    return components.url
  }
  
  // MARK: - QR Code Image Generation
  
  /// Generates a QR code image from a URL
  /// - Parameters:
  ///   - url: The URL to encode
  ///   - size: Desired image size (default: 200x200)
  /// - Returns: PlatformImage containing the QR code or nil if generation fails
  func generateQRCodeImage(from url: URL, size: CGSize = CGSize(width: 200, height: 200)) -> PlatformImage? {
    return generateQRCodeImage(from: url.absoluteString, size: size)
  }
  
  /// Generates a QR code image from a string
  /// - Parameters:
  ///   - string: The string to encode
  ///   - size: Desired image size (default: 200x200)
  /// - Returns: PlatformImage containing the QR code or nil if generation fails
  func generateQRCodeImage(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> PlatformImage? {
    guard !string.isEmpty else { return nil }
    
    // Convert string to data
    guard let data = string.data(using: .utf8) else { return nil }
    
    // Create QR code filter
    guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    qrFilter.setValue(data, forKey: "inputMessage")
    qrFilter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction
    
    // Get the QR code image
    guard let qrCodeImage = qrFilter.outputImage else { return nil }
    
    // Scale the image to desired size
    let scaleX = size.width / qrCodeImage.extent.width
    let scaleY = size.height / qrCodeImage.extent.height
    let scaledImage = qrCodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    
    // Convert to platform image
    guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
    
    #if canImport(AppKit)
    return NSImage(cgImage: cgImage, size: size)
    #else
    return UIImage(cgImage: cgImage)
    #endif
  }
  
  // MARK: - Image Data Conversion
  
  /// Converts a QR code PlatformImage to PNG data
  /// - Parameter image: The PlatformImage to convert
  /// - Returns: PNG data or nil if conversion fails
  func qrCodeImageToPNGData(_ image: PlatformImage?) -> Data? {
    guard let image = image else { return nil }
    
    #if canImport(AppKit)
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    return bitmapRep.representation(using: .png, properties: [:])
    #else
    return image.pngData()
    #endif
  }
  
  /// Converts a QR code PlatformImage to JPEG data
  /// - Parameters:
  ///   - image: The PlatformImage to convert
  ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
  /// - Returns: JPEG data or nil if conversion fails
  func qrCodeImageToJPEGData(_ image: PlatformImage?, compressionQuality: CGFloat = 0.8) -> Data? {
    guard let image = image else { return nil }
    
    #if canImport(AppKit)
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    #else
    return image.jpegData(compressionQuality: compressionQuality)
    #endif
  }
  
  // MARK: - Utility Methods
  
  /// Validates if a string is a valid OTPAuth URL
  /// - Parameter urlString: The URL string to validate
  /// - Returns: True if valid OTPAuth URL, false otherwise
  func isValidOTPAuthURL(_ urlString: String) -> Bool {
    guard let url = URL(string: urlString) else { return false }
    
    return url.scheme == "otpauth" &&
           url.host == "totp" &&
           url.absoluteString.contains("secret=") &&
           url.absoluteString.contains("issuer=")
  }
  
  /// Extracts the secret from an OTPAuth URL
  /// - Parameter url: The OTPAuth URL
  /// - Returns: The secret string or nil if not found
  func extractSecret(from url: URL) -> String? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
      return nil
    }
    
    return queryItems.first { $0.name == "secret" }?.value
  }
  
  /// Extracts the issuer from an OTPAuth URL
  /// - Parameter url: The OTPAuth URL
  /// - Returns: The issuer string or nil if not found
  func extractIssuer(from url: URL) -> String? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
      return nil
    }
    
    return queryItems.first { $0.name == "issuer" }?.value
  }
  
  /// Extracts the account name from an OTPAuth URL path
  /// - Parameter url: The OTPAuth URL
  /// - Returns: The account name or nil if not found
  func extractAccountName(from url: URL) -> String? {
    let path = url.path
    
    // Path format: /Issuer:AccountName
    if let colonIndex = path.firstIndex(of: ":") {
      let accountPart = String(path[path.index(after: colonIndex)...])
      return accountPart.removingPercentEncoding
    }
    
    return nil
  }
}

// MARK: - Error Types

extension QRCodeManager {
  enum QRCodeError: Error, LocalizedError {
    case invalidInput
    case generationFailed
    case conversionFailed
    
    var errorDescription: String? {
      switch self {
      case .invalidInput:
        return "Invalid input parameters for QR code generation"
      case .generationFailed:
        return "Failed to generate QR code image"
      case .conversionFailed:
        return "Failed to convert image to data"
      }
    }
  }
}

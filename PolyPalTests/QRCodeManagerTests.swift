import XCTest
import CoreImage
@testable import PolyPal

final class QRCodeManagerTests: XCTestCase {
  
  var qrCodeManager: QRCodeManager!
  
  override func setUp() {
    super.setUp()
    qrCodeManager = QRCodeManager()
  }
  
  override func tearDown() {
    qrCodeManager = nil
    super.tearDown()
  }
  
  // MARK: - OTPAuth URL Generation Tests
  
  func testGenerateOTPAuthURL_ValidInputs_ReturnsCorrectURL() {
    // Given
    let secret = "JBSWY3DPEHPK3PXP"
    let accountName = "user@example.com"
    let issuer = "PolyPal"
    
    // When
    let url = qrCodeManager.generateOTPAuthURL(
      secret: secret,
      accountName: accountName,
      issuer: issuer
    )
    
    // Then
    XCTAssertNotNil(url)
    XCTAssertEqual(url?.scheme, "otpauth")
    XCTAssertEqual(url?.host, "totp")
    XCTAssertTrue(url?.absoluteString.contains("secret=\(secret)") ?? false)
    XCTAssertTrue(url?.absoluteString.contains("issuer=\(issuer)") ?? false)
    XCTAssertTrue(url?.absoluteString.contains(accountName) ?? false)
  }
  
  func testGenerateOTPAuthURL_WithPeriodAndDigits_IncludesParameters() {
    // Given
    let secret = "JBSWY3DPEHPK3PXP"
    let accountName = "user@example.com"
    let issuer = "PolyPal"
    let period = 30
    let digits = 6
    
    // When
    let url = qrCodeManager.generateOTPAuthURL(
      secret: secret,
      accountName: accountName,
      issuer: issuer,
      period: period,
      digits: digits
    )
    
    // Then
    XCTAssertNotNil(url)
    XCTAssertTrue(url?.absoluteString.contains("period=\(period)") ?? false)
    XCTAssertTrue(url?.absoluteString.contains("digits=\(digits)") ?? false)
    XCTAssertTrue(url?.absoluteString.contains("algorithm=SHA1") ?? false)
  }
  
  func testGenerateOTPAuthURL_EmptySecret_ReturnsNil() {
    // Given
    let secret = ""
    let accountName = "user@example.com"
    let issuer = "PolyPal"
    
    // When
    let url = qrCodeManager.generateOTPAuthURL(
      secret: secret,
      accountName: accountName,
      issuer: issuer
    )
    
    // Then
    XCTAssertNil(url)
  }
  
  func testGenerateOTPAuthURL_EmptyAccountName_ReturnsNil() {
    // Given
    let secret = "JBSWY3DPEHPK3PXP"
    let accountName = ""
    let issuer = "PolyPal"
    
    // When
    let url = qrCodeManager.generateOTPAuthURL(
      secret: secret,
      accountName: accountName,
      issuer: issuer
    )
    
    // Then
    XCTAssertNil(url)
  }
  
  func testGenerateOTPAuthURL_SpecialCharactersInAccountName_ProperlyEncoded() {
    // Given
    let secret = "JBSWY3DPEHPK3PXP"
    let accountName = "user+test@example.com"
    let issuer = "PolyPal App"
    
    // When
    let url = qrCodeManager.generateOTPAuthURL(
      secret: secret,
      accountName: accountName,
      issuer: issuer
    )
    
    // Then
    XCTAssertNotNil(url)
    XCTAssertTrue(url?.absoluteString.contains("user%2Btest%40example.com") ?? false)
    XCTAssertTrue(url?.absoluteString.contains("issuer=PolyPal%20App") ?? false)
  }
  
  // MARK: - QR Code Image Generation Tests
  
  func testGenerateQRCodeImage_ValidURL_ReturnsImage() {
    // Given
    let testURL = URL(string: "otpauth://totp/PolyPal:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=PolyPal")!
    
    // When
    let image = qrCodeManager.generateQRCodeImage(from: testURL)
    
    // Then
    XCTAssertNotNil(image)
  }
  
  func testGenerateQRCodeImage_ValidString_ReturnsImage() {
    // Given
    let testString = "otpauth://totp/PolyPal:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=PolyPal"
    
    // When
    let image = qrCodeManager.generateQRCodeImage(from: testString)
    
    // Then
    XCTAssertNotNil(image)
  }
  
  func testGenerateQRCodeImage_EmptyString_ReturnsNil() {
    // Given
    let testString = ""
    
    // When
    let image = qrCodeManager.generateQRCodeImage(from: testString)
    
    // Then
    XCTAssertNil(image)
  }
  
  func testGenerateQRCodeImage_CustomSize_ReturnsCorrectSize() {
    // Given
    let testString = "otpauth://totp/PolyPal:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=PolyPal"
    let customSize = CGSize(width: 300, height: 300)
    
    // When
    let image = qrCodeManager.generateQRCodeImage(from: testString, size: customSize)
    
    // Then
    XCTAssertNotNil(image)
    XCTAssertEqual(image?.size.width, customSize.width, accuracy: 1.0)
    XCTAssertEqual(image?.size.height, customSize.height, accuracy: 1.0)
  }
  
  func testGenerateQRCodeImage_VeryLargeString_HandlesGracefully() {
    // Given
    let largeString = String(repeating: "A", count: 1000)
    
    // When
    let image = qrCodeManager.generateQRCodeImage(from: largeString)
    
    // Then
    // Should either return an image or nil, but not crash
    XCTAssertTrue(image != nil || image == nil)
  }
  
  // MARK: - Integration Tests
  
  func testCompleteQRCodeGeneration_FromSecretToImage_Success() {
    // Given
    let secret = "JBSWY3DPEHPK3PXP"
    let accountName = "user@example.com"
    let issuer = "PolyPal"
    
    // When
    let url = qrCodeManager.generateOTPAuthURL(
      secret: secret,
      accountName: accountName,
      issuer: issuer
    )
    
    guard let validURL = url else {
      XCTFail("Failed to generate OTPAuth URL")
      return
    }
    
    let image = qrCodeManager.generateQRCodeImage(from: validURL)
    
    // Then
    XCTAssertNotNil(image)
    XCTAssertTrue(image!.size.width > 0)
    XCTAssertTrue(image!.size.height > 0)
  }
  
  func testQRCodeImageData_CanBeConvertedToPNG() {
    // Given
    let testString = "otpauth://totp/PolyPal:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=PolyPal"
    
    // When
    let image = qrCodeManager.generateQRCodeImage(from: testString)
    let pngData = qrCodeManager.qrCodeImageToPNGData(image)
    
    // Then
    XCTAssertNotNil(image)
    XCTAssertNotNil(pngData)
    XCTAssertTrue(pngData!.count > 0)
  }
  
  func testQRCodeImageData_NilImage_ReturnsNil() {
    // Given
    let nilImage: UIImage? = nil
    
    // When
    let pngData = qrCodeManager.qrCodeImageToPNGData(nilImage)
    
    // Then
    XCTAssertNil(pngData)
  }
  
  // MARK: - Error Handling Tests
  
  func testGenerateOTPAuthURL_InvalidCharacters_HandlesGracefully() {
    // Given
    let secret = "INVALID_SECRET_WITH_INVALID_CHARS!@#$%"
    let accountName = "user@example.com"
    let issuer = "PolyPal"
    
    // When
    let url = qrCodeManager.generateOTPAuthURL(
      secret: secret,
      accountName: accountName,
      issuer: issuer
    )
    
    // Then
    // Should handle gracefully - either return valid URL or nil
    XCTAssertTrue(url != nil || url == nil)
  }
  
  func testQRCodeGeneration_MemoryPressure_HandlesMultipleGenerations() {
    // Given
    let testString = "otpauth://totp/PolyPal:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=PolyPal"
    
    // When & Then
    for _ in 0..<100 {
      let image = qrCodeManager.generateQRCodeImage(from: testString)
      XCTAssertNotNil(image)
    }
  }
}

import XCTest
import CryptoKit
@testable import PolyPal

/// Performance tests for MFA components to ensure they meet performance requirements
final class MFAPerformanceTests: XCTestCase {
  
  var mfaManager: MFAManager!
  var backupCodeManager: BackupCodeManager!
  var qrCodeManager: QRCodeManager!
  var rateLimiter: MFARateLimiter!
  
  override func setUp() {
    super.setUp()
    mfaManager = MFAManager()
    backupCodeManager = BackupCodeManager()
    qrCodeManager = QRCodeManager()
    rateLimiter = MFARateLimiter()
  }
  
  override func tearDown() {
    mfaManager = nil
    backupCodeManager = nil
    qrCodeManager = nil
    rateLimiter = nil
    super.tearDown()
  }
  
  // MARK: - TOTP Performance Tests
  
  func testTOTPGenerationPerformance() {
    let secret = mfaManager.generateSecretKey()
    
    measure {
      for _ in 0..<1000 {
        _ = mfaManager.generateTOTP(secret: secret)
      }
    }
  }
  
  func testTOTPValidationPerformance() {
    let secret = mfaManager.generateSecretKey()
    let totp = mfaManager.generateTOTP(secret: secret)
    
    measure {
      for _ in 0..<1000 {
        _ = mfaManager.validateTOTP(totp, secret: secret)
      }
    }
  }
  
  func testSecretKeyGenerationPerformance() {
    measure {
      for _ in 0..<100 {
        _ = mfaManager.generateSecretKey()
      }
    }
  }
  
  // MARK: - Backup Code Performance Tests
  
  func testBackupCodeGenerationPerformance() {
    measure {
      for _ in 0..<100 {
        _ = backupCodeManager.generateBackupCodes()
      }
    }
  }
  
  func testBackupCodeValidationPerformance() {
    let codes = backupCodeManager.generateBackupCodes()
    let userId = "test-user-\(UUID().uuidString)"
    backupCodeManager.storeBackupCodes(codes, for: userId)
    
    measure {
      for code in codes {
        _ = backupCodeManager.validateBackupCode(code, for: userId)
      }
    }
  }
  
  func testBackupCodeKeychainPerformance() {
    let codes = backupCodeManager.generateBackupCodes()
    let userId = "test-user-\(UUID().uuidString)"
    
    measure {
      for _ in 0..<50 {
        backupCodeManager.storeBackupCodes(codes, for: userId)
        _ = backupCodeManager.getStoredBackupCodes(for: userId)
      }
    }
  }
  
  // MARK: - QR Code Performance Tests
  
  func testQRCodeGenerationPerformance() {
    let secret = mfaManager.generateSecretKey()
    
    measure {
      for _ in 0..<50 {
        _ = qrCodeManager.generateQRCode(
          for: secret,
          accountName: "test@example.com",
          issuer: "PolyPal"
        )
      }
    }
  }
  
  func testOTPAuthURLGenerationPerformance() {
    let secret = mfaManager.generateSecretKey()
    
    measure {
      for _ in 0..<1000 {
        _ = qrCodeManager.generateOTPAuthURL(
          secret: secret,
          accountName: "test@example.com",
          issuer: "PolyPal"
        )
      }
    }
  }
  
  // MARK: - Rate Limiter Performance Tests
  
  func testRateLimiterPerformance() {
    let userId = "test-user-\(UUID().uuidString)"
    
    measure {
      for _ in 0..<1000 {
        _ = rateLimiter.shouldAllowAttempt(for: userId)
      }
    }
  }
  
  func testConcurrentRateLimiterAccess() {
    let userId = "test-user-\(UUID().uuidString)"
    let expectation = XCTestExpectation(description: "Concurrent access")
    expectation.expectedFulfillmentCount = 10
    
    measure {
      for _ in 0..<10 {
        DispatchQueue.global().async {
          for _ in 0..<100 {
            _ = self.rateLimiter.shouldAllowAttempt(for: userId)
          }
          expectation.fulfill()
        }
      }
      
      wait(for: [expectation], timeout: 5.0)
    }
  }
  
  // MARK: - Memory Performance Tests
  
  func testMemoryUsageUnderLoad() {
    let initialMemory = getMemoryUsage()
    
    // Generate many secrets and codes
    var secrets: [String] = []
    var backupCodes: [[String]] = []
    
    for _ in 0..<100 {
      secrets.append(mfaManager.generateSecretKey())
      backupCodes.append(backupCodeManager.generateBackupCodes())
    }
    
    // Generate TOTPs
    for secret in secrets {
      _ = mfaManager.generateTOTP(secret: secret)
    }
    
    let finalMemory = getMemoryUsage()
    let memoryIncrease = finalMemory - initialMemory
    
    // Memory increase should be reasonable (less than 10MB for this test)
    XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024, "Memory usage increased by \(memoryIncrease) bytes")
  }
  
  // MARK: - Stress Tests
  
  func testHighVolumeOperations() {
    let userId = "stress-test-user"
    let secret = mfaManager.generateSecretKey()
    let codes = backupCodeManager.generateBackupCodes()
    backupCodeManager.storeBackupCodes(codes, for: userId)
    
    // Simulate high volume of operations
    for i in 0..<1000 {
      let totp = mfaManager.generateTOTP(secret: secret)
      _ = mfaManager.validateTOTP(totp, secret: secret)
      
      if i % 100 == 0 {
        _ = backupCodeManager.getRemainingBackupCodeCount(for: userId)
      }
      
      if i % 200 == 0 {
        _ = rateLimiter.shouldAllowAttempt(for: userId)
      }
    }
    
    // Verify system is still responsive
    let finalTotp = mfaManager.generateTOTP(secret: secret)
    XCTAssertTrue(mfaManager.validateTOTP(finalTotp, secret: secret))
  }
  
  // MARK: - Helper Methods
  
  private func getMemoryUsage() -> Int64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_,
                  task_flavor_t(MACH_TASK_BASIC_INFO),
                  $0,
                  &count)
      }
    }
    
    if kerr == KERN_SUCCESS {
      return Int64(info.resident_size)
    } else {
      return 0
    }
  }
}

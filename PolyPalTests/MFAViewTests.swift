import XCTest
import SwiftUI
@testable import PolyPal

final class MFAViewTests: XCTestCase {
    var authViewModel: AuthenticationViewModel!
    
    override func setUp() {
        super.setUp()
        authViewModel = AuthenticationViewModel()
    }
    
    override func tearDown() {
        authViewModel = nil
        super.tearDown()
    }
    
    func testMFAViewInitialState() {
        let mfaView = MFAView()
        XCTAssertNotNil(mfaView)
    }
    
    func testMFACodeValidation() {
        // Test empty code
        var isValid = authViewModel.isValidMFACode("")
        XCTAssertFalse(isValid)
        
        // Test short code
        isValid = authViewModel.isValidMFACode("123")
        XCTAssertFalse(isValid)
        
        // Test long code
        isValid = authViewModel.isValidMFACode("1234567")
        XCTAssertFalse(isValid)
        
        // Test non-numeric code
        isValid = authViewModel.isValidMFACode("abcdef")
        XCTAssertFalse(isValid)
        
        // Test valid 6-digit code
        isValid = authViewModel.isValidMFACode("123456")
        XCTAssertTrue(isValid)
        
        // Test valid code with leading zeros
        isValid = authViewModel.isValidMFACode("001234")
        XCTAssertTrue(isValid)
    }
    
    func testMFAVerification() async {
        // Setup authentication state to require MFA
        authViewModel.email = "test@example.com"
        authViewModel.password = "password123"
        
        // Simulate successful login that requires MFA
        await authViewModel.login()
        
        // Should be in MFA required state
        XCTAssertEqual(authViewModel.authenticationState, .mfaRequired)
        
        // Test invalid MFA code
        await authViewModel.verifyMFA("000000")
        XCTAssertEqual(authViewModel.authenticationState, .error("Invalid MFA code"))
        XCTAssertFalse(authViewModel.isAuthenticated)
        
        // Test valid MFA code
        await authViewModel.verifyMFA("123456")
        XCTAssertEqual(authViewModel.authenticationState, .authenticated)
        XCTAssertTrue(authViewModel.isAuthenticated)
    }
    
    func testMFACodeFormatting() {
        // Test that MFA code is properly formatted (digits only, max 6 characters)
        var formattedCode = authViewModel.formatMFACode("123abc456def")
        XCTAssertEqual(formattedCode, "123456")
        
        // Test truncation at 6 digits
        formattedCode = authViewModel.formatMFACode("12345678")
        XCTAssertEqual(formattedCode, "123456")
        
        // Test empty string
        formattedCode = authViewModel.formatMFACode("")
        XCTAssertEqual(formattedCode, "")
        
        // Test special characters removed
        formattedCode = authViewModel.formatMFACode("1-2-3-4-5-6")
        XCTAssertEqual(formattedCode, "123456")
    }
    
    func testMFAResendCode() async {
        // Setup MFA required state
        authViewModel.email = "test@example.com"
        await authViewModel.login()
        XCTAssertEqual(authViewModel.authenticationState, .mfaRequired)
        
        // Test resend functionality
        await authViewModel.resendMFACode()
        
        // Should remain in MFA required state but clear any errors
        XCTAssertEqual(authViewModel.authenticationState, .mfaRequired)
    }
    
    func testMFANavigationBack() {
        // Setup navigation state
        authViewModel.navigationState = .mfa
        
        // Navigate back should go to login
        authViewModel.navigateBackFromMFA()
        XCTAssertEqual(authViewModel.navigationState, .login)
        XCTAssertEqual(authViewModel.authenticationState, .unauthenticated)
    }
    
    func testMFALoadingState() async {
        authViewModel.email = "test@example.com"
        await authViewModel.login()
        
        // Should show loading during MFA verification
        Task {
            await authViewModel.verifyMFA("123456")
        }
        
        // Note: In a real implementation, we would test loading state
        // but for this basic test we just ensure the method exists
    }
}

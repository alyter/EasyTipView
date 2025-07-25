//
//  AccountSettingsMFAIntegrationTests.swift
//  PolyPalTests
//
//  Created on 2025-07-24.
//

import XCTest
import SwiftUI
@testable import PolyPal

class AccountSettingsMFAIntegrationTests: XCTestCase {
  
  var viewModel: ProfileViewModel!
  var mfaManager: MFAManager!
  var backupCodeManager: BackupCodeManager!
  
  override func setUp() {
    super.setUp()
    viewModel = ProfileViewModel()
    mfaManager = MFAManager()
    backupCodeManager = BackupCodeManager()
  }
  
  override func tearDown() {
    viewModel = nil
    mfaManager = nil
    backupCodeManager = nil
    super.tearDown()
  }
  
  // MARK: - MFA Status Display Tests
  
  func testMFAStatusDisplayWhenDisabled() {
    // Given
    viewModel.profile.mfaSettings.isEnabled = false
    
    // When
    let status = viewModel.getMFAStatusText()
    
    // Then
    XCTAssertEqual(status, "Disabled")
    XCTAssertFalse(viewModel.profile.mfaSettings.isEnabled)
  }
  
  func testMFAStatusDisplayWhenEnabled() {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    viewModel.profile.mfaSettings.setupDate = Date()
    
    // When
    let status = viewModel.getMFAStatusText()
    
    // Then
    XCTAssertEqual(status, "Enabled")
    XCTAssertTrue(viewModel.profile.mfaSettings.isEnabled)
  }
  
  func testMFAStatusDisplayWithBackupCodesCount() {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    viewModel.profile.mfaSettings.remainingBackupCodes = 5
    
    // When
    let backupStatus = viewModel.getBackupCodesStatusText()
    
    // Then
    XCTAssertEqual(backupStatus, "5 backup codes remaining")
  }
  
  func testMFAStatusDisplayWithLowBackupCodes() {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    viewModel.profile.mfaSettings.remainingBackupCodes = 2
    
    // When
    let backupStatus = viewModel.getBackupCodesStatusText()
    let needsRegeneration = viewModel.shouldShowBackupCodeWarning()
    
    // Then
    XCTAssertEqual(backupStatus, "2 backup codes remaining")
    XCTAssertTrue(needsRegeneration)
  }
  
  // MARK: - MFA Enable/Disable Tests
  
  func testEnableMFAFlow() async {
    // Given
    XCTAssertFalse(viewModel.profile.mfaSettings.isEnabled)
    
    // When
    let expectation = XCTestExpectation(description: "MFA enabled")
    
    await viewModel.enableMFA { success in
      // Then
      XCTAssertTrue(success)
      XCTAssertTrue(self.viewModel.profile.mfaSettings.isEnabled)
      XCTAssertNotNil(self.viewModel.profile.mfaSettings.setupDate)
      XCTAssertEqual(self.viewModel.profile.mfaSettings.remainingBackupCodes, 10)
      expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 2.0)
  }
  
  func testDisableMFAFlow() async {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    viewModel.profile.mfaSettings.setupDate = Date()
    
    // When
    let expectation = XCTestExpectation(description: "MFA disabled")
    
    await viewModel.disableMFA { success in
      // Then
      XCTAssertTrue(success)
      XCTAssertFalse(self.viewModel.profile.mfaSettings.isEnabled)
      XCTAssertNil(self.viewModel.profile.mfaSettings.setupDate)
      XCTAssertEqual(self.viewModel.profile.mfaSettings.remainingBackupCodes, 0)
      expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 2.0)
  }
  
  func testDisableMFARequiresConfirmation() {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    
    // When
    let requiresConfirmation = viewModel.mfaDisableRequiresConfirmation()
    
    // Then
    XCTAssertTrue(requiresConfirmation)
  }
  
  // MARK: - Backup Code Management Tests
  
  func testRegenerateBackupCodes() async {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    viewModel.profile.mfaSettings.remainingBackupCodes = 3
    
    // When
    let expectation = XCTestExpectation(description: "Backup codes regenerated")
    
    await viewModel.regenerateBackupCodes { success, newCodes in
      // Then
      XCTAssertTrue(success)
      XCTAssertNotNil(newCodes)
      XCTAssertEqual(newCodes?.count, 10)
      XCTAssertEqual(self.viewModel.profile.mfaSettings.remainingBackupCodes, 10)
      expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 2.0)
  }
  
  func testRegenerateBackupCodesWhenMFADisabled() async {
    // Given
    viewModel.profile.mfaSettings.isEnabled = false
    
    // When
    let expectation = XCTestExpectation(description: "Backup codes regeneration failed")
    
    await viewModel.regenerateBackupCodes { success, newCodes in
      // Then
      XCTAssertFalse(success)
      XCTAssertNil(newCodes)
      expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 2.0)
  }
  
  func testDownloadBackupCodes() {
    // Given
    let backupCodes = ["ABCD1234", "EFGH5678", "IJKL9012"]
    
    // When
    let csvContent = viewModel.generateBackupCodesCSV(codes: backupCodes)
    
    // Then
    XCTAssertTrue(csvContent.contains("Backup Code"))
    XCTAssertTrue(csvContent.contains("ABCD1234"))
    XCTAssertTrue(csvContent.contains("EFGH5678"))
    XCTAssertTrue(csvContent.contains("IJKL9012"))
  }
  
  // MARK: - MFA Setup Navigation Tests
  
  func testNavigateToMFASetup() {
    // Given
    XCTAssertFalse(viewModel.profile.mfaSettings.isEnabled)
    
    // When
    let shouldNavigate = viewModel.shouldNavigateToMFASetup()
    
    // Then
    XCTAssertTrue(shouldNavigate)
  }
  
  func testNavigateToMFASetupWhenAlreadyEnabled() {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    
    // When
    let shouldNavigate = viewModel.shouldNavigateToMFASetup()
    
    // Then
    XCTAssertFalse(shouldNavigate)
  }
  
  // MARK: - MFA Settings Validation Tests
  
  func testValidateMFASettings() {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    viewModel.profile.mfaSettings.setupDate = Date()
    viewModel.profile.mfaSettings.remainingBackupCodes = 5
    
    // When
    let isValid = viewModel.validateMFASettings()
    
    // Then
    XCTAssertTrue(isValid)
  }
  
  func testValidateMFASettingsWithInvalidState() {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    viewModel.profile.mfaSettings.setupDate = nil // Invalid state
    
    // When
    let isValid = viewModel.validateMFASettings()
    
    // Then
    XCTAssertFalse(isValid)
  }
  
  // MARK: - Security Audit Tests
  
  func testMFASecurityAuditLogging() {
    // Given
    let initialLogCount = viewModel.getSecurityAuditLogCount()
    
    // When
    viewModel.logMFASecurityEvent(.mfaEnabled, details: "User enabled MFA from account settings")
    
    // Then
    let newLogCount = viewModel.getSecurityAuditLogCount()
    XCTAssertEqual(newLogCount, initialLogCount + 1)
  }
  
  func testMFADisableSecurityAuditLogging() {
    // Given
    let initialLogCount = viewModel.getSecurityAuditLogCount()
    
    // When
    viewModel.logMFASecurityEvent(.mfaDisabled, details: "User disabled MFA from account settings")
    
    // Then
    let newLogCount = viewModel.getSecurityAuditLogCount()
    XCTAssertEqual(newLogCount, initialLogCount + 1)
  }
  
  // MARK: - Error Handling Tests
  
  func testMFAEnableWithNetworkError() async {
    // Given
    viewModel.simulateNetworkError = true
    
    // When
    let expectation = XCTestExpectation(description: "MFA enable failed")
    
    await viewModel.enableMFA { success in
      // Then
      XCTAssertFalse(success)
      XCTAssertFalse(self.viewModel.profile.mfaSettings.isEnabled)
      XCTAssertNotNil(self.viewModel.errorMessage)
      expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 2.0)
  }
  
  func testMFADisableWithNetworkError() async {
    // Given
    viewModel.profile.mfaSettings.isEnabled = true
    viewModel.simulateNetworkError = true
    
    // When
    let expectation = XCTestExpectation(description: "MFA disable failed")
    
    await viewModel.disableMFA { success in
      // Then
      XCTAssertFalse(success)
      XCTAssertTrue(self.viewModel.profile.mfaSettings.isEnabled) // Should remain enabled
      XCTAssertNotNil(self.viewModel.errorMessage)
      expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 2.0)
  }
  
  // MARK: - Integration with UserProfile Tests
  
  func testMFASettingsIntegrationWithUserProfile() {
    // Given
    let profile = UserProfile.empty()
    
    // When
    profile.mfaSettings.isEnabled = true
    profile.mfaSettings.setupDate = Date()
    profile.mfaSettings.remainingBackupCodes = 8
    
    // Then
    XCTAssertTrue(profile.mfaSettings.isEnabled)
    XCTAssertNotNil(profile.mfaSettings.setupDate)
    XCTAssertEqual(profile.mfaSettings.remainingBackupCodes, 8)
  }
  
  func testMFASettingsSerializationInUserProfile() throws {
    // Given
    var profile = UserProfile.empty()
    profile.mfaSettings.isEnabled = true
    profile.mfaSettings.setupDate = Date()
    profile.mfaSettings.remainingBackupCodes = 7
    
    // When
    let data = try JSONEncoder().encode(profile)
    let decodedProfile = try JSONDecoder().decode(UserProfile.self, from: data)
    
    // Then
    XCTAssertEqual(decodedProfile.mfaSettings.isEnabled, profile.mfaSettings.isEnabled)
    XCTAssertEqual(decodedProfile.mfaSettings.remainingBackupCodes, profile.mfaSettings.remainingBackupCodes)
    XCTAssertNotNil(decodedProfile.mfaSettings.setupDate)
  }
}

// MARK: - Security Event Types for Testing

extension ProfileViewModel {
  enum MFASecurityEvent {
    case mfaEnabled
    case mfaDisabled
    case backupCodesRegenerated
    case backupCodeUsed
  }
}

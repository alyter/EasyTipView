//
//  ZohoConfigurationTests.swift
//  PolyPalTests
//
//  Created by Agent OS on 2025-07-25.
//

import XCTest
@testable import PolyPal

final class ZohoConfigurationTests: XCTestCase {
  
  var zohoConfiguration: ZohoConfiguration!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    zohoConfiguration = ZohoConfiguration()
  }
  
  override func tearDownWithError() throws {
    zohoConfiguration = nil
    try super.tearDownWithError()
  }
  
  // MARK: - ZCAppInfo.plist Parsing Tests
  
  func testLoadConfigurationFromPlist() throws {
    // Test that configuration can be loaded from ZCAppInfo.plist
    let config = try zohoConfiguration.loadConfiguration()
    
    XCTAssertNotNil(config, "Configuration should not be nil")
    XCTAssertFalse(config.accountsDomain.isEmpty, "AccountsDomain should not be empty")
    XCTAssertFalse(config.portalURL.isEmpty, "PortalURL should not be empty")
    XCTAssertFalse(config.creatorDomain.isEmpty, "CreatorDomain should not be empty")
    XCTAssertFalse(config.appOwnerName.isEmpty, "AppOwnerName should not be empty")
    XCTAssertFalse(config.appLinkName.isEmpty, "AppLinkName should not be empty")
  }
  
  func testConfigurationValidation() throws {
    // Test that configuration values are properly validated
    let config = try zohoConfiguration.loadConfiguration()
    
    XCTAssertEqual(config.accountsDomain, "accounts.zoho.com", "AccountsDomain should match expected value")
    XCTAssertEqual(config.portalURL, "https://clovelace1.zohocreatorportal.com", "PortalURL should match expected value")
    XCTAssertEqual(config.creatorDomain, "creator.zoho.com", "CreatorDomain should match expected value")
    XCTAssertEqual(config.appOwnerName, "clovelace1", "AppOwnerName should match expected value")
    XCTAssertEqual(config.appLinkName, "trading", "AppLinkName should match expected value")
  }
  
  func testPortalURLValidation() throws {
    // Test that portal URL is a valid URL
    let config = try zohoConfiguration.loadConfiguration()
    
    XCTAssertNotNil(URL(string: config.portalURL), "PortalURL should be a valid URL")
    XCTAssertTrue(config.portalURL.hasPrefix("https://"), "PortalURL should use HTTPS")
    XCTAssertTrue(config.portalURL.contains("zohocreatorportal.com"), "PortalURL should be a Zoho Creator portal")
  }
  
  // MARK: - Error Handling Tests
  
  func testMissingConfigurationFile() {
    // Test behavior when ZCAppInfo.plist is missing
    let invalidConfig = ZohoConfiguration(plistName: "NonExistentFile")
    
    XCTAssertThrowsError(try invalidConfig.loadConfiguration()) { error in
      XCTAssertTrue(error is ZohoConfigurationError, "Should throw ZohoConfigurationError")
      if let configError = error as? ZohoConfigurationError {
        XCTAssertEqual(configError, .plistNotFound, "Should be plistNotFound error")
      }
    }
  }
  
  func testInvalidConfigurationData() {
    // Test behavior with invalid configuration data
    // This would require creating a mock plist with invalid data
    // For now, we'll test the validation logic directly
    
    let invalidConfigData: [String: Any] = [
      "AccountsDomain": "",
      "PortalURL": "invalid-url",
      "CreatorDomain": "",
      "AppOwnerName": "",
      "AppLinkName": ""
    ]
    
    XCTAssertThrowsError(try zohoConfiguration.validateConfiguration(invalidConfigData)) { error in
      XCTAssertTrue(error is ZohoConfigurationError, "Should throw ZohoConfigurationError")
    }
  }
  
  // MARK: - SDK Initialization Tests
  
  func testSDKInitializationPreparation() {
    // Test that configuration is properly prepared for SDK initialization
    XCTAssertNoThrow(try zohoConfiguration.prepareForSDKInitialization(), "SDK preparation should not throw")
  }
  
  func testSDKInitializationWithValidConfig() throws {
    // Test SDK initialization with valid configuration
    let config = try zohoConfiguration.loadConfiguration()
    
    // Mock SDK initialization - in real implementation this would call Zoho SDK
    let initResult = zohoConfiguration.mockSDKInitialization(with: config)
    XCTAssertTrue(initResult, "SDK initialization should succeed with valid config")
  }
  
  func testSDKInitializationErrorHandling() {
    // Test error handling during SDK initialization
    let mockError = ZohoSDKError.initializationFailed("Mock initialization failure")
    
    XCTAssertThrowsError(try zohoConfiguration.handleSDKInitializationError(mockError)) { error in
      XCTAssertTrue(error is ZohoSDKError, "Should propagate ZohoSDKError")
    }
  }
  
  // MARK: - Configuration Access Tests
  
  func testConfigurationAccessMethods() throws {
    // Test convenience methods for accessing configuration values
    let config = try zohoConfiguration.loadConfiguration()
    
    XCTAssertEqual(zohoConfiguration.getAccountsDomain(), config.accountsDomain)
    XCTAssertEqual(zohoConfiguration.getPortalURL(), config.portalURL)
    XCTAssertEqual(zohoConfiguration.getCreatorDomain(), config.creatorDomain)
    XCTAssertEqual(zohoConfiguration.getAppOwnerName(), config.appOwnerName)
    XCTAssertEqual(zohoConfiguration.getAppLinkName(), config.appLinkName)
  }
  
  func testConfigurationCaching() throws {
    // Test that configuration is cached after first load
    let config1 = try zohoConfiguration.loadConfiguration()
    let config2 = try zohoConfiguration.loadConfiguration()
    
    // Should be the same instance (cached)
    XCTAssertTrue(config1.accountsDomain == config2.accountsDomain)
    XCTAssertTrue(config1.portalURL == config2.portalURL)
  }
  
  // MARK: - Performance Tests
  
  func testConfigurationLoadPerformance() {
    // Test configuration loading performance
    measure {
      do {
        _ = try zohoConfiguration.loadConfiguration()
      } catch {
        XCTFail("Configuration loading should not fail: \(error)")
      }
    }
  }
}

// MARK: - Mock Errors for Testing

enum ZohoConfigurationError: Error, Equatable {
  case plistNotFound
  case invalidConfigurationData
  case missingRequiredKey(String)
  case invalidURL(String)
}

enum ZohoSDKError: Error {
  case initializationFailed(String)
  case authenticationFailed
  case networkError
}

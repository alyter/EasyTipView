//
//  ZohoConfiguration.swift
//  PolyPal
//
//  Created by Agent OS on 2025-07-25.
//

import Foundation
import ZCUIFramework
import Combine
// MARK: - Configuration Data Structure

struct ZohoConfigurationData {
  let accountsDomain: String
  let portalURL: String
  let creatorDomain: String
  let appOwnerName: String
  let appLinkName: String
}

// MARK: - ZohoConfiguration Class

class ZohoConfiguration: @unchecked Sendable {
  
  // MARK: - Singleton
  
  static let shared = ZohoConfiguration()
  
  // MARK: - Properties
  
  private let plistName: String
  private var cachedConfiguration: ZohoConfigurationData?
  
  // MARK: - Initialization
  
  init(plistName: String = "ZCAppInfo") {
    self.plistName = plistName
  }
  
  // MARK: - Configuration Loading
  
  func loadConfiguration() throws -> ZohoConfigurationData {
    // Return cached configuration if available
    if let cached = cachedConfiguration {
      return cached
    }
    
    // Load configuration from plist
    guard let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
          let plistData = NSDictionary(contentsOfFile: path) as? [String: Any] else {
      throw ZohoConfigurationError.plistNotFound
    }
    
    // Validate and create configuration
    try validateConfiguration(plistData)
    
    let configuration = ZohoConfigurationData(
      accountsDomain: plistData["AccountsDomain"] as? String ?? "",
      portalURL: plistData["PortalURL"] as? String ?? "",
      creatorDomain: plistData["CreatorDomain"] as? String ?? "",
      appOwnerName: plistData["AppOwnerName"] as? String ?? "",
      appLinkName: plistData["AppLinkName"] as? String ?? ""
    )
    
    // Cache the configuration
    cachedConfiguration = configuration
    
    return configuration
  }
  
  // MARK: - Configuration Validation
  
  func validateConfiguration(_ configData: [String: Any]) throws {
    let requiredKeys = ["AccountsDomain", "PortalURL", "CreatorDomain", "AppOwnerName", "AppLinkName"]
    
    // Check for missing keys
    for key in requiredKeys {
      guard let value = configData[key] as? String, !value.isEmpty else {
        throw ZohoConfigurationError.missingRequiredKey(key)
      }
    }
    
    // Validate portal URL format
    if let portalURL = configData["PortalURL"] as? String {
      guard URL(string: portalURL) != nil else {
        throw ZohoConfigurationError.invalidURL(portalURL)
      }
      
      guard portalURL.hasPrefix("https://") else {
        throw ZohoConfigurationError.invalidURL("Portal URL must use HTTPS")
      }
      
      guard portalURL.contains("zohocreatorportal.com") else {
        throw ZohoConfigurationError.invalidURL("Invalid Zoho Creator portal URL")
      }
    }
  }
  
  // MARK: - SDK Initialization Support
  
  func prepareForSDKInitialization() throws {
    // Ensure configuration is loaded and valid
    _ = try loadConfiguration()
    
    // Additional preparation steps for SDK initialization
    // This would include setting up any required SDK parameters
  }
  
  func mockSDKInitialization(with config: ZohoConfigurationData) -> Bool {
    // Mock implementation for testing
    // In real implementation, this would call actual Zoho SDK initialization
    return !config.accountsDomain.isEmpty &&
           !config.portalURL.isEmpty &&
           !config.creatorDomain.isEmpty &&
           !config.appOwnerName.isEmpty &&
           !config.appLinkName.isEmpty
  }
  
  func handleSDKInitializationError(_ error: ZohoSDKError) throws {
    // Handle SDK initialization errors
    // Log the error and re-throw for proper error handling
    print("Zoho SDK initialization error: \(error)")
    throw error
  }
  
  // MARK: - Convenience Access Methods
  
  func getAccountsDomain() -> String {
    do {
      let config = try loadConfiguration()
      return config.accountsDomain
    } catch {
      print("Error loading configuration: \(error)")
      return ""
    }
  }
  
  func getPortalURL() -> String {
    do {
      let config = try loadConfiguration()
      return config.portalURL
    } catch {
      print("Error loading configuration: \(error)")
      return ""
    }
  }
  
  func getCreatorDomain() -> String {
    do {
      let config = try loadConfiguration()
      return config.creatorDomain
    } catch {
      print("Error loading configuration: \(error)")
      return ""
    }
  }
  
  func getAppOwnerName() -> String {
    do {
      let config = try loadConfiguration()
      return config.appOwnerName
    } catch {
      print("Error loading configuration: \(error)")
      return ""
    }
  }
  
  func getAppLinkName() -> String {
    do {
      let config = try loadConfiguration()
      return config.appLinkName
    } catch {
      print("Error loading configuration: \(error)")
      return ""
    }
  }
  
  // MARK: - Cache Management
  
  func clearCache() {
    cachedConfiguration = nil
  }
  
  func reloadConfiguration() throws -> ZohoConfigurationData {
    clearCache()
    return try loadConfiguration()
  }
}

// MARK: - Error Definitions

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

// MARK: - Error Descriptions

extension ZohoConfigurationError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .plistNotFound:
      return "ZCAppInfo.plist file not found in app bundle"
    case .invalidConfigurationData:
      return "Invalid configuration data in ZCAppInfo.plist"
    case .missingRequiredKey(let key):
      return "Missing required configuration key: \(key)"
    case .invalidURL(let url):
      return "Invalid URL in configuration: \(url)"
    }
  }
}

extension ZohoSDKError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .initializationFailed(let message):
      return "Zoho SDK initialization failed: \(message)"
    case .authenticationFailed:
      return "Zoho SDK authentication failed"
    case .networkError:
      return "Network error during Zoho SDK operation"
    }
  }
}

//
//  UserProfile.swift
//  PolyPal
//
//  Created on 2025-07-24.
//

import Foundation

// MARK: - Contact Method Enum

enum ContactMethod: String, CaseIterable, Codable {
  case email = "email"
  case phone = "phone"
  case both = "both"
}

// MARK: - UserProfile

struct UserProfile: Codable, Identifiable {
  let id: String
  var firstName: String
  var lastName: String
  var email: String
  var phoneNumber: String
  var companyName: String
  var jobTitle: String
  var address: String
  var city: String
  var state: String
  var zipCode: String
  var country: String
  var bio: String?
  var website: String?
  var linkedIn: String?
  var linkedInProfile: String? // Alias for linkedIn for compatibility
  var dateOfBirth: Date?
  var preferredContactMethod: ContactMethod
  var isPublicProfile: Bool
  var allowDirectMessages: Bool
  var showContactInfo: Bool
  var profileImageURL: String?
  let createdAt: Date
  var updatedAt: Date
  
  // Settings
  var privacySettings: PrivacySettings = PrivacySettings()
  var notificationSettings: NotificationSettings = NotificationSettings()
  
  // MARK: - Initializers
  
  init(
    id: String = UUID().uuidString,
    firstName: String,
    lastName: String,
    email: String,
    phoneNumber: String,
    companyName: String = "",
    jobTitle: String = "",
    address: String,
    city: String,
    state: String,
    zipCode: String,
    country: String,
    bio: String? = nil,
    website: String? = nil,
    linkedIn: String? = nil,
    linkedInProfile: String? = nil,
    dateOfBirth: Date? = nil,
    preferredContactMethod: ContactMethod = .email,
    isPublicProfile: Bool = true,
    allowDirectMessages: Bool = true,
    showContactInfo: Bool = true,
    profileImageURL: String? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    privacySettings: PrivacySettings = PrivacySettings(),
    notificationSettings: NotificationSettings = NotificationSettings()
  ) {
    self.id = id
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
    self.phoneNumber = phoneNumber
    self.companyName = companyName
    self.jobTitle = jobTitle
    self.address = address
    self.city = city
    self.state = state
    self.zipCode = zipCode
    self.country = country
    self.bio = bio
    self.website = website
    self.linkedIn = linkedIn
    self.linkedInProfile = linkedInProfile
    self.dateOfBirth = dateOfBirth
    self.preferredContactMethod = preferredContactMethod
    self.isPublicProfile = isPublicProfile
    self.allowDirectMessages = allowDirectMessages
    self.showContactInfo = showContactInfo
    self.profileImageURL = profileImageURL
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.privacySettings = privacySettings
    self.notificationSettings = notificationSettings
  }
  
  // MARK: - Static Methods
  
  static func empty() -> UserProfile {
    return UserProfile(
      firstName: "",
      lastName: "",
      email: "",
      phoneNumber: "",
      address: "",
      city: "",
      state: "",
      zipCode: "",
      country: "United States"
    )
  }
  
  // MARK: - Computed Properties
  
  var fullName: String {
    "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
  }
  
  // MARK: - Validation Methods
  
  func isValidEmail(_ email: String) -> Bool {
    guard !email.isEmpty else { return false }
    
    let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return email.range(of: emailRegex, options: .regularExpression) != nil
  }
  
  func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
    guard !phoneNumber.isEmpty else { return false }
    
    // Remove all non-digit characters except + for international prefix
    let cleanedNumber = phoneNumber.replacingOccurrences(of: "[^+0-9]", with: "", options: .regularExpression)
    
    // Check if it's a reasonable length (7-15 digits, optionally starting with +)
    let phoneRegex = #"^\+?[0-9]{7,15}$"#
    return cleanedNumber.range(of: phoneRegex, options: .regularExpression) != nil
  }
  
  func isValidWebsite(_ url: String) -> Bool {
    guard !url.isEmpty else { return false }
    guard let urlObject = URL(string: url) else { return false }
    
    // Check if it's HTTP or HTTPS
    return urlObject.scheme == "http" || urlObject.scheme == "https"
  }
  
  func isValidLinkedInProfile(_ url: String) -> Bool {
    guard !url.isEmpty else { return false }
    guard let urlObject = URL(string: url) else { return false }
    
    // Check if it's a LinkedIn URL
    let host = urlObject.host?.lowercased()
    return host == "linkedin.com" || host == "www.linkedin.com"
  }
  
  func isValidBio(_ bio: String) -> Bool {
    return bio.count <= 500
  }
  
  // MARK: - Profile Completion
  
  var completionPercentage: Double {
    let totalFields = 12.0
    var completedFields = 0.0
    
    // Required fields
    if !firstName.isEmpty { completedFields += 1 }
    if !lastName.isEmpty { completedFields += 1 }
    if !email.isEmpty && isValidEmail(email) { completedFields += 1 }
    if !phoneNumber.isEmpty { completedFields += 1 }
    
    // Address fields
    if !address.isEmpty { completedFields += 1 }
    if !city.isEmpty { completedFields += 1 }
    if !state.isEmpty { completedFields += 1 }
    if !zipCode.isEmpty { completedFields += 1 }
    
    // Company fields
    if !companyName.isEmpty { completedFields += 1 }
    if !jobTitle.isEmpty { completedFields += 1 }
    
    // Optional but valuable fields
    if profileImageURL != nil && !profileImageURL!.isEmpty { completedFields += 1 }
    if bio != nil && !bio!.isEmpty { completedFields += 1 }
    
    return (completedFields / totalFields) * 100.0
  }
  
  var isComplete: Bool {
    return completionPercentage >= 80.0
  }
  
  var hasRequiredFields: Bool {
    return !firstName.isEmpty &&
           !lastName.isEmpty &&
           !email.isEmpty &&
           !phoneNumber.isEmpty
  }
}

// MARK: - Equatable Implementation

extension UserProfile: Equatable {
  static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
    return lhs.id == rhs.id
  }
}

// MARK: - Privacy Settings

struct PrivacySettings: Codable, Equatable {
  var showEmail: Bool
  var showPhoneNumber: Bool
  var showAddress: Bool
  var showLinkedInProfile: Bool
  var showWebsite: Bool
  var allowDirectMessages: Bool
  var showOnlineStatus: Bool
  
  init(
    showEmail: Bool = true,
    showPhoneNumber: Bool = true,
    showAddress: Bool = false,
    showLinkedInProfile: Bool = true,
    showWebsite: Bool = true,
    allowDirectMessages: Bool = true,
    showOnlineStatus: Bool = false
  ) {
    self.showEmail = showEmail
    self.showPhoneNumber = showPhoneNumber
    self.showAddress = showAddress
    self.showLinkedInProfile = showLinkedInProfile
    self.showWebsite = showWebsite
    self.allowDirectMessages = allowDirectMessages
    self.showOnlineStatus = showOnlineStatus
  }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable, Equatable {
  var emailNotifications: Bool
  var pushNotifications: Bool
  var smsNotifications: Bool
  var marketingEmails: Bool
  var newMessageNotifications: Bool
  var connectionRequestNotifications: Bool
  var systemUpdateNotifications: Bool
  
  init(
    emailNotifications: Bool = true,
    pushNotifications: Bool = true,
    smsNotifications: Bool = false,
    marketingEmails: Bool = true,
    newMessageNotifications: Bool = true,
    connectionRequestNotifications: Bool = true,
    systemUpdateNotifications: Bool = true
  ) {
    self.emailNotifications = emailNotifications
    self.pushNotifications = pushNotifications
    self.smsNotifications = smsNotifications
    self.marketingEmails = marketingEmails
    self.newMessageNotifications = newMessageNotifications
    self.connectionRequestNotifications = connectionRequestNotifications
    self.systemUpdateNotifications = systemUpdateNotifications
  }
}

//
//  ProfileViewModel.swift
//  PolyPal
//
//  Created on 2025-07-24.
//

import Foundation
import Combine
import UIKit

class ProfileViewModel: ObservableObject {
  
  // MARK: - Published Properties
  
  @Published var profile = UserProfile.empty()
  @Published var loadingState: LoadingState = .idle
  @Published var hasUnsavedChanges: Bool = false
  
  // Error handling
  @Published var errorMessage: String?
  @Published var validationErrors: [String] = []
  
  // Image upload state
  @Published var selectedImage: UIImage?
  @Published var isImagePickerPresented = false
  @Published var isImageCropperPresented = false
  @Published var imageUploadProgress: Double = 0.0
  @Published var isUploadingImage = false
  @Published var imageUploadState: ImageUploadState = .idle
  
  // Profile Creation Wizard State
  @Published var currentStep = 0
  let totalSteps = 5 // Basic Info, Contact Info, Location, Preferences, Review
  
  // MARK: - Loading States
  
  enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error
  }
  
  enum ImageUploadState: Equatable {
    case idle
    case uploading
    case uploaded
    case error
  }
  
  // MARK: - Private Properties
  
  private var cancellables = Set<AnyCancellable>()
  private var originalProfile: UserProfile?
  
  // MARK: - Initialization
  
  init() {
    setupValidationObservers()
  }
  
  // MARK: - Wizard Navigation
  
  var isFirstStep: Bool {
    currentStep == 0
  }
  
  var isLastStep: Bool {
    currentStep == totalSteps - 1
  }
  
  var canProceedToNextStep: Bool {
    switch currentStep {
    case 0: return isBasicInfoValid
    case 1: return isContactInfoValid
    case 2: return isLocationInfoValid
    case 3: return isPreferencesValid
    case 4: return true // Review step
    default: return false
    }
  }
  
  var creationProgress: Double {
    Double(currentStep) / Double(totalSteps - 1)
  }
  
  func nextStep() {
    guard currentStep < totalSteps - 1 else { return }
    currentStep += 1
  }
  
  func previousStep() {
    guard currentStep > 0 else { return }
    currentStep -= 1
  }
  
  func isStepCompleted(_ step: Int) -> Bool {
    switch step {
    case 0: return isBasicInfoValid
    case 1: return isContactInfoValid
    case 2: return isLocationInfoValid
    case 3: return isPreferencesValid
    case 4: return true
    default: return false
    }
  }
  
  // MARK: - Step Validation
  
  var isBasicInfoValid: Bool {
    !profile.firstName.isEmpty &&
    !profile.lastName.isEmpty &&
    profile.dateOfBirth != nil
  }
  
  var isContactInfoValid: Bool {
    profile.isValidEmail(profile.email) &&
    !profile.phoneNumber.isEmpty
  }
  
  var isLocationInfoValid: Bool {
    !profile.address.isEmpty &&
    !profile.city.isEmpty &&
    !profile.state.isEmpty &&
    !profile.zipCode.isEmpty
  }
  
  var isPreferencesValid: Bool {
    true // Preferences are optional
  }
  
  // MARK: - Profile Loading
  
  func loadProfile() {
    loadingState = .loading
    clearErrors()
    
    // Simulate API call to load profile
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self = self else { return }
      
      self.originalProfile = self.profile
      self.loadingState = .loaded
      self.hasUnsavedChanges = false
    }
  }
  
  // MARK: - Profile Saving
  
  func saveProfile() {
    guard isFormValid else {
      loadingState = .error
      errorMessage = "Please fix validation errors before saving"
      return
    }
    
    loadingState = .loading
    clearErrors()
    
    // Simulate API call to save profile
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self = self else { return }
      
      self.originalProfile = self.profile
      self.loadingState = .loaded
      self.hasUnsavedChanges = false
    }
  }
  
  // MARK: - Form Validation
  
  var isFormValid: Bool {
    validationErrors.isEmpty
  }
  
  private func setupValidationObservers() {
    // Observe profile changes and update validation
    $profile
      .sink { [weak self] (profile: UserProfile) in
        self?.updateValidationErrors()
        self?.hasUnsavedChanges = true
      }
      .store(in: &cancellables)
  }
  
  // Public method to trigger validation manually for testing
  func triggerValidation() {
    updateValidationErrors()
  }
  
  private func updateValidationErrors() {
    var errors: [String] = []
    
    // Email validation
    if !profile.email.isEmpty && !profile.isValidEmail(profile.email) {
      errors.append("Invalid email format")
    }
    
    // Phone number validation
    if !profile.phoneNumber.isEmpty && !profile.isValidPhoneNumber(profile.phoneNumber) {
      errors.append("Invalid phone number format")
    }
    
    // Website validation
    if let website = profile.website, !website.isEmpty && !profile.isValidWebsite(website) {
      errors.append("Invalid website URL")
    }
    
    // LinkedIn validation
    if let linkedIn = profile.linkedInProfile, !linkedIn.isEmpty && !profile.isValidLinkedInProfile(linkedIn) {
      errors.append("Invalid LinkedIn profile URL")
    }
    
    // Bio validation
    if let bio = profile.bio, !bio.isEmpty && !profile.isValidBio(bio) {
      errors.append("Bio must be 500 characters or less")
    }
    
    validationErrors = errors
  }
  
  // MARK: - Phone Number Formatting
  
  func formatPhoneNumber() {
    let cleaned = profile.phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    
    if cleaned.count == 10 {
      let areaCode = String(cleaned.prefix(3))
      let firstThree = String(cleaned.dropFirst(3).prefix(3))
      let lastFour = String(cleaned.suffix(4))
      profile.phoneNumber = "(\(areaCode)) \(firstThree)-\(lastFour)"
    }
  }
  
  // MARK: - Image Management
  
  func presentImagePicker() {
    isImagePickerPresented = true
  }
  
  func presentImageCropper() {
    isImageCropperPresented = true
  }
  
  func uploadImage() {
    guard let image = selectedImage else { return }
    
    isUploadingImage = true
    imageUploadState = .uploading
    imageUploadProgress = 0.0
    
    // Simulate image upload with progress
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      
      self.imageUploadProgress += 0.1
      
      if self.imageUploadProgress >= 1.0 {
        timer.invalidate()
        self.completeImageUpload()
      }
    }
  }
  
  private func completeImageUpload() {
    // Simulate successful upload
    let uploadedURL = "https://example.com/uploaded-image-\(UUID().uuidString).jpg"
    profile.profileImageURL = uploadedURL
    
    isUploadingImage = false
    imageUploadState = .uploaded
    imageUploadProgress = 1.0
    hasUnsavedChanges = true
  }
  
  // MARK: - Reset and Clear
  
  func resetChanges() {
    if let original = originalProfile {
      profile = original
    }
    hasUnsavedChanges = false
    clearErrors()
  }
  
  func clearErrors() {
    errorMessage = nil
    validationErrors = []
  }
  
  // MARK: - Profile Completion
  
  var profileCompletionPercentage: Double {
    profile.completionPercentage
  }
  
  var isProfileComplete: Bool {
    profile.isComplete
  }
  
  // MARK: - Account Settings
  
  @Published var isTwoFactorEnabled: Bool = false
  @Published var simulateNetworkError: Bool = false
  
  // MFA-specific properties
  @Published var mfaManager: MFAManager = MFAManager()
  @Published var backupCodeManager: BackupCodeManager = BackupCodeManager()
  @Published var isShowingMFASetup: Bool = false
  @Published var isShowingBackupCodeRegeneration: Bool = false
  @Published var securityAuditLog: [SecurityAuditEntry] = []
  
  var isLoading: Bool {
    get { loadingState == .loading }
    set { loadingState = newValue ? .loading : .idle }
  }
  
  func saveProfile(completion: @escaping (Bool) -> Void) {
    if simulateNetworkError {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.errorMessage = "Network error occurred"
        completion(false)
      }
      return
    }
    
    loadingState = .loading
    clearErrors()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self = self else { return }
      
      self.originalProfile = self.profile
      self.loadingState = .loaded
      self.hasUnsavedChanges = false
      completion(true)
    }
  }
  
  func toggleTwoFactorAuthentication() {
    isTwoFactorEnabled.toggle()
  }
  
  func requestPasswordChange(completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion(true)
    }
  }
  
  func requestAccountDeletion(completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion(true)
    }
  }
  
  func validateSettings() -> Bool {
    return true // Basic validation - can be expanded
  }
  
  func requestDataExport(completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion(true)
    }
  }
  
  func resetSettingsToDefaults() {
    profile.privacySettings = PrivacySettings()
    profile.notificationSettings = NotificationSettings()
  }
  
  // MARK: - Notification Preferences Management
  
  func updateNotificationPreference(keyPath: WritableKeyPath<NotificationSettings, Bool>, value: Bool) {
    profile.notificationSettings[keyPath: keyPath] = value
    hasUnsavedChanges = true
  }
  
  func validateNotificationSettings() -> Bool {
    // Ensure at least one notification method is enabled if notifications are on
    if profile.notificationSettings.newMessageNotifications || 
       profile.notificationSettings.connectionRequestNotifications {
      return profile.notificationSettings.emailNotifications || 
             profile.notificationSettings.pushNotifications || 
             profile.notificationSettings.smsNotifications
    }
    return true
  }
  
  func getNotificationSummary() -> String {
    var enabledMethods: [String] = []
    
    if profile.notificationSettings.emailNotifications {
      enabledMethods.append("Email")
    }
    if profile.notificationSettings.pushNotifications {
      enabledMethods.append("Push")
    }
    if profile.notificationSettings.smsNotifications {
      enabledMethods.append("SMS")
    }
    
    if enabledMethods.isEmpty {
      return "No notifications enabled"
    } else {
      return "Notifications via: \(enabledMethods.joined(separator: ", "))"
    }
  }
  
  // MARK: - User Preferences Integration
  
  func saveUserPreferences() {
    // Save preferences to UserDefaults or other persistence layer
    let preferences = [
      "publicProfile": profile.isPublicProfile,
      "allowDirectMessages": profile.allowDirectMessages,
      "showContactInfo": profile.showContactInfo,
      "twoFactorEnabled": isTwoFactorEnabled
    ]
    
    UserDefaults.standard.set(preferences, forKey: "userPreferences")
    
    // Save privacy settings
    let privacyPreferences = [
      "showEmail": profile.privacySettings.showEmail,
      "showPhoneNumber": profile.privacySettings.showPhoneNumber,
      "showAddress": profile.privacySettings.showAddress,
      "showLinkedInProfile": profile.privacySettings.showLinkedInProfile,
      "showWebsite": profile.privacySettings.showWebsite,
      "showOnlineStatus": profile.privacySettings.showOnlineStatus
    ]
    
    UserDefaults.standard.set(privacyPreferences, forKey: "privacyPreferences")
    
    // Save notification settings
    let notificationPreferences = [
      "emailNotifications": profile.notificationSettings.emailNotifications,
      "pushNotifications": profile.notificationSettings.pushNotifications,
      "smsNotifications": profile.notificationSettings.smsNotifications,
      "marketingEmails": profile.notificationSettings.marketingEmails,
      "newMessageNotifications": profile.notificationSettings.newMessageNotifications,
      "connectionRequestNotifications": profile.notificationSettings.connectionRequestNotifications,
      "systemUpdateNotifications": profile.notificationSettings.systemUpdateNotifications
    ]
    
    UserDefaults.standard.set(notificationPreferences, forKey: "notificationPreferences")
  }
  
  func loadUserPreferences() {
    // Load preferences from UserDefaults
    if let preferences = UserDefaults.standard.dictionary(forKey: "userPreferences") {
      profile.isPublicProfile = preferences["publicProfile"] as? Bool ?? true
      profile.allowDirectMessages = preferences["allowDirectMessages"] as? Bool ?? true
      profile.showContactInfo = preferences["showContactInfo"] as? Bool ?? false
      isTwoFactorEnabled = preferences["twoFactorEnabled"] as? Bool ?? false
    }
    
    // Load privacy settings
    if let privacyPreferences = UserDefaults.standard.dictionary(forKey: "privacyPreferences") {
      profile.privacySettings.showEmail = privacyPreferences["showEmail"] as? Bool ?? false
      profile.privacySettings.showPhoneNumber = privacyPreferences["showPhoneNumber"] as? Bool ?? false
      profile.privacySettings.showAddress = privacyPreferences["showAddress"] as? Bool ?? false
      profile.privacySettings.showLinkedInProfile = privacyPreferences["showLinkedInProfile"] as? Bool ?? true
      profile.privacySettings.showWebsite = privacyPreferences["showWebsite"] as? Bool ?? true
      profile.privacySettings.showOnlineStatus = privacyPreferences["showOnlineStatus"] as? Bool ?? true
    }
    
    // Load notification settings
    if let notificationPreferences = UserDefaults.standard.dictionary(forKey: "notificationPreferences") {
      profile.notificationSettings.emailNotifications = notificationPreferences["emailNotifications"] as? Bool ?? true
      profile.notificationSettings.pushNotifications = notificationPreferences["pushNotifications"] as? Bool ?? true
      profile.notificationSettings.smsNotifications = notificationPreferences["smsNotifications"] as? Bool ?? false
      profile.notificationSettings.marketingEmails = notificationPreferences["marketingEmails"] as? Bool ?? false
      profile.notificationSettings.newMessageNotifications = notificationPreferences["newMessageNotifications"] as? Bool ?? true
      profile.notificationSettings.connectionRequestNotifications = notificationPreferences["connectionRequestNotifications"] as? Bool ?? true
      profile.notificationSettings.systemUpdateNotifications = notificationPreferences["systemUpdateNotifications"] as? Bool ?? true
    }
  }
  
  func resetPreferencesToDefaults() {
    // Reset all preferences to default values
    profile.isPublicProfile = true
    profile.allowDirectMessages = true
    profile.showContactInfo = false
    isTwoFactorEnabled = false
    
    // Reset privacy settings
    profile.privacySettings = PrivacySettings()
    
    // Reset notification settings
    profile.notificationSettings = NotificationSettings()
    
    hasUnsavedChanges = true
  }
  
  func exportPreferences() -> [String: Any] {
    return [
      "userPreferences": [
        "publicProfile": profile.isPublicProfile,
        "allowDirectMessages": profile.allowDirectMessages,
        "showContactInfo": profile.showContactInfo,
        "twoFactorEnabled": isTwoFactorEnabled
      ],
      "privacySettings": [
        "showEmail": profile.privacySettings.showEmail,
        "showPhoneNumber": profile.privacySettings.showPhoneNumber,
        "showAddress": profile.privacySettings.showAddress,
        "showLinkedInProfile": profile.privacySettings.showLinkedInProfile,
        "showWebsite": profile.privacySettings.showWebsite,
        "showOnlineStatus": profile.privacySettings.showOnlineStatus
      ],
      "notificationSettings": [
        "emailNotifications": profile.notificationSettings.emailNotifications,
        "pushNotifications": profile.notificationSettings.pushNotifications,
        "smsNotifications": profile.notificationSettings.smsNotifications,
        "marketingEmails": profile.notificationSettings.marketingEmails,
        "newMessageNotifications": profile.notificationSettings.newMessageNotifications,
        "connectionRequestNotifications": profile.notificationSettings.connectionRequestNotifications,
        "systemUpdateNotifications": profile.notificationSettings.systemUpdateNotifications
      ]
    ]
  }
  
  // MARK: - MFA Management
  
  func getMFAStatusText() -> String {
    return profile.mfaSettings.isEnabled ? "Enabled" : "Disabled"
  }
  
  func getBackupCodesStatusText() -> String {
    let count = profile.mfaSettings.remainingBackupCodes
    return "\(count) backup codes remaining"
  }
  
  func shouldShowBackupCodeWarning() -> Bool {
    return profile.mfaSettings.isEnabled && profile.mfaSettings.remainingBackupCodes <= 3
  }
  
  func enableMFA(completion: @escaping (Bool) -> Void) async {
    if simulateNetworkError {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.errorMessage = "Network error occurred while enabling MFA"
        completion(false)
      }
      return
    }
    
    loadingState = .loading
    clearErrors()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self = self else { return }
      
      // Generate secret key and backup codes
      let secretKey = self.mfaManager.generateSecretKey()
      let backupCodes = self.backupCodeManager.generateBackupCodes()
      
      // Update profile settings
      self.profile.mfaSettings.isEnabled = true
      self.profile.mfaSettings.setupDate = Date()
      self.profile.mfaSettings.remainingBackupCodes = backupCodes.count
      self.profile.mfaSettings.secretKey = String(data: secretKey, encoding: .utf8)
      
      // Store backup codes securely
      _ = self.backupCodeManager.storeBackupCodes(backupCodes, for: self.profile.id)
      
      // Log security event
      self.logMFASecurityEvent(.mfaEnabled, details: "User enabled MFA from account settings")
      
      self.loadingState = .loaded
      self.hasUnsavedChanges = true
      completion(true)
    }
  }
  
  func disableMFA(completion: @escaping (Bool) -> Void) async {
    if simulateNetworkError {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.errorMessage = "Network error occurred while disabling MFA"
        completion(false)
      }
      return
    }
    
    loadingState = .loading
    clearErrors()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self = self else { return }
      
      // Clear MFA settings
      self.profile.mfaSettings.isEnabled = false
      self.profile.mfaSettings.setupDate = nil
      self.profile.mfaSettings.remainingBackupCodes = 0
      self.profile.mfaSettings.secretKey = nil
      
      // Clear stored backup codes
      _ = self.backupCodeManager.deleteBackupCodes(for: self.profile.id)
      
      // Log security event
      self.logMFASecurityEvent(.mfaDisabled, details: "User disabled MFA from account settings")
      
      self.loadingState = .loaded
      self.hasUnsavedChanges = true
      completion(true)
    }
  }
  
  func mfaDisableRequiresConfirmation() -> Bool {
    return profile.mfaSettings.isEnabled
  }
  
  func regenerateBackupCodes(completion: @escaping (Bool, [String]?) -> Void) async {
    guard profile.mfaSettings.isEnabled else {
      completion(false, nil)
      return
    }
    
    if simulateNetworkError {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.errorMessage = "Network error occurred while regenerating backup codes"
        completion(false, nil)
      }
      return
    }
    
    loadingState = .loading
    clearErrors()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self = self else { return }
      
      // Generate new backup codes
      let newBackupCodes = self.backupCodeManager.generateBackupCodes()
      
      // Update profile settings
      self.profile.mfaSettings.remainingBackupCodes = newBackupCodes.count
      
      // Store new backup codes securely
      _ = self.backupCodeManager.storeBackupCodes(newBackupCodes, for: self.profile.id)
      
      // Log security event
      self.logMFASecurityEvent(.backupCodesRegenerated, details: "User regenerated backup codes from account settings")
      
      self.loadingState = .loaded
      self.hasUnsavedChanges = true
      completion(true, newBackupCodes)
    }
  }
  
  func generateBackupCodesCSV(codes: [String]) -> String {
    var csvContent = "Backup Code\n"
    for code in codes {
      csvContent += "\(code)\n"
    }
    return csvContent
  }
  
  func shouldNavigateToMFASetup() -> Bool {
    return !profile.mfaSettings.isEnabled
  }
  
  func validateMFASettings() -> Bool {
    if profile.mfaSettings.isEnabled {
      return profile.mfaSettings.setupDate != nil && profile.mfaSettings.remainingBackupCodes > 0
    }
    return true
  }
  
  // MARK: - Security Audit Logging
  
  func logMFASecurityEvent(_ event: MFASecurityEvent, details: String) {
    let entry = SecurityAuditEntry(
      id: UUID().uuidString,
      timestamp: Date(),
      event: event.rawValue,
      details: details,
      userAgent: "PolyPal iOS App",
      ipAddress: "127.0.0.1" // In real app, this would be actual IP
    )
    
    securityAuditLog.append(entry)
    
    // In a real app, this would also send to a secure logging service
    print("Security Event: \(event.rawValue) - \(details)")
  }
  
  func getSecurityAuditLogCount() -> Int {
    return securityAuditLog.count
  }
}

// MARK: - Security Audit Entry

struct SecurityAuditEntry: Codable, Identifiable {
  let id: String
  let timestamp: Date
  let event: String
  let details: String
  let userAgent: String
  let ipAddress: String
}

// MARK: - MFA Security Event Types

extension ProfileViewModel {
  enum MFASecurityEvent: String, CaseIterable {
    case mfaEnabled = "mfa_enabled"
    case mfaDisabled = "mfa_disabled"
    case backupCodesRegenerated = "backup_codes_regenerated"
    case backupCodeUsed = "backup_code_used"
  }
}

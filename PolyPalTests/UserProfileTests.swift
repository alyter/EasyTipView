import XCTest
@testable import PolyPal

final class UserProfileTests: XCTestCase {
  var sampleUserProfile: UserProfile!
  
  override func setUp() {
    super.setUp()
    sampleUserProfile = UserProfile(
      firstName: "John",
      lastName: "Doe",
      email: "john.doe@example.com",
      phoneNumber: "(555) 123-4567",
      address: "123 Main Street",
      city: "San Francisco",
      state: "CA",
      zipCode: "94102",
      country: "United States",
      bio: "Software engineer with 10 years of experience",
      website: "https://johndoe.dev",
      linkedIn: "https://linkedin.com/in/johndoe",
      dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
      profileImageURL: "https://example.com/profile.jpg"
    )
  }
  
  override func tearDown() {
    sampleUserProfile = nil
    super.tearDown()
  }
  
  // MARK: - Initialization Tests
  
  func testUserProfileInitialization() {
    XCTAssertEqual(sampleUserProfile.firstName, "John")
    XCTAssertEqual(sampleUserProfile.lastName, "Doe")
    XCTAssertEqual(sampleUserProfile.email, "john.doe@example.com")
    XCTAssertEqual(sampleUserProfile.phoneNumber, "(555) 123-4567")
    XCTAssertEqual(sampleUserProfile.address, "123 Main Street")
    XCTAssertEqual(sampleUserProfile.city, "San Francisco")
    XCTAssertEqual(sampleUserProfile.state, "CA")
    XCTAssertEqual(sampleUserProfile.zipCode, "94102")
    XCTAssertEqual(sampleUserProfile.country, "United States")
    XCTAssertEqual(sampleUserProfile.website, "https://johndoe.dev")
    XCTAssertEqual(sampleUserProfile.linkedIn, "https://linkedin.com/in/johndoe")
  }
  
  func testEmptyUserProfile() {
    let emptyProfile = UserProfile.empty()
    XCTAssertEqual(emptyProfile.firstName, "")
    XCTAssertEqual(emptyProfile.lastName, "")
    XCTAssertEqual(emptyProfile.email, "")
    XCTAssertEqual(emptyProfile.phoneNumber, "")
    XCTAssertEqual(emptyProfile.address, "")
    XCTAssertEqual(emptyProfile.city, "")
    XCTAssertEqual(emptyProfile.state, "")
    XCTAssertEqual(emptyProfile.zipCode, "")
    XCTAssertEqual(emptyProfile.country, "United States")
  }
  
  // MARK: - Computed Properties Tests
  
  func testFullName() {
    XCTAssertEqual(sampleUserProfile.fullName, "John Doe")
    
    let emptyProfile = UserProfile.empty()
    XCTAssertEqual(emptyProfile.fullName, "")
    
    var partialProfile = UserProfile.empty()
    partialProfile.firstName = "Jane"
    XCTAssertEqual(partialProfile.fullName, "Jane")
  }
  
  // MARK: - Validation Tests
  
  func testEmailValidation() {
    // Valid emails
    XCTAssertTrue(sampleUserProfile.isValidEmail("test@example.com"))
    XCTAssertTrue(sampleUserProfile.isValidEmail("user.name@domain.co.uk"))
    XCTAssertTrue(sampleUserProfile.isValidEmail("test+tag@example.org"))
    
    // Invalid emails
    XCTAssertFalse(sampleUserProfile.isValidEmail("invalid-email"))
    XCTAssertFalse(sampleUserProfile.isValidEmail("@example.com"))
    XCTAssertFalse(sampleUserProfile.isValidEmail("test@"))
    XCTAssertFalse(sampleUserProfile.isValidEmail(""))
  }
  
  func testPhoneNumberValidation() {
    // Valid phone numbers
    XCTAssertTrue(sampleUserProfile.isValidPhoneNumber("1234567890"))
    XCTAssertTrue(sampleUserProfile.isValidPhoneNumber("(555) 123-4567"))
    XCTAssertTrue(sampleUserProfile.isValidPhoneNumber("+1-555-123-4567"))
    XCTAssertTrue(sampleUserProfile.isValidPhoneNumber("+44 20 7946 0958"))
    
    // Invalid phone numbers
    XCTAssertFalse(sampleUserProfile.isValidPhoneNumber("123"))
    XCTAssertFalse(sampleUserProfile.isValidPhoneNumber("abc-def-ghij"))
    XCTAssertFalse(sampleUserProfile.isValidPhoneNumber(""))
  }
  
  func testWebsiteValidation() {
    // Valid websites
    XCTAssertTrue(sampleUserProfile.isValidWebsite("https://example.com"))
    XCTAssertTrue(sampleUserProfile.isValidWebsite("http://test.org"))
    XCTAssertTrue(sampleUserProfile.isValidWebsite("https://subdomain.example.co.uk"))
    
    // Invalid websites
    XCTAssertFalse(sampleUserProfile.isValidWebsite("not-a-url"))
    XCTAssertFalse(sampleUserProfile.isValidWebsite("ftp://example.com"))
    XCTAssertFalse(sampleUserProfile.isValidWebsite(""))
  }
  
  func testLinkedInProfileValidation() {
    // Valid LinkedIn URLs
    XCTAssertTrue(sampleUserProfile.isValidLinkedInProfile("https://linkedin.com/in/testuser"))
    XCTAssertTrue(sampleUserProfile.isValidLinkedInProfile("https://www.linkedin.com/in/test-user-123"))
    
    // Invalid LinkedIn URLs
    XCTAssertFalse(sampleUserProfile.isValidLinkedInProfile("https://facebook.com/testuser"))
    XCTAssertFalse(sampleUserProfile.isValidLinkedInProfile("not-a-url"))
    XCTAssertFalse(sampleUserProfile.isValidLinkedInProfile(""))
  }
  
  func testBioValidation() {
    // Valid bios
    let shortBio = "Short bio"
    let maxLengthBio = String(repeating: "a", count: 500)
    XCTAssertTrue(sampleUserProfile.isValidBio(shortBio))
    XCTAssertTrue(sampleUserProfile.isValidBio(maxLengthBio))
    
    // Invalid bio (too long)
    let tooLongBio = String(repeating: "a", count: 501)
    XCTAssertFalse(sampleUserProfile.isValidBio(tooLongBio))
  }
  
  // MARK: - Profile Completion Tests
  
  func testProfileCompletionMinimal() {
    let minimalProfile = UserProfile.empty()
    XCTAssertLessThan(minimalProfile.completionPercentage, 50.0)
    XCTAssertFalse(minimalProfile.isComplete)
    XCTAssertFalse(minimalProfile.hasRequiredFields)
  }
  
  func testProfileCompletionPartial() {
    var incompleteProfile = UserProfile.empty()
    incompleteProfile.firstName = "Jane"
    incompleteProfile.lastName = "Smith"
    incompleteProfile.email = "jane@example.com"
    
    XCTAssertGreaterThan(incompleteProfile.completionPercentage, 0.0)
    XCTAssertLessThan(incompleteProfile.completionPercentage, 80.0)
    XCTAssertFalse(incompleteProfile.isComplete)
  }
  
  func testProfileCompletionFull() {
    XCTAssertGreaterThanOrEqual(sampleUserProfile.completionPercentage, 80.0)
    XCTAssertTrue(sampleUserProfile.isComplete)
    XCTAssertTrue(sampleUserProfile.hasRequiredFields)
  }
  
  func testRequiredFieldsValidation() {
    var profile = UserProfile.empty()
    XCTAssertFalse(profile.hasRequiredFields)
    
    profile.firstName = "John"
    XCTAssertFalse(profile.hasRequiredFields)
    
    profile.lastName = "Doe"
    XCTAssertFalse(profile.hasRequiredFields)
    
    profile.email = "john@example.com"
    XCTAssertFalse(profile.hasRequiredFields)
    
    profile.phoneNumber = "555-1234"
    XCTAssertTrue(profile.hasRequiredFields)
  }
  
  // MARK: - Codable Tests
  
  func testUserProfileCodable() throws {
    // Test encoding
    let encoder = JSONEncoder()
    let data = try encoder.encode(sampleUserProfile)
    XCTAssertGreaterThan(data.count, 0)
    
    // Test decoding
    let decoder = JSONDecoder()
    let decodedProfile = try decoder.decode(UserProfile.self, from: data)
    
    XCTAssertEqual(decodedProfile.id, sampleUserProfile.id)
    XCTAssertEqual(decodedProfile.firstName, sampleUserProfile.firstName)
    XCTAssertEqual(decodedProfile.lastName, sampleUserProfile.lastName)
    XCTAssertEqual(decodedProfile.email, sampleUserProfile.email)
    XCTAssertEqual(decodedProfile.phoneNumber, sampleUserProfile.phoneNumber)
    XCTAssertEqual(decodedProfile.address, sampleUserProfile.address)
    XCTAssertEqual(decodedProfile.city, sampleUserProfile.city)
    XCTAssertEqual(decodedProfile.state, sampleUserProfile.state)
    XCTAssertEqual(decodedProfile.zipCode, sampleUserProfile.zipCode)
    XCTAssertEqual(decodedProfile.country, sampleUserProfile.country)
    XCTAssertEqual(decodedProfile.website, sampleUserProfile.website)
    XCTAssertEqual(decodedProfile.linkedIn, sampleUserProfile.linkedIn)
    XCTAssertEqual(decodedProfile.bio, sampleUserProfile.bio)
  }
  
  // MARK: - Equatable Tests
  
  func testUserProfileEquality() {
    let profile1 = sampleUserProfile!
    let profile2 = UserProfile(
      id: profile1.id, // Same ID
      firstName: "Different",
      lastName: "Name",
      email: "different@example.com",
      phoneNumber: "999-999-9999",
      address: "Different Address",
      city: "Different City",
      state: "NY",
      zipCode: "10001",
      country: "United States"
    )
    
    // Should be equal because they have the same ID
    XCTAssertEqual(profile1, profile2)
    
    let profile3 = UserProfile.empty() // Different ID
    XCTAssertNotEqual(profile1, profile3)
  }
  
  // MARK: - Privacy Settings Tests
  
  func testPrivacySettingsDefaults() {
    let privacySettings = PrivacySettings()
    XCTAssertTrue(privacySettings.showEmail)
    XCTAssertTrue(privacySettings.showPhoneNumber)
    XCTAssertFalse(privacySettings.showAddress)
    XCTAssertTrue(privacySettings.showLinkedInProfile)
    XCTAssertTrue(privacySettings.showWebsite)
    XCTAssertTrue(privacySettings.allowDirectMessages)
    XCTAssertFalse(privacySettings.showOnlineStatus)
  }
  
  func testPrivacySettingsCodable() throws {
    let privacySettings = PrivacySettings(
      showEmail: false,
      showPhoneNumber: false,
      showAddress: true,
      showLinkedInProfile: false,
      showWebsite: false,
      allowDirectMessages: false,
      showOnlineStatus: true
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(privacySettings)
    
    let decoder = JSONDecoder()
    let decodedSettings = try decoder.decode(PrivacySettings.self, from: data)
    
    XCTAssertEqual(decodedSettings, privacySettings)
  }
  
  // MARK: - Notification Settings Tests
  
  func testNotificationSettingsDefaults() {
    let notificationSettings = NotificationSettings()
    XCTAssertTrue(notificationSettings.emailNotifications)
    XCTAssertTrue(notificationSettings.pushNotifications)
    XCTAssertFalse(notificationSettings.smsNotifications)
    XCTAssertTrue(notificationSettings.marketingEmails)
    XCTAssertTrue(notificationSettings.newMessageNotifications)
    XCTAssertTrue(notificationSettings.connectionRequestNotifications)
    XCTAssertTrue(notificationSettings.systemUpdateNotifications)
  }
  
  func testNotificationSettingsCodable() throws {
    let notificationSettings = NotificationSettings(
      emailNotifications: false,
      pushNotifications: false,
      smsNotifications: true,
      marketingEmails: false,
      newMessageNotifications: false,
      connectionRequestNotifications: false,
      systemUpdateNotifications: false
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(notificationSettings)
    
    let decoder = JSONDecoder()
    let decodedSettings = try decoder.decode(NotificationSettings.self, from: data)
    
    XCTAssertEqual(decodedSettings, notificationSettings)
  }
}

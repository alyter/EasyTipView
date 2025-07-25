import XCTest
import SwiftUI
import Combine
@testable import PolyPal

final class ProfileViewModelTests: XCTestCase {
  var viewModel: ProfileViewModel!
  var cancellables: Set<AnyCancellable>!
  
  override func setUp() {
    super.setUp()
    viewModel = ProfileViewModel()
    cancellables = Set<AnyCancellable>()
  }
  
  override func tearDown() {
    viewModel = nil
    cancellables = nil
    super.tearDown()
  }
  
  // MARK: - Initialization Tests
  
  func testProfileViewModelInitialization() {
    XCTAssertEqual(viewModel.loadingState, .idle)
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertTrue(viewModel.validationErrors.isEmpty)
    XCTAssertEqual(viewModel.currentStep, 0)
    XCTAssertEqual(viewModel.totalSteps, 5)
    XCTAssertEqual(viewModel.imageUploadState, .idle)
    XCTAssertFalse(viewModel.isUploadingImage)
    XCTAssertEqual(viewModel.imageUploadProgress, 0.0)
  }
  
  // MARK: - Profile Loading Tests
  
  func testLoadProfile() {
    let expectation = XCTestExpectation(description: "Profile loaded")
    
    viewModel.$loadingState
      .sink { state in
        if state == .loaded {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.loadProfile()
    XCTAssertEqual(viewModel.loadingState, .loading)
    
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(viewModel.loadingState, .loaded)
    XCTAssertFalse(viewModel.hasUnsavedChanges)
  }
  
  // MARK: - Profile Saving Tests
  
  func testSaveProfileSuccess() {
    // Set up valid profile data
    viewModel.profile.firstName = "John"
    viewModel.profile.lastName = "Doe"
    viewModel.profile.email = "john@example.com"
    viewModel.profile.phoneNumber = "555-1234"
    
    let expectation = XCTestExpectation(description: "Profile saved")
    
    viewModel.$loadingState
      .sink { state in
        if state == .loaded {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.saveProfile()
    XCTAssertEqual(viewModel.loadingState, .loading)
    
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(viewModel.loadingState, .loaded)
    XCTAssertFalse(viewModel.hasUnsavedChanges)
  }
  
  func testSaveProfileWithValidationErrors() {
    // Set invalid email by replacing the entire profile to trigger validation
    var updatedProfile = viewModel.profile
    updatedProfile.email = "invalid-email"
    viewModel.profile = updatedProfile
    
    // Trigger validation manually to ensure it happens synchronously
    viewModel.triggerValidation()
    
    // Now try to save - should fail due to validation errors
    viewModel.saveProfile()
    
    XCTAssertEqual(viewModel.loadingState, .error)
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertEqual(viewModel.errorMessage, "Please fix validation errors before saving")
  }
  
  // MARK: - Validation Tests
  
  func testEmailValidation() {
    // Set invalid email by replacing the entire profile to trigger the publisher
    var updatedProfile = viewModel.profile
    updatedProfile.email = "invalid-email"
    viewModel.profile = updatedProfile
    
    // Trigger validation manually to ensure it happens synchronously
    viewModel.triggerValidation()
    
    XCTAssertTrue(viewModel.validationErrors.contains("Invalid email format"))
    XCTAssertFalse(viewModel.isFormValid)
  }
  
  func testPhoneNumberValidation() {
    // Set invalid phone number by replacing the entire profile to trigger the publisher
    var updatedProfile = viewModel.profile
    updatedProfile.phoneNumber = "invalid"
    viewModel.profile = updatedProfile
    
    // Trigger validation manually to ensure it happens synchronously
    viewModel.triggerValidation()
    
    XCTAssertTrue(viewModel.validationErrors.contains("Invalid phone number format"))
    XCTAssertFalse(viewModel.isFormValid)
  }
  
  func testWebsiteValidation() {
    // Set invalid website URL by replacing the entire profile to trigger the publisher
    var updatedProfile = viewModel.profile
    updatedProfile.website = "invalid-url"
    viewModel.profile = updatedProfile
    
    // Trigger validation manually to ensure it happens synchronously
    viewModel.triggerValidation()
    
    XCTAssertTrue(viewModel.validationErrors.contains("Invalid website URL"))
    XCTAssertFalse(viewModel.isFormValid)
  }
  
  func testLinkedInValidation() {
    // Set invalid LinkedIn URL by replacing the entire profile to trigger the publisher
    var updatedProfile = viewModel.profile
    updatedProfile.linkedInProfile = "invalid-linkedin"
    viewModel.profile = updatedProfile
    
    // Trigger validation manually to ensure it happens synchronously
    viewModel.triggerValidation()
    
    XCTAssertTrue(viewModel.validationErrors.contains("Invalid LinkedIn profile URL"))
    XCTAssertFalse(viewModel.isFormValid)
  }
  
  func testBioValidation() {
    // Set bio that's too long by replacing the entire profile to trigger the publisher
    var updatedProfile = viewModel.profile
    updatedProfile.bio = String(repeating: "a", count: 501)
    viewModel.profile = updatedProfile
    
    // Trigger validation manually to ensure it happens synchronously
    viewModel.triggerValidation()
    
    XCTAssertTrue(viewModel.validationErrors.contains("Bio must be 500 characters or less"))
    XCTAssertFalse(viewModel.isFormValid)
  }
  
  // MARK: - Phone Number Formatting Tests
  
  func testPhoneNumberFormatting() {
    viewModel.profile.phoneNumber = "1234567890"
    viewModel.formatPhoneNumber()
    XCTAssertEqual(viewModel.profile.phoneNumber, "(123) 456-7890")
  }
  
  func testPhoneNumberFormattingInvalidLength() {
    let originalNumber = "12345"
    viewModel.profile.phoneNumber = originalNumber
    viewModel.formatPhoneNumber()
    // Should not format if not 10 digits
    XCTAssertEqual(viewModel.profile.phoneNumber, originalNumber)
  }
  
  // MARK: - Wizard Navigation Tests
  
  func testWizardInitialState() {
    XCTAssertEqual(viewModel.currentStep, 0)
    XCTAssertTrue(viewModel.isFirstStep)
    XCTAssertFalse(viewModel.isLastStep)
    XCTAssertFalse(viewModel.canProceedToNextStep)
    XCTAssertEqual(viewModel.creationProgress, 0.0, accuracy: 0.01)
  }
  
  func testWizardNavigation() {
    // Fill basic info to allow progression
    viewModel.profile.firstName = "John"
    viewModel.profile.lastName = "Doe"
    viewModel.profile.dateOfBirth = Date()
    
    XCTAssertTrue(viewModel.canProceedToNextStep)
    
    viewModel.nextStep()
    XCTAssertEqual(viewModel.currentStep, 1)
    XCTAssertFalse(viewModel.isFirstStep)
    XCTAssertFalse(viewModel.isLastStep)
    
    viewModel.previousStep()
    XCTAssertEqual(viewModel.currentStep, 0)
    XCTAssertTrue(viewModel.isFirstStep)
  }
  
  func testWizardNavigationBoundaries() {
    // Test can't go below 0
    viewModel.previousStep()
    XCTAssertEqual(viewModel.currentStep, 0)
    
    // Test can't go above max
    viewModel.currentStep = viewModel.totalSteps - 1
    viewModel.nextStep()
    XCTAssertEqual(viewModel.currentStep, viewModel.totalSteps - 1)
    XCTAssertTrue(viewModel.isLastStep)
  }
  
  func testWizardProgressCalculation() {
    for step in 0..<viewModel.totalSteps {
      viewModel.currentStep = step
      let expectedProgress = Double(step) / Double(viewModel.totalSteps - 1)
      XCTAssertEqual(viewModel.creationProgress, expectedProgress, accuracy: 0.01)
    }
  }
  
  // MARK: - Step Validation Tests
  
  func testBasicInfoValidation() {
    XCTAssertFalse(viewModel.isBasicInfoValid)
    
    viewModel.profile.firstName = "John"
    XCTAssertFalse(viewModel.isBasicInfoValid)
    
    viewModel.profile.lastName = "Doe"
    XCTAssertFalse(viewModel.isBasicInfoValid)
    
    viewModel.profile.dateOfBirth = Date()
    XCTAssertTrue(viewModel.isBasicInfoValid)
  }
  
  func testContactInfoValidation() {
    XCTAssertFalse(viewModel.isContactInfoValid)
    
    viewModel.profile.email = "john@example.com"
    XCTAssertFalse(viewModel.isContactInfoValid)
    
    viewModel.profile.phoneNumber = "555-1234"
    XCTAssertTrue(viewModel.isContactInfoValid)
  }
  
  func testLocationInfoValidation() {
    XCTAssertFalse(viewModel.isLocationInfoValid)
    
    viewModel.profile.address = "123 Main St"
    XCTAssertFalse(viewModel.isLocationInfoValid)
    
    viewModel.profile.city = "Anytown"
    XCTAssertFalse(viewModel.isLocationInfoValid)
    
    viewModel.profile.state = "CA"
    XCTAssertFalse(viewModel.isLocationInfoValid)
    
    viewModel.profile.zipCode = "12345"
    XCTAssertTrue(viewModel.isLocationInfoValid)
  }
  
  func testPreferencesValidation() {
    // Preferences are always valid since they're optional
    XCTAssertTrue(viewModel.isPreferencesValid)
    
    viewModel.profile.bio = "Some bio"
    XCTAssertTrue(viewModel.isPreferencesValid)
  }
  
  func testStepCompletion() {
    // Initially no steps completed
    XCTAssertFalse(viewModel.isStepCompleted(0))
    XCTAssertFalse(viewModel.isStepCompleted(1))
    
    // Complete basic info
    viewModel.profile.firstName = "John"
    viewModel.profile.lastName = "Doe"
    viewModel.profile.dateOfBirth = Date()
    
    XCTAssertTrue(viewModel.isStepCompleted(0))
    XCTAssertFalse(viewModel.isStepCompleted(1))
  }
  
  // MARK: - Image Management Tests
  
  func testImagePickerPresentation() {
    XCTAssertFalse(viewModel.isImagePickerPresented)
    
    viewModel.presentImagePicker()
    XCTAssertTrue(viewModel.isImagePickerPresented)
  }
  
  func testImageCropperPresentation() {
    XCTAssertFalse(viewModel.isImageCropperPresented)
    
    viewModel.presentImageCropper()
    XCTAssertTrue(viewModel.isImageCropperPresented)
  }
  
  func testImageUpload() {
    let testImage = UIImage(systemName: "person.circle")!
    viewModel.selectedImage = testImage
    
    let expectation = XCTestExpectation(description: "Image uploaded")
    
    viewModel.$imageUploadState
      .sink { state in
        if state == .uploaded {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)
    
    viewModel.uploadImage()
    XCTAssertEqual(viewModel.imageUploadState, .uploading)
    XCTAssertTrue(viewModel.isUploadingImage)
    
    wait(for: [expectation], timeout: 3.0)
    
    XCTAssertEqual(viewModel.imageUploadState, .uploaded)
    XCTAssertFalse(viewModel.isUploadingImage)
    XCTAssertEqual(viewModel.imageUploadProgress, 1.0)
    XCTAssertNotNil(viewModel.profile.profileImageURL)
    XCTAssertTrue(viewModel.hasUnsavedChanges)
  }
  
  func testImageUploadWithoutSelectedImage() {
    viewModel.selectedImage = nil
    viewModel.uploadImage()
    
    // Should not start upload without selected image
    XCTAssertEqual(viewModel.imageUploadState, .idle)
    XCTAssertFalse(viewModel.isUploadingImage)
  }
  
  // MARK: - Profile Completion Tests
  
  func testProfileCompletionPercentage() {
    let emptyProfile = UserProfile.empty()
    viewModel.profile = emptyProfile
    
    let initialCompletion = viewModel.profileCompletionPercentage
    XCTAssertGreaterThanOrEqual(initialCompletion, 0.0)
    XCTAssertLessThanOrEqual(initialCompletion, 100.0)
    
    // Add some data and check completion increases
    viewModel.profile.firstName = "John"
    viewModel.profile.lastName = "Doe"
    viewModel.profile.email = "john@example.com"
    
    let improvedCompletion = viewModel.profileCompletionPercentage
    XCTAssertGreaterThan(improvedCompletion, initialCompletion)
  }
  
  func testProfileCompleteness() {
    let emptyProfile = UserProfile.empty()
    viewModel.profile = emptyProfile
    XCTAssertFalse(viewModel.isProfileComplete)
    
    // Create a complete profile
    let completeProfile = UserProfile(
      firstName: "John",
      lastName: "Doe",
      email: "john@example.com",
      phoneNumber: "555-1234",
      address: "123 Main St",
      city: "Anytown",
      state: "CA",
      zipCode: "12345",
      country: "United States",
      bio: "Software engineer",
      website: "https://johndoe.com",
      linkedIn: "https://linkedin.com/in/johndoe",
      dateOfBirth: Date(),
      profileImageURL: "https://example.com/image.jpg"
    )
    
    viewModel.profile = completeProfile
    XCTAssertTrue(viewModel.isProfileComplete)
  }
  
  // MARK: - Reset and Clear Tests
  
  func testResetChanges() {
    // Make some changes
    viewModel.profile.firstName = "Changed"
    viewModel.hasUnsavedChanges = true
    viewModel.errorMessage = "Some error"
    viewModel.validationErrors = ["Error 1", "Error 2"]
    
    viewModel.resetChanges()
    
    // Should clear errors
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertTrue(viewModel.validationErrors.isEmpty)
    XCTAssertFalse(viewModel.hasUnsavedChanges)
  }
  
  func testClearErrors() {
    viewModel.errorMessage = "Some error"
    viewModel.validationErrors = ["Error 1", "Error 2"]
    
    viewModel.clearErrors()
    
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertTrue(viewModel.validationErrors.isEmpty)
  }
  
  // MARK: - Form Validation Tests
  
  func testFormValidityWithNoErrors() {
    viewModel.validationErrors = []
    XCTAssertTrue(viewModel.isFormValid)
  }
  
  func testFormValidityWithErrors() {
    viewModel.validationErrors = ["Error 1"]
    XCTAssertFalse(viewModel.isFormValid)
  }
  
  // MARK: - Unsaved Changes Tests
  
  func testUnsavedChangesTracking() {
    let expectation = XCTestExpectation(description: "Unsaved changes tracked")
    
    viewModel.$hasUnsavedChanges
      .dropFirst() // Skip initial false state
      .sink { hasChanges in
        XCTAssertTrue(hasChanges)
        expectation.fulfill()
      }
      .store(in: &cancellables)
    
    // Make a change to trigger unsaved changes
    viewModel.profile.firstName = "Changed"
    
    wait(for: [expectation], timeout: 1.0)
  }
}

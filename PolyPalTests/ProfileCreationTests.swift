import XCTest
import SwiftUI
@testable import PolyPal

final class ProfileCreationTests: XCTestCase {
  var viewModel: ProfileViewModel!
  
  override func setUp() {
    super.setUp()
    viewModel = ProfileViewModel()
  }
  
  override func tearDown() {
    viewModel = nil
    super.tearDown()
  }
  
  // MARK: - Profile Creation Wizard Tests
  
  func testProfileCreationWizardInitialState() {
    // Test that wizard starts at first step
    XCTAssertEqual(viewModel.currentStep, 0)
    XCTAssertFalse(viewModel.canProceedToNextStep)
    XCTAssertFalse(viewModel.isLastStep)
    XCTAssertTrue(viewModel.isFirstStep)
  }
  
  func testProfileCreationStepNavigation() {
    // Test navigation between steps
    viewModel.nextStep()
    XCTAssertEqual(viewModel.currentStep, 1)
    XCTAssertFalse(viewModel.isFirstStep)
    
    viewModel.previousStep()
    XCTAssertEqual(viewModel.currentStep, 0)
    XCTAssertTrue(viewModel.isFirstStep)
  }
  
  func testProfileCreationStepValidation() {
    // Test step validation for basic info
    viewModel.profile.firstName = "John"
    viewModel.profile.lastName = "Doe"
    viewModel.profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
    
    XCTAssertTrue(viewModel.canProceedToNextStep)
  }
  
  func testProfileCreationProgressCalculation() {
    // Test progress calculation
    XCTAssertEqual(viewModel.creationProgress, 0.0, accuracy: 0.01)
    
    viewModel.currentStep = 2
    let expectedProgress = 2.0 / Double(viewModel.totalSteps - 1)
    XCTAssertEqual(viewModel.creationProgress, expectedProgress, accuracy: 0.01)
  }
  
  // MARK: - Form Validation Tests
  
  func testBasicInfoValidation() {
    // Test basic info step validation
    XCTAssertFalse(viewModel.isBasicInfoValid)
    
    viewModel.profile.firstName = "John"
    XCTAssertFalse(viewModel.isBasicInfoValid)
    
    viewModel.profile.lastName = "Doe"
    XCTAssertFalse(viewModel.isBasicInfoValid)
    
    viewModel.profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
    XCTAssertTrue(viewModel.isBasicInfoValid)
  }
  
  func testContactInfoValidation() {
    // Test contact info step validation
    XCTAssertFalse(viewModel.isContactInfoValid)
    
    viewModel.profile.email = "invalid-email"
    XCTAssertFalse(viewModel.isContactInfoValid)
    
    viewModel.profile.email = "john@example.com"
    XCTAssertFalse(viewModel.isContactInfoValid)
    
    viewModel.profile.phoneNumber = "123-456-7890"
    XCTAssertTrue(viewModel.isContactInfoValid)
  }
  
  func testLocationInfoValidation() {
    // Test location info step validation
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
    // Test preferences step validation (always valid since optional)
    XCTAssertTrue(viewModel.isPreferencesValid)
    
    viewModel.profile.bio = "Interested in Technology and Sports"
    XCTAssertTrue(viewModel.isPreferencesValid)
  }
  
  // MARK: - Real-time Validation Tests
  
  func testRealTimeValidationFeedback() {
    // Test that validation errors update in real-time
    viewModel.profile.email = "invalid"
    viewModel.triggerValidation()
    XCTAssertTrue(viewModel.validationErrors.contains("Invalid email format"))
    
    viewModel.profile.email = "valid@example.com"
    viewModel.triggerValidation()
    XCTAssertFalse(viewModel.validationErrors.contains("Invalid email format"))
  }
  
  func testPhoneNumberFormatting() {
    // Test phone number formatting
    viewModel.profile.phoneNumber = "1234567890"
    viewModel.formatPhoneNumber()
    XCTAssertEqual(viewModel.profile.phoneNumber, "(123) 456-7890")
  }
  
  // MARK: - Image Selection Tests
  
  func testImageSelectionState() {
    // Test image selection state management
    XCTAssertFalse(viewModel.isImagePickerPresented)
    XCTAssertNil(viewModel.selectedImage)
    
    viewModel.presentImagePicker()
    XCTAssertTrue(viewModel.isImagePickerPresented)
  }
  
  func testImageCroppingState() {
    // Test image cropping state
    XCTAssertFalse(viewModel.isImageCropperPresented)
    
    // Simulate image selection
    let testImage = UIImage(systemName: "person.circle")!
    viewModel.selectedImage = testImage
    viewModel.presentImageCropper()
    
    XCTAssertTrue(viewModel.isImageCropperPresented)
  }
  
  // MARK: - Form Navigation Tests
  
  func testFormNavigationWithValidation() {
    // Test that navigation respects validation
    XCTAssertFalse(viewModel.canProceedToNextStep)
    
    // Fill basic info
    viewModel.profile.firstName = "John"
    viewModel.profile.lastName = "Doe"
    viewModel.profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
    
    XCTAssertTrue(viewModel.canProceedToNextStep)
    
    viewModel.nextStep()
    XCTAssertEqual(viewModel.currentStep, 1)
  }
  
  func testFormNavigationBoundaries() {
    // Test navigation boundaries
    viewModel.previousStep() // Should not go below 0
    XCTAssertEqual(viewModel.currentStep, 0)
    
    // Navigate to last step
    viewModel.currentStep = viewModel.totalSteps - 1
    viewModel.nextStep() // Should not go beyond last step
    XCTAssertEqual(viewModel.currentStep, viewModel.totalSteps - 1)
    XCTAssertTrue(viewModel.isLastStep)
  }
  
  // MARK: - Progress Tracking Tests
  
  func testProgressTrackingAccuracy() {
    // Test progress tracking through all steps
    for step in 0..<viewModel.totalSteps {
      viewModel.currentStep = step
      let expectedProgress = Double(step) / Double(viewModel.totalSteps - 1)
      XCTAssertEqual(viewModel.creationProgress, expectedProgress, accuracy: 0.01)
    }
  }
  
  func testStepCompletionTracking() {
    // Test that completed steps are tracked
    viewModel.profile.firstName = "John"
    viewModel.profile.lastName = "Doe"
    viewModel.profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
    
    XCTAssertTrue(viewModel.isStepCompleted(0))
    XCTAssertFalse(viewModel.isStepCompleted(1))
  }
}

//
//  UserTests.swift
//  PolyPalTests
//
//  Created on 2025-07-22.
//

import XCTest
@testable import PolyPal

final class UserTests: XCTestCase {
  
  func testUserInitialization() {
    let user = User(
      email: "test@example.com",
      role: .buyer,
      firstName: "John",
      lastName: "Doe"
    )
    
    XCTAssertEqual(user.email, "test@example.com")
    XCTAssertEqual(user.role, .buyer)
    XCTAssertEqual(user.firstName, "John")
    XCTAssertEqual(user.lastName, "Doe")
    XCTAssertFalse(user.isEmailVerified)
    XCTAssertFalse(user.isMFAEnabled)
  }
  
  func testUserWithDefaultValues() {
    let user = User(email: "test@example.com", role: .vendor)
    
    XCTAssertEqual(user.email, "test@example.com")
    XCTAssertEqual(user.role, .vendor)
    XCTAssertNil(user.firstName)
    XCTAssertNil(user.lastName)
    XCTAssertFalse(user.isEmailVerified)
    XCTAssertFalse(user.isMFAEnabled)
  }
  
  func testDisplayName() {
    // Test with both first and last name
    let fullUser = User(
      email: "test@example.com",
      role: .buyer,
      firstName: "John",
      lastName: "Doe"
    )
    XCTAssertEqual(fullUser.displayName, "John Doe")
    
    // Test with only first name
    let firstNameUser = User(
      email: "test@example.com",
      role: .buyer,
      firstName: "John"
    )
    XCTAssertEqual(firstNameUser.displayName, "John")
    
    // Test with only last name
    let lastNameUser = User(
      email: "test@example.com",
      role: .buyer,
      lastName: "Doe"
    )
    XCTAssertEqual(lastNameUser.displayName, "Doe")
    
    // Test with no names (should return email)
    let emailOnlyUser = User(email: "test@example.com", role: .buyer)
    XCTAssertEqual(emailOnlyUser.displayName, "test@example.com")
  }
  
  func testIsProfileComplete() {
    // Complete profile
    let completeUser = User(
      email: "test@example.com",
      role: .buyer,
      firstName: "John",
      lastName: "Doe",
      isEmailVerified: true
    )
    XCTAssertTrue(completeUser.isProfileComplete)
    
    // Missing first name
    let missingFirstName = User(
      email: "test@example.com",
      role: .buyer,
      lastName: "Doe",
      isEmailVerified: true
    )
    XCTAssertFalse(missingFirstName.isProfileComplete)
    
    // Missing last name
    let missingLastName = User(
      email: "test@example.com",
      role: .buyer,
      firstName: "John",
      isEmailVerified: true
    )
    XCTAssertFalse(missingLastName.isProfileComplete)
    
    // Email not verified
    let unverifiedEmail = User(
      email: "test@example.com",
      role: .buyer,
      firstName: "John",
      lastName: "Doe",
      isEmailVerified: false
    )
    XCTAssertFalse(unverifiedEmail.isProfileComplete)
  }
  
  func testEmailValidation() {
    // Test valid emails
    let validUser1 = User(email: "valid@example.com", role: .buyer)
    XCTAssertTrue(validUser1.isValidEmail())
    
    let validUser2 = User(email: "user.name@domain.co.uk", role: .buyer)
    XCTAssertTrue(validUser2.isValidEmail())
    
    let validUser3 = User(email: "test+tag@example.org", role: .buyer)
    XCTAssertTrue(validUser3.isValidEmail())
    
    // Test invalid emails
    let invalidUser1 = User(email: "invalid.email", role: .buyer)
    XCTAssertFalse(invalidUser1.isValidEmail())
    
    let invalidUser2 = User(email: "@example.com", role: .buyer)
    XCTAssertFalse(invalidUser2.isValidEmail())
    
    let invalidUser3 = User(email: "test@", role: .buyer)
    XCTAssertFalse(invalidUser3.isValidEmail())
    
    let invalidUser4 = User(email: "", role: .buyer)
    XCTAssertFalse(invalidUser4.isValidEmail())
  }
  
  func testUserRoles() {
    let buyer = User(email: "buyer@example.com", role: .buyer)
    let vendor = User(email: "vendor@example.com", role: .vendor)
    let admin = User(email: "admin@example.com", role: .admin)
    
    XCTAssertEqual(buyer.role, .buyer)
    XCTAssertEqual(vendor.role, .vendor)
    XCTAssertEqual(admin.role, .admin)
    
    // Test role raw values
    XCTAssertEqual(User.UserRole.buyer.rawValue, "buyer")
    XCTAssertEqual(User.UserRole.vendor.rawValue, "vendor")
    XCTAssertEqual(User.UserRole.admin.rawValue, "admin")
  }
  
  func testUserCodable() throws {
    let originalUser = User(
      email: "test@example.com",
      role: .buyer,
      firstName: "John",
      lastName: "Doe",
      isEmailVerified: true,
      isMFAEnabled: true
    )
    
    let encoded = try JSONEncoder().encode(originalUser)
    let decodedUser = try JSONDecoder().decode(User.self, from: encoded)
    
    XCTAssertEqual(originalUser.id, decodedUser.id)
    XCTAssertEqual(originalUser.email, decodedUser.email)
    XCTAssertEqual(originalUser.role, decodedUser.role)
    XCTAssertEqual(originalUser.firstName, decodedUser.firstName)
    XCTAssertEqual(originalUser.lastName, decodedUser.lastName)
    XCTAssertEqual(originalUser.isEmailVerified, decodedUser.isEmailVerified)
    XCTAssertEqual(originalUser.isMFAEnabled, decodedUser.isMFAEnabled)
  }
  
  func testUserEquality() {
    let user1 = User(
      id: UUID(),
      email: "test@example.com",
      role: .buyer,
      firstName: "John"
    )
    
    let user2 = User(
      id: user1.id,
      email: "test@example.com",
      role: .buyer,
      firstName: "John"
    )
    
    let user3 = User(
      email: "different@example.com",
      role: .buyer,
      firstName: "John"
    )
    
    XCTAssertEqual(user1, user2)
    XCTAssertNotEqual(user1, user3)
  }
}

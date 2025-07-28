//
//  User.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import Foundation

struct User: Codable, Identifiable, Equatable {
  let id: UUID
  var email: String
  var role: UserRole
  var firstName: String?
  var lastName: String?
  var isEmailVerified: Bool
  var createdAt: Date
  var updatedAt: Date
  
  enum UserRole: String, Codable, CaseIterable {
    case buyer = "buyer"
    case vendor = "vendor"
    case admin = "admin"
  }
  
  static func == (lhs: User, rhs: User) -> Bool {
    return lhs.id == rhs.id
  }
  
  init(
    id: UUID = UUID(),
    email: String,
    role: UserRole,
    firstName: String? = nil,
    lastName: String? = nil,
    isEmailVerified: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.email = email
    self.role = role
    self.firstName = firstName
    self.lastName = lastName
    self.isEmailVerified = isEmailVerified
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  
  var displayName: String {
    if let firstName = firstName, let lastName = lastName {
      return "\(firstName) \(lastName)"
    } else if let firstName = firstName {
      return firstName
    } else if let lastName = lastName {
      return lastName
    } else {
      return email
    }
  }
  
  var isProfileComplete: Bool {
    return firstName != nil && lastName != nil && isEmailVerified
  }
  
  func isValidEmail() -> Bool {
    let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return email.range(of: emailRegex, options: .regularExpression) != nil
  }
}

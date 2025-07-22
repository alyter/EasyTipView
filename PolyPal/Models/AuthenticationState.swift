//
//  AuthenticationState.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import Foundation

enum AuthenticationState: CaseIterable {
  case unauthenticated
  case authenticating
  case authenticated
  case error(String)
  
  static var allCases: [AuthenticationState] {
    return [.unauthenticated, .authenticating, .authenticated, .error("Test error")]
  }
}

extension AuthenticationState: Equatable {
  static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
    switch (lhs, rhs) {
    case (.unauthenticated, .unauthenticated),
         (.authenticating, .authenticating),
         (.authenticated, .authenticated):
      return true
    case (.error(let lhsMessage), .error(let rhsMessage)):
      return lhsMessage == rhsMessage
    default:
      return false
    }
  }
}

extension AuthenticationState: Codable {
  enum CodingKeys: String, CodingKey {
    case type
    case errorMessage
  }
  
  private enum StateType: String, Codable {
    case unauthenticated
    case authenticating
    case authenticated
    case error
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(StateType.self, forKey: .type)
    
    switch type {
    case .unauthenticated:
      self = .unauthenticated
    case .authenticating:
      self = .authenticating
    case .authenticated:
      self = .authenticated
    case .error:
      let message = try container.decode(String.self, forKey: .errorMessage)
      self = .error(message)
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    switch self {
    case .unauthenticated:
      try container.encode(StateType.unauthenticated, forKey: .type)
    case .authenticating:
      try container.encode(StateType.authenticating, forKey: .type)
    case .authenticated:
      try container.encode(StateType.authenticated, forKey: .type)
    case .error(let message):
      try container.encode(StateType.error, forKey: .type)
      try container.encode(message, forKey: .errorMessage)
    }
  }
}

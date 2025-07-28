//
//  NetworkErrorHandler.swift
//  PolyPal
//
//  Created by Agent OS on 7/25/25.
//

import Foundation
import Network

/// Network-related errors
enum NetworkError: Error, LocalizedError, Equatable {
  case noConnection
  case timeout
  case serverError(Int)
  case invalidResponse
  case dataCorrupted
  case rateLimited(retryAfter: TimeInterval?)
  case authenticationFailed
  case forbidden
  case notFound
  case tooManyRequests
  case serverUnavailable
  case unknown(Error?)
  
  var errorDescription: String? {
    switch self {
    case .noConnection:
      return "No internet connection available"
    case .timeout:
      return "Request timed out"
    case .serverError(let code):
      return "Server error (Code: \(code))"
    case .invalidResponse:
      return "Invalid response from server"
    case .dataCorrupted:
      return "Data received is corrupted"
    case .rateLimited(let retryAfter):
      if let retryAfter = retryAfter {
        return "Rate limited. Try again in \(Int(retryAfter)) seconds"
      } else {
        return "Rate limited. Please try again later"
      }
    case .authenticationFailed:
      return "Authentication failed"
    case .forbidden:
      return "Access forbidden"
    case .notFound:
      return "Resource not found"
    case .tooManyRequests:
      return "Too many requests. Please try again later"
    case .serverUnavailable:
      return "Server is temporarily unavailable"
    case .unknown(let error):
      return error?.localizedDescription ?? "An unknown error occurred"
    }
  }
  
  var failureReason: String? {
    switch self {
    case .noConnection:
      return "The device is not connected to the internet"
    case .timeout:
      return "The request took too long to complete"
    case .serverError(let code):
      return "The server returned an error with status code \(code)"
    case .invalidResponse:
      return "The server response format is invalid"
    case .dataCorrupted:
      return "The data received from the server is corrupted"
    case .rateLimited:
      return "Too many requests have been made in a short period"
    case .authenticationFailed:
      return "The authentication credentials are invalid or expired"
    case .forbidden:
      return "You don't have permission to access this resource"
    case .notFound:
      return "The requested resource could not be found"
    case .tooManyRequests:
      return "The rate limit has been exceeded"
    case .serverUnavailable:
      return "The server is currently undergoing maintenance"
    case .unknown:
      return "An unexpected error occurred"
    }
  }
  
  var recoverySuggestion: String? {
    switch self {
    case .noConnection:
      return "Check your internet connection and try again"
    case .timeout:
      return "Check your connection and try again"
    case .serverError:
      return "Please try again later or contact support if the problem persists"
    case .invalidResponse, .dataCorrupted:
      return "Please try again or contact support if the problem persists"
    case .rateLimited(let retryAfter):
      if let retryAfter = retryAfter {
        return "Wait \(Int(retryAfter)) seconds before trying again"
      } else {
        return "Wait a moment before trying again"
      }
    case .authenticationFailed:
      return "Please log in again"
    case .forbidden:
      return "Contact support if you believe you should have access"
    case .notFound:
      return "The resource may have been moved or deleted"
    case .tooManyRequests:
      return "Wait a moment before making more requests"
    case .serverUnavailable:
      return "Please try again in a few minutes"
    case .unknown:
      return "Please try again or contact support if the problem persists"
    }
  }
  
  /// Indicates whether this error is recoverable through retry
  var isRetryable: Bool {
    switch self {
    case .noConnection, .timeout:
      return true
    case .serverError(let code):
      return code >= 500 || code == 408 || code == 429
    case .rateLimited, .tooManyRequests, .serverUnavailable:
      return true
    case .invalidResponse, .dataCorrupted:
      return false
    case .authenticationFailed, .forbidden, .notFound:
      return false
    case .unknown:
      return true
    }
  }
  
  /// Suggested delay before retry (in seconds)
  var retryDelay: TimeInterval {
    switch self {
    case .rateLimited(let retryAfter):
      return retryAfter ?? 60
    case .tooManyRequests:
      return 30
    case .serverUnavailable:
      return 120
    case .timeout:
      return 5
    case .noConnection:
      return 10
    default:
      return 1
    }
  }
}

/// Network error handler for managing error responses and recovery
class NetworkErrorHandler {
  
  /// Convert URLError to NetworkError
  static func networkError(from urlError: URLError) -> NetworkError {
    switch urlError.code {
    case .notConnectedToInternet, .networkConnectionLost:
      return .noConnection
    case .timedOut:
      return .timeout
    case .userAuthenticationRequired:
      return .authenticationFailed
    case .resourceUnavailable:
      return .serverUnavailable
    case .cannotFindHost, .cannotConnectToHost:
      return .serverUnavailable
    default:
      return .unknown(urlError)
    }
  }
  
  /// Convert HTTP response to NetworkError
  static func networkError(from httpResponse: HTTPURLResponse, data: Data?) -> NetworkError {
    switch httpResponse.statusCode {
    case 200...299:
      return .unknown(nil) // This shouldn't happen for error cases
    case 400:
      return .invalidResponse
    case 401:
      return .authenticationFailed
    case 403:
      return .forbidden
    case 404:
      return .notFound
    case 408:
      return .timeout
    case 429:
      let retryAfter = parseRetryAfter(from: httpResponse)
      return .rateLimited(retryAfter: retryAfter)
    case 500...599:
      return .serverError(httpResponse.statusCode)
    default:
      return .unknown(nil)
    }
  }
  
  /// Parse Retry-After header from HTTP response
  private static func parseRetryAfter(from response: HTTPURLResponse) -> TimeInterval? {
    guard let retryAfterString = response.value(forHTTPHeaderField: "Retry-After") else {
      return nil
    }
    
    // Try parsing as seconds
    if let seconds = TimeInterval(retryAfterString) {
      return seconds
    }
    
    // Try parsing as HTTP date
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    if let date = formatter.date(from: retryAfterString) {
      return date.timeIntervalSinceNow
    }
    
    return nil
  }
  
  /// Handle network error with appropriate logging and user notification
  static func handleError(_ error: NetworkError, context: String = "") {
    let contextPrefix = context.isEmpty ? "" : "[\(context)] "
    print("NetworkError: \(contextPrefix)\(error.localizedDescription)")
    
    // Log additional details for debugging
    if let failureReason = error.failureReason {
      print("NetworkError: Reason - \(failureReason)")
    }
    
    if let recoverySuggestion = error.recoverySuggestion {
      print("NetworkError: Suggestion - \(recoverySuggestion)")
    }
    
    // Post notification for UI to handle
    NotificationCenter.default.post(
      name: .networkErrorOccurred,
      object: nil,
      userInfo: [
        "error": error,
        "context": context,
        "isRetryable": error.isRetryable,
        "retryDelay": error.retryDelay
      ]
    )
  }
  
  /// Create user-friendly error message for display
  static func userFriendlyMessage(for error: NetworkError) -> String {
    switch error {
    case .noConnection:
      return "Please check your internet connection and try again."
    case .timeout:
      return "The request is taking longer than expected. Please try again."
    case .serverError:
      return "We're experiencing technical difficulties. Please try again later."
    case .invalidResponse, .dataCorrupted:
      return "Something went wrong. Please try again."
    case .rateLimited:
      return "You're making requests too quickly. Please wait a moment and try again."
    case .authenticationFailed:
      return "Please sign in again to continue."
    case .forbidden:
      return "You don't have permission to access this content."
    case .notFound:
      return "The content you're looking for isn't available."
    case .tooManyRequests:
      return "Too many requests. Please wait a moment before trying again."
    case .serverUnavailable:
      return "Our servers are temporarily unavailable. Please try again in a few minutes."
    case .unknown:
      return "Something unexpected happened. Please try again."
    }
  }
  
  /// Determine if error should trigger offline mode
  static func shouldTriggerOfflineMode(for error: NetworkError) -> Bool {
    switch error {
    case .noConnection, .timeout, .serverUnavailable:
      return true
    default:
      return false
    }
  }
  
  /// Get appropriate retry strategy for error
  static func retryStrategy(for error: NetworkError) -> RetryStrategy {
    if !error.isRetryable {
      return .noRetry
    }
    
    switch error {
    case .rateLimited(let retryAfter):
      return .fixedDelay(retryAfter ?? 60)
    case .tooManyRequests:
      return .fixedDelay(30)
    case .serverUnavailable:
      return .exponentialBackoff(initialDelay: 5, maxDelay: 120, maxAttempts: 3)
    case .timeout, .noConnection:
      return .exponentialBackoff(initialDelay: 1, maxDelay: 30, maxAttempts: 3)
    case .serverError:
      return .exponentialBackoff(initialDelay: 2, maxDelay: 60, maxAttempts: 3)
    default:
      return .exponentialBackoff(initialDelay: 1, maxDelay: 10, maxAttempts: 2)
    }
  }
}

/// Retry strategy for network requests
enum RetryStrategy {
  case noRetry
  case fixedDelay(TimeInterval)
  case exponentialBackoff(initialDelay: TimeInterval, maxDelay: TimeInterval, maxAttempts: Int)
  
  /// Calculate delay for given attempt number (0-based)
  func delay(for attempt: Int) -> TimeInterval? {
    switch self {
    case .noRetry:
      return nil
    case .fixedDelay(let delay):
      return delay
    case .exponentialBackoff(let initialDelay, let maxDelay, let maxAttempts):
      guard attempt < maxAttempts else { return nil }
      let delay = initialDelay * pow(2.0, Double(attempt))
      return min(delay, maxDelay)
    }
  }
  
  /// Maximum number of retry attempts
  var maxAttempts: Int {
    switch self {
    case .noRetry:
      return 0
    case .fixedDelay:
      return 3
    case .exponentialBackoff(_, _, let maxAttempts):
      return maxAttempts
    }
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let networkErrorOccurred = Notification.Name("NetworkErrorOccurred")
}

// MARK: - Error Equatable Implementation

extension NetworkError {
  static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
    switch (lhs, rhs) {
    case (.noConnection, .noConnection),
         (.timeout, .timeout),
         (.invalidResponse, .invalidResponse),
         (.dataCorrupted, .dataCorrupted),
         (.authenticationFailed, .authenticationFailed),
         (.forbidden, .forbidden),
         (.notFound, .notFound),
         (.tooManyRequests, .tooManyRequests),
         (.serverUnavailable, .serverUnavailable):
      return true
    case (.serverError(let lhsCode), .serverError(let rhsCode)):
      return lhsCode == rhsCode
    case (.rateLimited(let lhsRetry), .rateLimited(let rhsRetry)):
      return lhsRetry == rhsRetry
    case (.unknown, .unknown):
      return true
    default:
      return false
    }
  }
}

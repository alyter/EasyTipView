//
//  MFARateLimiter.swift
//  PolyPal
//
//  Created by Agent OS on 7/24/25.
//

import Foundation

/// Rate limiter for MFA verification attempts with exponential backoff
class MFARateLimiter {
  private var failureCount: Int = 0
  private var lastFailureTime: Date?
  private var isLocked: Bool = false
  private var lockUntil: Date?
  
  // Configuration
  private let maxFailures: Int = 5
  private let baseBackoffSeconds: TimeInterval = 1.0
  private let maxBackoffSeconds: TimeInterval = 300.0 // 5 minutes
  private let lockDurationSeconds: TimeInterval = 900.0 // 15 minutes
  
  /// Check if an attempt is allowed
  func canAttempt() -> Bool {
    let now = Date()
    
    // Check if we're currently locked
    if let lockUntil = lockUntil, now < lockUntil {
      return false
    }
    
    // If lock has expired, reset
    if let lockUntil = lockUntil, now >= lockUntil {
      reset()
    }
    
    // Check if we need to wait for backoff
    if let lastFailure = lastFailureTime {
      let backoffDelay = getBackoffDelay()
      let nextAllowedTime = lastFailure.addingTimeInterval(backoffDelay)
      
      if now < nextAllowedTime {
        return false
      }
    }
    
    return true
  }
  
  /// Record a failed verification attempt
  func recordFailedAttempt() {
    failureCount += 1
    lastFailureTime = Date()
    
    // Lock if too many failures
    if failureCount >= maxFailures {
      isLocked = true
      lockUntil = Date().addingTimeInterval(lockDurationSeconds)
    }
  }
  
  /// Record a successful verification attempt
  func recordSuccessfulAttempt() {
    reset()
  }
  
  /// Reset the rate limiter state
  func reset() {
    failureCount = 0
    lastFailureTime = nil
    isLocked = false
    lockUntil = nil
  }
  
  /// Get the current failure count
  func getFailureCount() -> Int {
    return failureCount
  }
  
  /// Calculate exponential backoff delay
  func getBackoffDelay() -> TimeInterval {
    guard failureCount > 0 else { return 0 }
    
    // Exponential backoff: base * (2 ^ (failures - 1))
    let exponentialDelay = baseBackoffSeconds * pow(2.0, Double(failureCount - 1))
    
    // Cap at maximum backoff
    return min(exponentialDelay, maxBackoffSeconds)
  }
  
  /// Get time remaining until next attempt is allowed
  func getTimeUntilNextAttempt() -> TimeInterval {
    let now = Date()
    
    // Check lock first
    if let lockUntil = lockUntil, now < lockUntil {
      return lockUntil.timeIntervalSince(now)
    }
    
    // Check backoff
    if let lastFailure = lastFailureTime {
      let backoffDelay = getBackoffDelay()
      let nextAllowedTime = lastFailure.addingTimeInterval(backoffDelay)
      
      if now < nextAllowedTime {
        return nextAllowedTime.timeIntervalSince(now)
      }
    }
    
    return 0
  }
  
  /// Check if currently locked due to too many failures
  func isCurrentlyLocked() -> Bool {
    guard let lockUntil = lockUntil else { return false }
    return Date() < lockUntil
  }
  
  /// Get remaining lock time in seconds
  func getRemainingLockTime() -> TimeInterval {
    guard let lockUntil = lockUntil else { return 0 }
    let remaining = lockUntil.timeIntervalSince(Date())
    return max(0, remaining)
  }
}

/// Thread-safe rate limiter for concurrent access
class ThreadSafeMFARateLimiter {
  private let rateLimiter = MFARateLimiter()
  private let queue = DispatchQueue(label: "com.polypal.mfa.ratelimiter", attributes: .concurrent)
  
  func canAttempt() -> Bool {
    return queue.sync {
      rateLimiter.canAttempt()
    }
  }
  
  func recordFailedAttempt() {
    queue.async(flags: .barrier) {
      self.rateLimiter.recordFailedAttempt()
    }
  }
  
  func recordSuccessfulAttempt() {
    queue.async(flags: .barrier) {
      self.rateLimiter.recordSuccessfulAttempt()
    }
  }
  
  func reset() {
    queue.async(flags: .barrier) {
      self.rateLimiter.reset()
    }
  }
  
  func getFailureCount() -> Int {
    return queue.sync {
      rateLimiter.getFailureCount()
    }
  }
  
  func getBackoffDelay() -> TimeInterval {
    return queue.sync {
      rateLimiter.getBackoffDelay()
    }
  }
  
  func getTimeUntilNextAttempt() -> TimeInterval {
    return queue.sync {
      rateLimiter.getTimeUntilNextAttempt()
    }
  }
  
  func isCurrentlyLocked() -> Bool {
    return queue.sync {
      rateLimiter.isCurrentlyLocked()
    }
  }
  
  func getRemainingLockTime() -> TimeInterval {
    return queue.sync {
      rateLimiter.getRemainingLockTime()
    }
  }
}

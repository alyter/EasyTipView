//
//  NetworkErrorView.swift
//  PolyPal
//
//  Created by Agent OS on 7/25/25.
//

import SwiftUI

/// View for displaying network errors with recovery options
struct NetworkErrorView: View {
  let error: NetworkError
  let onRetry: (() -> Void)?
  let onDismiss: (() -> Void)?
  
  @State private var isRetrying = false
  @State private var retryCountdown: Int = 0
  @State private var countdownTimer: Timer?
  
  init(
    error: NetworkError,
    onRetry: (() -> Void)? = nil,
    onDismiss: (() -> Void)? = nil
  ) {
    self.error = error
    self.onRetry = onRetry
    self.onDismiss = onDismiss
  }
  
  var body: some View {
    VStack(spacing: 20) {
      // Error Icon
      errorIcon
        .font(.system(size: 60))
        .foregroundColor(errorColor)
      
      // Error Title and Message
      VStack(spacing: 12) {
        Text(errorTitle)
          .font(.title2)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
        
        Text(NetworkErrorHandler.userFriendlyMessage(for: error))
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }
      
      // Recovery Actions
      VStack(spacing: 12) {
        if error.isRetryable && onRetry != nil {
          retryButton
        }
        
        if let suggestion = error.recoverySuggestion {
          Text(suggestion)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        
        if onDismiss != nil {
          dismissButton
        }
      }
    }
    .padding(24)
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    .onDisappear {
      stopCountdown()
    }
  }
  
  // MARK: - Error Icon
  
  @ViewBuilder
  private var errorIcon: some View {
    switch error {
    case .noConnection:
      Image(systemName: "wifi.slash")
    case .timeout:
      Image(systemName: "clock.badge.exclamationmark")
    case .serverError, .serverUnavailable:
      Image(systemName: "server.rack")
    case .authenticationFailed:
      Image(systemName: "person.badge.key.fill")
    case .forbidden:
      Image(systemName: "lock.fill")
    case .notFound:
      Image(systemName: "questionmark.folder.fill")
    case .rateLimited, .tooManyRequests:
      Image(systemName: "speedometer")
    default:
      Image(systemName: "exclamationmark.triangle.fill")
    }
  }
  
  // MARK: - Error Color
  
  private var errorColor: Color {
    switch error {
    case .noConnection:
      return .orange
    case .authenticationFailed, .forbidden:
      return .red
    case .rateLimited, .tooManyRequests:
      return .yellow
    case .serverError, .serverUnavailable:
      return .red
    default:
      return .orange
    }
  }
  
  // MARK: - Error Title
  
  private var errorTitle: String {
    switch error {
    case .noConnection:
      return "No Internet Connection"
    case .timeout:
      return "Request Timed Out"
    case .serverError:
      return "Server Error"
    case .authenticationFailed:
      return "Authentication Required"
    case .forbidden:
      return "Access Denied"
    case .notFound:
      return "Content Not Found"
    case .rateLimited, .tooManyRequests:
      return "Too Many Requests"
    case .serverUnavailable:
      return "Service Unavailable"
    default:
      return "Something Went Wrong"
    }
  }
  
  // MARK: - Retry Button
  
  @ViewBuilder
  private var retryButton: some View {
    Button(action: handleRetry) {
      HStack {
        if isRetrying {
          ProgressView()
            .scaleEffect(0.8)
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
        } else {
          Image(systemName: "arrow.clockwise")
        }
        
        Text(retryButtonText)
          .fontWeight(.medium)
      }
      .foregroundColor(.white)
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .background(errorColor)
      .cornerRadius(8)
    }
    .disabled(isRetrying || retryCountdown > 0)
    .opacity(isRetrying || retryCountdown > 0 ? 0.6 : 1.0)
  }
  
  private var retryButtonText: String {
    if isRetrying {
      return "Retrying..."
    } else if retryCountdown > 0 {
      return "Retry in \(retryCountdown)s"
    } else {
      return "Try Again"
    }
  }
  
  // MARK: - Dismiss Button
  
  @ViewBuilder
  private var dismissButton: some View {
    Button("Dismiss") {
      onDismiss?()
    }
    .foregroundColor(.secondary)
    .padding(.horizontal, 24)
    .padding(.vertical, 8)
  }
  
  // MARK: - Actions
  
  private func handleRetry() {
    guard !isRetrying, retryCountdown == 0 else { return }
    
    // Check if we need to wait before retrying
    let retryDelay = error.retryDelay
    if retryDelay > 1 {
      startCountdown(Int(retryDelay))
    } else {
      performRetry()
    }
  }
  
  private func performRetry() {
    isRetrying = true
    
    // Add a small delay to show the loading state
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
      onRetry?()
      isRetrying = false
    }
  }
  
  private func startCountdown(_ seconds: Int) {
    retryCountdown = seconds
    
    // Use a recursive approach with DispatchQueue instead of Timer to avoid capture issues
    func countdown() {
      if retryCountdown > 0 {
        retryCountdown -= 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          countdown()
        }
      } else {
        performRetry()
      }
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      countdown()
    }
  }
  
  private func stopCountdown() {
    countdownTimer?.invalidate()
    countdownTimer = nil
    retryCountdown = 0
  }
}

// MARK: - Network Error Banner

/// Compact banner view for displaying network errors
struct NetworkErrorBanner: View {
  let error: NetworkError
  let onRetry: (() -> Void)?
  let onDismiss: (() -> Void)?
  
  @State private var isVisible = true
  
  var body: some View {
    if isVisible {
      HStack(spacing: 12) {
        // Error Icon
        Image(systemName: bannerIcon)
          .foregroundColor(.white)
          .font(.system(size: 16, weight: .medium))
        
        // Error Message
        VStack(alignment: .leading, spacing: 2) {
          Text(bannerTitle)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
          
          Text(NetworkErrorHandler.userFriendlyMessage(for: error))
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.9))
            .lineLimit(2)
        }
        
        Spacer()
        
        // Action Buttons
        HStack(spacing: 8) {
          if error.isRetryable && onRetry != nil {
            Button("Retry") {
              onRetry?()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.2))
            .cornerRadius(4)
          }
          
          Button(action: {
            withAnimation(.easeOut(duration: 0.3)) {
              isVisible = false
            }
            Task { @MainActor in
              try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
              onDismiss?()
            }
          }) {
            Image(systemName: "xmark")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.white)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(bannerColor)
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  }
  
  private var bannerIcon: String {
    switch error {
    case .noConnection:
      return "wifi.slash"
    case .timeout:
      return "clock.badge.exclamationmark"
    case .serverError, .serverUnavailable:
      return "exclamationmark.triangle.fill"
    case .authenticationFailed:
      return "person.badge.key.fill"
    default:
      return "exclamationmark.circle.fill"
    }
  }
  
  private var bannerTitle: String {
    switch error {
    case .noConnection:
      return "No Internet Connection"
    case .timeout:
      return "Connection Timeout"
    case .serverError, .serverUnavailable:
      return "Server Error"
    case .authenticationFailed:
      return "Authentication Failed"
    default:
      return "Network Error"
    }
  }
  
  private var bannerColor: Color {
    switch error {
    case .noConnection:
      return .orange
    case .authenticationFailed:
      return .red
    case .serverError, .serverUnavailable:
      return .red
    default:
      return .orange
    }
  }
}

// MARK: - Offline Mode Indicator

/// View for indicating offline mode
struct OfflineModeIndicator: View {
  @State private var isVisible = true
  
  var body: some View {
    if isVisible {
      HStack(spacing: 8) {
        Image(systemName: "wifi.slash")
          .font(.system(size: 14, weight: .medium))
        
        Text("You're offline")
          .font(.system(size: 14, weight: .medium))
        
        Spacer()
        
        Text("Showing cached content")
          .font(.system(size: 12))
          .opacity(0.8)
      }
      .foregroundColor(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(.gray)
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  }
}

// MARK: - Preview

#Preview("Network Error View") {
  VStack(spacing: 20) {
    NetworkErrorView(
      error: .noConnection,
      onRetry: { print("Retry tapped") },
      onDismiss: { print("Dismiss tapped") }
    )
    
    NetworkErrorView(
      error: .rateLimited(retryAfter: 30),
      onRetry: { print("Retry tapped") }
    )
  }
  .padding()
  .background {
    #if canImport(UIKit)
    Color(.systemGroupedBackground)
    #elseif canImport(AppKit)
    Color(.windowBackgroundColor)
    #else
    Color.gray.opacity(0.1)
    #endif
  }
}

#Preview("Network Error Banner") {
  VStack(spacing: 0) {
    NetworkErrorBanner(
      error: .noConnection,
      onRetry: { print("Retry tapped") },
      onDismiss: { print("Dismiss tapped") }
    )
    
    NetworkErrorBanner(
      error: .serverError(500),
      onRetry: { print("Retry tapped") },
      onDismiss: { print("Dismiss tapped") }
    )
    
    OfflineModeIndicator()
    
    Spacer()
  }
  .background {
    #if canImport(UIKit)
    Color(.systemGroupedBackground)
    #elseif canImport(AppKit)
    Color(.windowBackgroundColor)
    #else
    Color.gray.opacity(0.1)
    #endif
  }
}

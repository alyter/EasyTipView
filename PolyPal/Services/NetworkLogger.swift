//
//  NetworkLogger.swift
//  PolyPal
//
//  Created by Agent OS on 7/25/25.
//

import Foundation
import os.log

/// Network logging and monitoring service
class NetworkLogger: @unchecked Sendable {
  
  // MARK: - Singleton
  
  nonisolated(unsafe) static let shared = NetworkLogger()
  
  // MARK: - Private Properties
  
  private let logger = Logger(subsystem: "com.polypal.app", category: "Network")
  private let analyticsLogger = Logger(subsystem: "com.polypal.app", category: "Analytics")
  private let performanceLogger = Logger(subsystem: "com.polypal.app", category: "Performance")
  
  private var networkMetrics: NetworkMetrics = NetworkMetrics()
  private let metricsQueue = DispatchQueue(label: "NetworkLogger.metrics", qos: .utility)
  
  // MARK: - Initialization
  
  private init() {
    setupPeriodicReporting()
  }
  
  // MARK: - Public Logging Methods
  
  /// Log network request start
  func logRequestStart(_ request: URLRequest, requestId: String = UUID().uuidString) {
    let url = request.url?.absoluteString ?? "unknown"
    let method = request.httpMethod ?? "GET"
    
    logger.info("🚀 Request started: \(method) \(url) [ID: \(requestId)]")
    
    metricsQueue.async {
      self.networkMetrics.recordRequestStart(requestId: requestId, url: url, method: method)
    }
  }
  
  /// Log successful network response
  func logRequestSuccess(_ response: HTTPURLResponse, data: Data?, requestId: String, duration: TimeInterval) {
    let url = response.url?.absoluteString ?? "unknown"
    let statusCode = response.statusCode
    let dataSize = data?.count ?? 0
    
    logger.info("✅ Request succeeded: \(statusCode) \(url) (\(dataSize) bytes, \(String(format: "%.2f", duration))s) [ID: \(requestId)]")
    
    metricsQueue.async {
      self.networkMetrics.recordRequestSuccess(
        requestId: requestId,
        statusCode: statusCode,
        responseSize: dataSize,
        duration: duration
      )
    }
    
    // Log performance metrics
    logPerformanceMetrics(url: url, duration: duration, dataSize: dataSize)
  }
  
  /// Log network request failure
  func logRequestFailure(_ error: Error, request: URLRequest?, requestId: String, duration: TimeInterval) {
    let url = request?.url?.absoluteString ?? "unknown"
    let errorDescription = error.localizedDescription
    
    logger.error("❌ Request failed: \(url) - \(errorDescription) (\(String(format: "%.2f", duration))s) [ID: \(requestId)]")
    
    metricsQueue.async {
      self.networkMetrics.recordRequestFailure(
        requestId: requestId,
        error: error,
        duration: duration
      )
    }
    
    // Log error analytics
    logErrorAnalytics(url: url, error: error, duration: duration)
  }
  
  /// Log network status change
  func logNetworkStatusChange(isConnected: Bool, connectionType: NetworkConnectionType, quality: NetworkQuality) {
    let status = isConnected ? "CONNECTED" : "DISCONNECTED"
    logger.info("📶 Network status: \(status) (\(connectionType), \(quality))")
    
    metricsQueue.async {
      self.networkMetrics.recordNetworkStatusChange(
        isConnected: isConnected,
        connectionType: connectionType,
        quality: quality
      )
    }
    
    // Log analytics event
    analyticsLogger.info("Network status changed: connected=\(isConnected), type=\(connectionType), quality=\(quality)")
  }
  
  /// Log offline mode change
  func logOfflineModeChange(isOffline: Bool, reason: OfflineReason) {
    let mode = isOffline ? "OFFLINE" : "ONLINE"
    logger.info("🔌 Offline mode: \(mode) (\(reason.displayName))")
    
    metricsQueue.async {
      self.networkMetrics.recordOfflineModeChange(isOffline: isOffline, reason: reason)
    }
    
    // Log analytics event
    analyticsLogger.info("Offline mode changed: offline=\(isOffline), reason=\(reason.displayName)")
  }
  
  /// Log cache operation
  func logCacheOperation(_ operation: CacheOperation, key: String, success: Bool, duration: TimeInterval? = nil) {
    let status = success ? "✅" : "❌"
    let durationText = duration.map { String(format: " (%.3fs)", $0) } ?? ""
    
    logger.debug("\(status) Cache \(operation.rawValue): \(key)\(durationText)")
    
    metricsQueue.async {
      self.networkMetrics.recordCacheOperation(operation, key: key, success: success, duration: duration)
    }
  }
  
  /// Log authentication event
  func logAuthenticationEvent(_ event: AuthenticationEvent, success: Bool, duration: TimeInterval? = nil) {
    let status = success ? "✅" : "❌"
    let durationText = duration.map { String(format: " (%.2fs)", $0) } ?? ""
    
    logger.info("\(status) Auth \(event.rawValue)\(durationText)")
    
    metricsQueue.async {
      self.networkMetrics.recordAuthenticationEvent(event, success: success, duration: duration)
    }
    
    // Log analytics event (without sensitive data)
    analyticsLogger.info("Authentication event: \(event.rawValue), success=\(success)")
  }
  
  /// Log retry attempt
  func logRetryAttempt(requestId: String, attempt: Int, delay: TimeInterval, reason: String) {
    logger.info("🔄 Retry attempt \(attempt) for request \(requestId) after \(String(format: "%.1f", delay))s - \(reason)")
    
    metricsQueue.async {
      self.networkMetrics.recordRetryAttempt(requestId: requestId, attempt: attempt, delay: delay, reason: reason)
    }
  }
  
  /// Log rate limiting
  func logRateLimiting(url: String, retryAfter: TimeInterval?) {
    let retryText = retryAfter.map { String(format: " (retry after %.0fs)", $0) } ?? ""
    logger.warning("⏱️ Rate limited: \(url)\(retryText)")
    
    metricsQueue.async {
      self.networkMetrics.recordRateLimiting(url: url, retryAfter: retryAfter)
    }
    
    // Log analytics event
    analyticsLogger.info("Rate limited: url=\(url), retryAfter=\(retryAfter ?? 0)")
  }
  
  // MARK: - Analytics and Metrics
  
  /// Get current network metrics
  func getNetworkMetrics() -> NetworkMetrics {
    return metricsQueue.sync {
      return networkMetrics
    }
  }
  
  /// Export metrics for analytics
  func exportMetricsForAnalytics() -> [String: Any] {
    return metricsQueue.sync {
      return networkMetrics.exportForAnalytics()
    }
  }
  
  /// Reset metrics (typically called daily)
  func resetMetrics() {
    metricsQueue.async {
      self.networkMetrics = NetworkMetrics()
      self.logger.info("📊 Network metrics reset")
    }
  }
  
  // MARK: - Private Methods
  
  private func logPerformanceMetrics(url: String, duration: TimeInterval, dataSize: Int) {
    let throughput = dataSize > 0 ? Double(dataSize) / duration / 1024.0 : 0 // KB/s
    
    performanceLogger.info("⚡ Performance: \(url) - \(String(format: "%.2f", duration))s, \(dataSize) bytes, \(String(format: "%.1f", throughput)) KB/s")
    
    // Log slow requests
    if duration > 5.0 {
      performanceLogger.warning("🐌 Slow request detected: \(url) took \(String(format: "%.2f", duration))s")
    }
    
    // Log large responses
    if dataSize > 1024 * 1024 { // 1MB
      performanceLogger.info("📦 Large response: \(url) returned \(dataSize / 1024 / 1024)MB")
    }
  }
  
  private func logErrorAnalytics(url: String, error: Error, duration: TimeInterval) {
    let errorType = String(describing: type(of: error))
    let errorCode = (error as NSError).code
    
    analyticsLogger.error("Network error: url=\(url), type=\(errorType), code=\(errorCode), duration=\(String(format: "%.2f", duration))")
    
    // Log specific error patterns
    if let urlError = error as? URLError {
      switch urlError.code {
      case .timedOut:
        analyticsLogger.info("Timeout error pattern detected for: \(url)")
      case .notConnectedToInternet:
        analyticsLogger.info("No internet connection detected")
      case .networkConnectionLost:
        analyticsLogger.info("Connection lost during request to: \(url)")
      default:
        break
      }
    }
  }
  
  private func setupPeriodicReporting() {
    // Report metrics every 5 minutes
    Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
      self?.reportPeriodicMetrics()
    }
  }
  
  private func reportPeriodicMetrics() {
    metricsQueue.async {
      let summary = self.networkMetrics.getSummary()
      
      self.analyticsLogger.info("""
        📊 Network Metrics Summary:
        - Requests: \(summary.totalRequests) (\(summary.successRate)% success)
        - Avg Response Time: \(String(format: "%.2f", summary.averageResponseTime))s
        - Cache Hit Rate: \(String(format: "%.1f", summary.cacheHitRate))%
        - Offline Events: \(summary.offlineEvents)
        - Retry Attempts: \(summary.retryAttempts)
        """)
    }
  }
}

// MARK: - Supporting Types

/// Cache operation types
enum CacheOperation: String, CaseIterable {
  case read = "READ"
  case write = "WRITE"
  case delete = "DELETE"
  case clear = "CLEAR"
  case hit = "HIT"
  case miss = "MISS"
}

/// Authentication event types
enum AuthenticationEvent: String, CaseIterable {
  case login = "LOGIN"
  case logout = "LOGOUT"
  case tokenRefresh = "TOKEN_REFRESH"
  case tokenExpired = "TOKEN_EXPIRED"
  case authenticationFailed = "AUTH_FAILED"
}

/// Network metrics data structure
struct NetworkMetrics {
  private var requests: [String: RequestMetric] = [:]
  private var networkEvents: [NetworkEvent] = []
  private var cacheOperations: [CacheMetric] = []
  private var authenticationEvents: [AuthMetric] = []
  private var retryAttempts: [RetryMetric] = []
  private var rateLimitEvents: [RateLimitMetric] = []
  
  // MARK: - Recording Methods
  
  mutating func recordRequestStart(requestId: String, url: String, method: String) {
    requests[requestId] = RequestMetric(
      id: requestId,
      url: url,
      method: method,
      startTime: Date()
    )
  }
  
  mutating func recordRequestSuccess(requestId: String, statusCode: Int, responseSize: Int, duration: TimeInterval) {
    requests[requestId]?.complete(success: true, statusCode: statusCode, responseSize: responseSize, duration: duration)
  }
  
  mutating func recordRequestFailure(requestId: String, error: Error, duration: TimeInterval) {
    requests[requestId]?.complete(success: false, error: error, duration: duration)
  }
  
  mutating func recordNetworkStatusChange(isConnected: Bool, connectionType: NetworkConnectionType, quality: NetworkQuality) {
    networkEvents.append(NetworkEvent(
      timestamp: Date(),
      isConnected: isConnected,
      connectionType: connectionType,
      quality: quality
    ))
  }
  
  mutating func recordOfflineModeChange(isOffline: Bool, reason: OfflineReason) {
    networkEvents.append(NetworkEvent(
      timestamp: Date(),
      isOffline: isOffline,
      offlineReason: reason
    ))
  }
  
  mutating func recordCacheOperation(_ operation: CacheOperation, key: String, success: Bool, duration: TimeInterval?) {
    cacheOperations.append(CacheMetric(
      timestamp: Date(),
      operation: operation,
      key: key,
      success: success,
      duration: duration
    ))
  }
  
  mutating func recordAuthenticationEvent(_ event: AuthenticationEvent, success: Bool, duration: TimeInterval?) {
    authenticationEvents.append(AuthMetric(
      timestamp: Date(),
      event: event,
      success: success,
      duration: duration
    ))
  }
  
  mutating func recordRetryAttempt(requestId: String, attempt: Int, delay: TimeInterval, reason: String) {
    retryAttempts.append(RetryMetric(
      timestamp: Date(),
      requestId: requestId,
      attempt: attempt,
      delay: delay,
      reason: reason
    ))
  }
  
  mutating func recordRateLimiting(url: String, retryAfter: TimeInterval?) {
    rateLimitEvents.append(RateLimitMetric(
      timestamp: Date(),
      url: url,
      retryAfter: retryAfter
    ))
  }
  
  // MARK: - Analysis Methods
  
  func getSummary() -> NetworkMetricsSummary {
    let completedRequests = requests.values.filter { $0.isCompleted }
    let successfulRequests = completedRequests.filter { $0.success == true }
    
    let totalRequests = completedRequests.count
    let successRate = totalRequests > 0 ? Double(successfulRequests.count) / Double(totalRequests) * 100 : 0
    
    let averageResponseTime = completedRequests.isEmpty ? 0 :
      completedRequests.compactMap { $0.duration }.reduce(0, +) / Double(completedRequests.count)
    
    let cacheHits = cacheOperations.filter { $0.operation == .hit }.count
    let cacheMisses = cacheOperations.filter { $0.operation == .miss }.count
    let cacheHitRate = (cacheHits + cacheMisses) > 0 ? Double(cacheHits) / Double(cacheHits + cacheMisses) * 100 : 0
    
    let offlineEvents = networkEvents.filter { $0.isOffline == true }.count
    
    return NetworkMetricsSummary(
      totalRequests: totalRequests,
      successRate: successRate,
      averageResponseTime: averageResponseTime,
      cacheHitRate: cacheHitRate,
      offlineEvents: offlineEvents,
      retryAttempts: retryAttempts.count
    )
  }
  
  func exportForAnalytics() -> [String: Any] {
    let summary = getSummary()
    
    return [
      "total_requests": summary.totalRequests,
      "success_rate": summary.successRate,
      "average_response_time": summary.averageResponseTime,
      "cache_hit_rate": summary.cacheHitRate,
      "offline_events": summary.offlineEvents,
      "retry_attempts": summary.retryAttempts,
      "rate_limit_events": rateLimitEvents.count,
      "auth_events": authenticationEvents.count,
      "timestamp": Date().timeIntervalSince1970
    ]
  }
}

// MARK: - Metric Data Structures

struct RequestMetric {
  let id: String
  let url: String
  let method: String
  let startTime: Date
  
  private(set) var isCompleted: Bool = false
  private(set) var success: Bool?
  private(set) var statusCode: Int?
  private(set) var responseSize: Int?
  private(set) var error: Error?
  private(set) var duration: TimeInterval?
  
  mutating func complete(success: Bool, statusCode: Int? = nil, responseSize: Int? = nil, error: Error? = nil, duration: TimeInterval) {
    self.isCompleted = true
    self.success = success
    self.statusCode = statusCode
    self.responseSize = responseSize
    self.error = error
    self.duration = duration
  }
}

struct NetworkEvent {
  let timestamp: Date
  let isConnected: Bool?
  let connectionType: NetworkConnectionType?
  let quality: NetworkQuality?
  let isOffline: Bool?
  let offlineReason: OfflineReason?
  
  init(timestamp: Date, isConnected: Bool, connectionType: NetworkConnectionType, quality: NetworkQuality) {
    self.timestamp = timestamp
    self.isConnected = isConnected
    self.connectionType = connectionType
    self.quality = quality
    self.isOffline = nil
    self.offlineReason = nil
  }
  
  init(timestamp: Date, isOffline: Bool, offlineReason: OfflineReason) {
    self.timestamp = timestamp
    self.isConnected = nil
    self.connectionType = nil
    self.quality = nil
    self.isOffline = isOffline
    self.offlineReason = offlineReason
  }
}

struct CacheMetric {
  let timestamp: Date
  let operation: CacheOperation
  let key: String
  let success: Bool
  let duration: TimeInterval?
}

struct AuthMetric {
  let timestamp: Date
  let event: AuthenticationEvent
  let success: Bool
  let duration: TimeInterval?
}

struct RetryMetric {
  let timestamp: Date
  let requestId: String
  let attempt: Int
  let delay: TimeInterval
  let reason: String
}

struct RateLimitMetric {
  let timestamp: Date
  let url: String
  let retryAfter: TimeInterval?
}

struct NetworkMetricsSummary {
  let totalRequests: Int
  let successRate: Double
  let averageResponseTime: TimeInterval
  let cacheHitRate: Double
  let offlineEvents: Int
  let retryAttempts: Int
}

//
//  OfflineManager.swift
//  PolyPal
//
//  Created by Agent OS on 7/25/25.
//

import Foundation
import SwiftUI
import Combine

/// Manager for handling offline mode and graceful degradation
@MainActor
class OfflineManager: ObservableObject {
  
  // MARK: - Published Properties
  
  @Published var isOffline: Bool = false
  @Published var offlineReason: OfflineReason = .none
  @Published var lastOnlineTime: Date?
  @Published var showOfflineIndicator: Bool = false
  
  // MARK: - Private Properties
  
  private let networkMonitor: NetworkMonitor
  private let cacheManager: CacheManager
  private var cancellables = Set<AnyCancellable>()
  private var offlineTimer: Timer?
  
  // MARK: - Initialization
  
  init(networkMonitor: NetworkMonitor, cacheManager: CacheManager) {
    self.networkMonitor = networkMonitor
    self.cacheManager = cacheManager
    setupNetworkObservation()
    setupNotificationObservers()
  }
  
  deinit {
    offlineTimer?.invalidate()
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Public Methods
  
  /// Check if a feature is available in offline mode
  func isFeatureAvailable(_ feature: OfflineFeature) -> Bool {
    if !isOffline {
      return true
    }
    
    switch feature {
    case .viewCachedOffers:
      return cacheManager.hasCachedData()
    case .searchCachedOffers:
      return cacheManager.hasCachedData()
    case .viewOfferDetails:
      return true // Details are cached with offers
    case .refreshOffers:
      return false
    case .authentication:
      return false // Requires network
    case .imageLoading:
      return false // Images require network
    case .syncData:
      return false
    }
  }
  
  /// Get offline capability message for a feature
  func offlineCapabilityMessage(for feature: OfflineFeature) -> String? {
    guard isOffline else { return nil }
    
    switch feature {
    case .viewCachedOffers:
      return cacheManager.hasCachedData() ? 
        "Showing cached offers from \(formatLastUpdateTime())" :
        "No cached offers available"
    case .searchCachedOffers:
      return "Search limited to cached offers"
    case .viewOfferDetails:
      return "Showing cached details"
    case .refreshOffers:
      return "Connect to internet to refresh offers"
    case .authentication:
      return "Authentication requires internet connection"
    case .imageLoading:
      return "Images unavailable offline"
    case .syncData:
      return "Data sync will resume when online"
    }
  }
  
  /// Get degraded functionality warning
  func getDegradedFunctionalityWarning() -> String? {
    guard isOffline else { return nil }
    
    let unavailableFeatures = OfflineFeature.allCases.filter { !isFeatureAvailable($0) }
    
    if unavailableFeatures.isEmpty {
      return nil
    }
    
    let featureNames = unavailableFeatures.map { $0.displayName }.joined(separator: ", ")
    return "Limited functionality: \(featureNames) unavailable offline"
  }
  
  /// Force offline mode (for testing or user preference)
  func setOfflineMode(_ offline: Bool, reason: OfflineReason = .userPreference) {
    if offline != isOffline {
      isOffline = offline
      offlineReason = offline ? reason : .none
      
      if offline {
        lastOnlineTime = Date()
        showOfflineIndicator = true
      } else {
        showOfflineIndicator = false
      }
      
      logOfflineStateChange()
      postOfflineStateNotification()
    }
  }
  
  /// Get cached data summary
  func getCachedDataSummary() -> CachedDataSummary {
    let offerCount = cacheManager.getCachedOfferCount()
    let lastUpdate = cacheManager.getLastCacheUpdate()
    let cacheSize = cacheManager.getCacheSize()
    
    return CachedDataSummary(
      offerCount: offerCount,
      lastUpdate: lastUpdate,
      cacheSize: cacheSize,
      isStale: isDataStale(lastUpdate)
    )
  }
  
  // MARK: - Private Methods
  
  private func setupNetworkObservation() {
    networkMonitor.$isConnected
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isConnected in
        self?.handleNetworkStatusChange(isConnected)
      }
      .store(in: &cancellables)
    
    networkMonitor.$networkQuality
      .receive(on: DispatchQueue.main)
      .sink { [weak self] quality in
        self?.handleNetworkQualityChange(quality)
      }
      .store(in: &cancellables)
  }
  
  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(networkErrorOccurred),
      name: .networkErrorOccurred,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
  }
  
  private func handleNetworkStatusChange(_ isConnected: Bool) {
    let wasOffline = isOffline
    
    if !isConnected {
      // Going offline
      if !wasOffline {
        isOffline = true
        offlineReason = .noConnection
        lastOnlineTime = Date()
        showOfflineIndicator = true
        startOfflineTimer()
        logOfflineStateChange()
        postOfflineStateNotification()
      }
    } else {
      // Coming online
      if wasOffline {
        isOffline = false
        offlineReason = .none
        showOfflineIndicator = false
        stopOfflineTimer()
        logOfflineStateChange()
        postOfflineStateNotification()
        
        // Trigger data sync when coming back online
        scheduleDataSync()
      }
    }
  }
  
  private func handleNetworkQualityChange(_ quality: NetworkQuality) {
    // Adjust offline behavior based on network quality
    if quality == .poor && !isOffline {
      // Consider entering degraded mode for very poor connections
      offlineReason = .poorConnection
      showOfflineIndicator = true
    } else if quality != .poor && offlineReason == .poorConnection {
      showOfflineIndicator = false
      offlineReason = .none
    }
  }
  
  @objc private func networkErrorOccurred(_ notification: Notification) {
    guard let error = notification.userInfo?["error"] as? NetworkError else { return }
    
    if NetworkErrorHandler.shouldTriggerOfflineMode(for: error) {
      setOfflineMode(true, reason: .networkError)
    }
  }
  
  @objc private func applicationWillEnterForeground() {
    // Check network status when app comes to foreground
    if isOffline && networkMonitor.isConnected {
      setOfflineMode(false)
    }
  }
  
  private func startOfflineTimer() {
    stopOfflineTimer()
    
    // Update offline duration periodically
    offlineTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
      self?.updateOfflineIndicator()
    }
  }
  
  private func stopOfflineTimer() {
    offlineTimer?.invalidate()
    offlineTimer = nil
  }
  
  private func updateOfflineIndicator() {
    // This triggers UI updates for offline duration
    objectWillChange.send()
  }
  
  private func scheduleDataSync() {
    // Schedule background data sync when coming back online
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      NotificationCenter.default.post(
        name: .shouldSyncData,
        object: nil,
        userInfo: ["reason": "back_online"]
      )
    }
  }
  
  private func logOfflineStateChange() {
    let state = isOffline ? "OFFLINE" : "ONLINE"
    let reason = offlineReason != .none ? " (\(offlineReason))" : ""
    print("OfflineManager: State changed to \(state)\(reason)")
    
    if isOffline, let lastOnline = lastOnlineTime {
      let duration = Date().timeIntervalSince(lastOnline)
      print("OfflineManager: Offline duration: \(formatDuration(duration))")
    }
  }
  
  private func postOfflineStateNotification() {
    NotificationCenter.default.post(
      name: .offlineStateChanged,
      object: self,
      userInfo: [
        "isOffline": isOffline,
        "reason": offlineReason,
        "lastOnlineTime": lastOnlineTime as Any,
        "cachedDataSummary": getCachedDataSummary()
      ]
    )
  }
  
  private func formatLastUpdateTime() -> String {
    guard let lastUpdate = cacheManager.getLastCacheUpdate() else {
      return "unknown time"
    }
    
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: lastUpdate, relativeTo: Date())
  }
  
  private func formatDuration(_ duration: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: duration) ?? "\(Int(duration))s"
  }
  
  private func isDataStale(_ lastUpdate: Date?) -> Bool {
    guard let lastUpdate = lastUpdate else { return true }
    return Date().timeIntervalSince(lastUpdate) > 900 // 15 minutes
  }
}

// MARK: - Supporting Types

/// Reasons for being offline
enum OfflineReason {
  case none
  case noConnection
  case networkError
  case poorConnection
  case userPreference
  case serverUnavailable
  
  var displayName: String {
    switch self {
    case .none:
      return ""
    case .noConnection:
      return "No internet connection"
    case .networkError:
      return "Network error"
    case .poorConnection:
      return "Poor connection"
    case .userPreference:
      return "Offline mode enabled"
    case .serverUnavailable:
      return "Server unavailable"
    }
  }
}

/// Features that may have offline capabilities
enum OfflineFeature: CaseIterable {
  case viewCachedOffers
  case searchCachedOffers
  case viewOfferDetails
  case refreshOffers
  case authentication
  case imageLoading
  case syncData
  
  var displayName: String {
    switch self {
    case .viewCachedOffers:
      return "View offers"
    case .searchCachedOffers:
      return "Search offers"
    case .viewOfferDetails:
      return "View details"
    case .refreshOffers:
      return "Refresh data"
    case .authentication:
      return "Sign in"
    case .imageLoading:
      return "Load images"
    case .syncData:
      return "Sync data"
    }
  }
}

/// Summary of cached data
struct CachedDataSummary {
  let offerCount: Int
  let lastUpdate: Date?
  let cacheSize: Int64
  let isStale: Bool
  
  var formattedCacheSize: String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useKB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: cacheSize)
  }
  
  var lastUpdateDescription: String {
    guard let lastUpdate = lastUpdate else {
      return "Never updated"
    }
    
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return "Updated \(formatter.localizedString(for: lastUpdate, relativeTo: Date()))"
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let offlineStateChanged = Notification.Name("OfflineStateChanged")
  static let shouldSyncData = Notification.Name("ShouldSyncData")
}

// MARK: - CacheManager Extensions

extension CacheManager {
  func hasCachedData() -> Bool {
    return getCachedOfferCount() > 0
  }
  
  func getCachedOfferCount() -> Int {
    // This would be implemented to return actual cached offer count
    // For now, return a placeholder
    return 0
  }
  
  func getLastCacheUpdate() -> Date? {
    // This would be implemented to return actual last update time
    // For now, return a placeholder
    return Date().addingTimeInterval(-300) // 5 minutes ago
  }
  
  func getCacheSize() -> Int64 {
    // This would be implemented to return actual cache size
    // For now, return a placeholder
    return 1024 * 1024 // 1MB
  }
}

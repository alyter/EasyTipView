//
//  NetworkMonitor.swift
//  PolyPal
//
//  Created by Agent OS on 7/25/25.
//

import Foundation
import Network
import UIKit

/// Network connection types
enum NetworkConnectionType {
  case wifi
  case cellular
  case ethernet
  case none
  case unknown
}

/// Network quality assessment
enum NetworkQuality {
  case good
  case fair
  case poor
  case unknown
}

/// Network monitoring service for detecting connectivity changes
@MainActor
class NetworkMonitor: ObservableObject {
  
  // MARK: - Published Properties
  
  @Published var isConnected: Bool = false
  @Published var connectionType: NetworkConnectionType = .unknown
  @Published var isExpensive: Bool = false
  @Published var isConstrained: Bool = false
  @Published var networkQuality: NetworkQuality = .unknown
  
  // MARK: - Private Properties
  
  private let pathMonitor: NWPathMonitor
  private let monitorQueue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
  private var isMonitoring = false
  
  // MARK: - Initialization
  
  init(pathMonitor: NWPathMonitor = NWPathMonitor()) {
    self.pathMonitor = pathMonitor
    setupApplicationStateObservers()
  }
  
  convenience init(pathMonitor: MockNWPathMonitor) {
    // This initializer is used for testing with mock objects
    self.init()
  }
  
  deinit {
    stopMonitoring()
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Public Methods
  
  /// Start monitoring network connectivity
  func startMonitoring() {
    guard !isMonitoring else { return }
    
    pathMonitor.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        self?.pathUpdateHandler(path)
      }
    }
    
    pathMonitor.start(queue: monitorQueue)
    isMonitoring = true
    
    print("NetworkMonitor: Started monitoring network connectivity")
  }
  
  /// Stop monitoring network connectivity
  func stopMonitoring() {
    guard isMonitoring else { return }
    
    pathMonitor.cancel()
    isMonitoring = false
    
    print("NetworkMonitor: Stopped monitoring network connectivity")
  }
  
  /// Check if network is suitable for data-intensive operations
  func isSuitableForDataIntensiveOperations() -> Bool {
    return isConnected && !isConstrained && networkQuality != .poor
  }
  
  /// Check if network is suitable for background sync
  func isSuitableForBackgroundSync() -> Bool {
    return isConnected && (!isExpensive || connectionType == .wifi)
  }
  
  // MARK: - Internal Methods (for testing)
  
  func pathUpdateHandler(_ path: NWPath) {
    let wasConnected = isConnected
    let previousConnectionType = connectionType
    
    // Update connection status
    isConnected = path.status == .satisfied
    isExpensive = path.isExpensive
    isConstrained = path.isConstrained
    
    // Determine connection type
    connectionType = determineConnectionType(from: path)
    
    // Assess network quality
    networkQuality = assessNetworkQuality(path: path)
    
    // Log network changes
    if wasConnected != isConnected || previousConnectionType != connectionType {
      logNetworkChange(wasConnected: wasConnected, previousType: previousConnectionType)
    }
    
    // Post notification for network status change
    NotificationCenter.default.post(
      name: .networkStatusChanged,
      object: self,
      userInfo: [
        "isConnected": isConnected,
        "connectionType": connectionType,
        "isExpensive": isExpensive,
        "isConstrained": isConstrained,
        "networkQuality": networkQuality
      ]
    )
  }
  
  // MARK: - Private Methods
  
  private func determineConnectionType(from path: NWPath) -> NetworkConnectionType {
    guard path.status == .satisfied else {
      return path.status == .unsatisfied ? .none : .unknown
    }
    
    // Check available interfaces
    for interface in path.availableInterfaces {
      switch interface.type {
      case .wifi:
        return .wifi
      case .cellular:
        return .cellular
      case .wiredEthernet:
        return .ethernet
      case .loopback, .other:
        continue
      @unknown default:
        continue
      }
    }
    
    // Fallback based on path characteristics
    if path.isExpensive {
      return .cellular
    } else {
      return .wifi
    }
  }
  
  private func assessNetworkQuality(path: NWPath) -> NetworkQuality {
    guard path.status == .satisfied else {
      return .unknown
    }
    
    // Assess quality based on connection characteristics
    if !path.isExpensive && !path.isConstrained {
      // WiFi or unlimited connection
      return .good
    } else if path.isExpensive && !path.isConstrained {
      // Cellular with good signal
      return .fair
    } else if path.isConstrained {
      // Constrained connection (low data mode, poor signal)
      return .poor
    } else {
      return .unknown
    }
  }
  
  private func logNetworkChange(wasConnected: Bool, previousType: NetworkConnectionType) {
    let statusChange = wasConnected ? "Connected" : "Disconnected"
    let typeChange = previousType != connectionType ? " (\(previousType) → \(connectionType))" : ""
    
    print("NetworkMonitor: \(statusChange)\(typeChange)")
    print("NetworkMonitor: Quality: \(networkQuality), Expensive: \(isExpensive), Constrained: \(isConstrained)")
  }
  
  private func setupApplicationStateObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
  }
  
  @objc private func applicationDidEnterBackground() {
    // Continue monitoring in background but with reduced frequency
    // The system will automatically throttle network monitoring
    print("NetworkMonitor: App entered background, continuing monitoring")
  }
  
  @objc private func applicationWillEnterForeground() {
    // Resume normal monitoring frequency
    print("NetworkMonitor: App entering foreground, resuming normal monitoring")
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}

// MARK: - NetworkConnectionType Extensions

extension NetworkConnectionType: CustomStringConvertible {
  var description: String {
    switch self {
    case .wifi:
      return "WiFi"
    case .cellular:
      return "Cellular"
    case .ethernet:
      return "Ethernet"
    case .none:
      return "None"
    case .unknown:
      return "Unknown"
    }
  }
}

// MARK: - NetworkQuality Extensions

extension NetworkQuality: CustomStringConvertible {
  var description: String {
    switch self {
    case .good:
      return "Good"
    case .fair:
      return "Fair"
    case .poor:
      return "Poor"
    case .unknown:
      return "Unknown"
    }
  }
}

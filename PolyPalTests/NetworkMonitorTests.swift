//
//  NetworkMonitorTests.swift
//  PolyPalTests
//
//  Created by Agent OS on 7/25/25.
//

import XCTest
import Network
@testable import PolyPal

final class NetworkMonitorTests: XCTestCase {
  
  var networkMonitor: NetworkMonitor!
  var mockPathMonitor: MockNWPathMonitor!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    mockPathMonitor = MockNWPathMonitor()
    networkMonitor = NetworkMonitor(pathMonitor: mockPathMonitor)
  }
  
  override func tearDownWithError() throws {
    networkMonitor = nil
    mockPathMonitor = nil
    try super.tearDownWithError()
  }
  
  // MARK: - Initialization Tests
  
  func testNetworkMonitorInitialization() {
    XCTAssertNotNil(networkMonitor)
    XCTAssertFalse(networkMonitor.isConnected)
    XCTAssertEqual(networkMonitor.connectionType, .unknown)
  }
  
  // MARK: - Network Status Tests
  
  func testNetworkConnectedStatus() {
    // Given
    let mockPath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: false)
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertTrue(networkMonitor.isConnected)
    XCTAssertEqual(networkMonitor.connectionType, .wifi)
  }
  
  func testNetworkDisconnectedStatus() {
    // Given
    let mockPath = MockNWPath(status: .unsatisfied, isExpensive: false, isConstrained: false)
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertFalse(networkMonitor.isConnected)
    XCTAssertEqual(networkMonitor.connectionType, .none)
  }
  
  func testCellularConnectionDetection() {
    // Given
    let mockPath = MockNWPath(status: .satisfied, isExpensive: true, isConstrained: false)
    mockPath.availableInterfaces = [MockNWInterface(type: .cellular)]
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertTrue(networkMonitor.isConnected)
    XCTAssertEqual(networkMonitor.connectionType, .cellular)
    XCTAssertTrue(networkMonitor.isExpensive)
  }
  
  func testWiFiConnectionDetection() {
    // Given
    let mockPath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: false)
    mockPath.availableInterfaces = [MockNWInterface(type: .wifi)]
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertTrue(networkMonitor.isConnected)
    XCTAssertEqual(networkMonitor.connectionType, .wifi)
    XCTAssertFalse(networkMonitor.isExpensive)
  }
  
  func testConstrainedNetworkDetection() {
    // Given
    let mockPath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: true)
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertTrue(networkMonitor.isConnected)
    XCTAssertTrue(networkMonitor.isConstrained)
  }
  
  // MARK: - State Transition Tests
  
  func testOnlineToOfflineTransition() {
    // Given - Start online
    let onlinePath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: false)
    networkMonitor.pathUpdateHandler(onlinePath)
    XCTAssertTrue(networkMonitor.isConnected)
    
    // When - Go offline
    let offlinePath = MockNWPath(status: .unsatisfied, isExpensive: false, isConstrained: false)
    networkMonitor.pathUpdateHandler(offlinePath)
    
    // Then
    XCTAssertFalse(networkMonitor.isConnected)
    XCTAssertEqual(networkMonitor.connectionType, .none)
  }
  
  func testOfflineToOnlineTransition() {
    // Given - Start offline
    let offlinePath = MockNWPath(status: .unsatisfied, isExpensive: false, isConstrained: false)
    networkMonitor.pathUpdateHandler(offlinePath)
    XCTAssertFalse(networkMonitor.isConnected)
    
    // When - Go online
    let onlinePath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: false)
    networkMonitor.pathUpdateHandler(onlinePath)
    
    // Then
    XCTAssertTrue(networkMonitor.isConnected)
  }
  
  func testWiFiToCellularTransition() {
    // Given - Start on WiFi
    let wifiPath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: false)
    wifiPath.availableInterfaces = [MockNWInterface(type: .wifi)]
    networkMonitor.pathUpdateHandler(wifiPath)
    XCTAssertEqual(networkMonitor.connectionType, .wifi)
    
    // When - Switch to cellular
    let cellularPath = MockNWPath(status: .satisfied, isExpensive: true, isConstrained: false)
    cellularPath.availableInterfaces = [MockNWInterface(type: .cellular)]
    networkMonitor.pathUpdateHandler(cellularPath)
    
    // Then
    XCTAssertEqual(networkMonitor.connectionType, .cellular)
    XCTAssertTrue(networkMonitor.isExpensive)
  }
  
  // MARK: - Notification Tests
  
  func testNetworkStatusChangeNotification() {
    // Given
    let expectation = XCTestExpectation(description: "Network status change notification")
    var receivedNotification = false
    
    let observer = NotificationCenter.default.addObserver(
      forName: .networkStatusChanged,
      object: nil,
      queue: .main
    ) { _ in
      receivedNotification = true
      expectation.fulfill()
    }
    
    // When
    let mockPath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: false)
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertTrue(receivedNotification)
    
    NotificationCenter.default.removeObserver(observer)
  }
  
  // MARK: - Monitoring Control Tests
  
  func testStartMonitoring() {
    // When
    networkMonitor.startMonitoring()
    
    // Then
    XCTAssertTrue(mockPathMonitor.startCalled)
  }
  
  func testStopMonitoring() {
    // Given
    networkMonitor.startMonitoring()
    
    // When
    networkMonitor.stopMonitoring()
    
    // Then
    XCTAssertTrue(mockPathMonitor.cancelCalled)
  }
  
  // MARK: - Network Quality Assessment Tests
  
  func testNetworkQualityGood() {
    // Given
    let mockPath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: false)
    mockPath.availableInterfaces = [MockNWInterface(type: .wifi)]
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertEqual(networkMonitor.networkQuality, .good)
  }
  
  func testNetworkQualityPoor() {
    // Given
    let mockPath = MockNWPath(status: .satisfied, isExpensive: true, isConstrained: true)
    mockPath.availableInterfaces = [MockNWInterface(type: .cellular)]
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertEqual(networkMonitor.networkQuality, .poor)
  }
  
  func testNetworkQualityFair() {
    // Given
    let mockPath = MockNWPath(status: .satisfied, isExpensive: true, isConstrained: false)
    mockPath.availableInterfaces = [MockNWInterface(type: .cellular)]
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertEqual(networkMonitor.networkQuality, .fair)
  }
  
  // MARK: - Background/Foreground State Tests
  
  func testBackgroundStateHandling() {
    // Given
    networkMonitor.startMonitoring()
    
    // When
    NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    
    // Then
    // Monitor should continue running but with reduced frequency
    XCTAssertTrue(mockPathMonitor.startCalled)
    XCTAssertFalse(mockPathMonitor.cancelCalled)
  }
  
  func testForegroundStateHandling() {
    // Given
    networkMonitor.startMonitoring()
    NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    
    // When
    NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    
    // Then
    // Monitor should resume normal operation
    XCTAssertTrue(mockPathMonitor.startCalled)
  }
  
  // MARK: - Error Scenario Tests
  
  func testNetworkRequiresConnectionHandling() {
    // Given
    let mockPath = MockNWPath(status: .requiresConnection, isExpensive: false, isConstrained: false)
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertFalse(networkMonitor.isConnected)
    XCTAssertEqual(networkMonitor.connectionType, .unknown)
  }
  
  func testNetworkUnsatisfiedHandling() {
    // Given
    let mockPath = MockNWPath(status: .unsatisfied, isExpensive: false, isConstrained: false)
    
    // When
    networkMonitor.pathUpdateHandler(mockPath)
    
    // Then
    XCTAssertFalse(networkMonitor.isConnected)
    XCTAssertEqual(networkMonitor.connectionType, .none)
  }
  
  // MARK: - Performance Tests
  
  func testNetworkStatusUpdatePerformance() {
    // Given
    let mockPath = MockNWPath(status: .satisfied, isExpensive: false, isConstrained: false)
    
    // When
    measure {
      for _ in 0..<1000 {
        networkMonitor.pathUpdateHandler(mockPath)
      }
    }
    
    // Then - Should complete within reasonable time
  }
}

// MARK: - Mock Classes

class MockNWPathMonitor {
  var startCalled = false
  var cancelCalled = false
  var pathUpdateHandler: ((NWPath) -> Void)?
  
  func start(queue: DispatchQueue) {
    startCalled = true
  }
  
  func cancel() {
    cancelCalled = true
  }
}

class MockNWPath: NWPath {
  private let _status: NWPath.Status
  private let _isExpensive: Bool
  private let _isConstrained: Bool
  var availableInterfaces: [NWInterface] = []
  
  init(status: NWPath.Status, isExpensive: Bool, isConstrained: Bool) {
    self._status = status
    self._isExpensive = isExpensive
    self._isConstrained = isConstrained
  }
  
  override var status: NWPath.Status {
    return _status
  }
  
  override var isExpensive: Bool {
    return _isExpensive
  }
  
  override var isConstrained: Bool {
    return _isConstrained
  }
  
  override var availableInterfaces: [NWInterface] {
    get { return self.availableInterfaces }
    set { self.availableInterfaces = newValue }
  }
}

class MockNWInterface: NWInterface {
  private let _type: NWInterface.InterfaceType
  
  init(type: NWInterface.InterfaceType) {
    self._type = type
  }
  
  override var type: NWInterface.InterfaceType {
    return _type
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}

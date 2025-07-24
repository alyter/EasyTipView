//
//  MainViewModel.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import Foundation
import SwiftUI

class MainViewModel: ObservableObject {
  @Published var selectedTab: TabSection = .buy
  @Published var messageBadgeCount: Int = 0
  @Published var favoritesBadgeCount: Int = 0
  
  // Tab selection tracking
  private var tabSelectionHistory: [TabSection] = []
  
  enum TabSection: Int, CaseIterable, Identifiable {
    case buy = 0
    case sell = 1
    case messages = 2
    case favorites = 3
    case account = 4
    
    var id: Int { rawValue }
    
    var title: String {
      switch self {
      case .buy:
        return "Buy"
      case .sell:
        return "Sell"
      case .messages:
        return "Messages"
      case .favorites:
        return "Favorites"
      case .account:
        return "Account"
      }
    }
    
    var icon: String {
      switch self {
      case .buy:
        return "magnifyingglass"
      case .sell:
        return "plus.circle"
      case .messages:
        return "message"
      case .favorites:
        return "heart"
      case .account:
        return "person"
      }
    }
    
    var selectedIcon: String {
      switch self {
      case .buy:
        return "magnifyingglass"
      case .sell:
        return "plus.circle.fill"
      case .messages:
        return "message.fill"
      case .favorites:
        return "heart.fill"
      case .account:
        return "person.fill"
      }
    }
  }
  
  init() {
    // Load persisted tab selection
    loadPersistedTabSelection()
  }
  
  // MARK: - Tab Selection
  
  func selectTab(_ tab: TabSection) {
    // Track previous tab
    if selectedTab != tab {
      tabSelectionHistory.append(selectedTab)
      
      // Limit history to last 10 selections
      if tabSelectionHistory.count > 10 {
        tabSelectionHistory.removeFirst()
      }
    }
    
    selectedTab = tab
    persistTabSelection()
    
    // Clear badge when selecting messages or favorites
    if tab == .messages {
      messageBadgeCount = 0
    } else if tab == .favorites {
      favoritesBadgeCount = 0
    }
  }
  
  func goToPreviousTab() {
    guard !tabSelectionHistory.isEmpty else { return }
    let previousTab = tabSelectionHistory.removeLast()
    selectedTab = previousTab
    persistTabSelection()
  }
  
  // MARK: - Badge Management
  
  func updateMessageBadge(count: Int) {
    messageBadgeCount = max(0, count)
  }
  
  func addMessageNotification() {
    messageBadgeCount += 1
  }
  
  func clearMessageBadge() {
    messageBadgeCount = 0
  }
  
  func updateFavoritesBadge(count: Int) {
    favoritesBadgeCount = max(0, count)
  }
  
  func addFavoriteNotification() {
    favoritesBadgeCount += 1
  }
  
  func clearFavoritesBadge() {
    favoritesBadgeCount = 0
  }
  
  // MARK: - Persistence
  
  private func persistTabSelection() {
    UserDefaults.standard.set(selectedTab.rawValue, forKey: "SelectedTab")
  }
  
  private func loadPersistedTabSelection() {
    let savedTab = UserDefaults.standard.integer(forKey: "SelectedTab")
    if let tab = TabSection(rawValue: savedTab) {
      selectedTab = tab
    }
  }
  
  // MARK: - Helper Properties
  
  var currentTabTitle: String {
    selectedTab.title
  }
  
  var currentTabIcon: String {
    selectedTab.selectedIcon
  }
  
  var hasPreviousTab: Bool {
    !tabSelectionHistory.isEmpty
  }
  
  var totalBadgeCount: Int {
    messageBadgeCount + favoritesBadgeCount
  }
  
  // MARK: - Reset
  
  func reset() {
    selectedTab = .buy
    messageBadgeCount = 0
    favoritesBadgeCount = 0
    tabSelectionHistory.removeAll()
    UserDefaults.standard.removeObject(forKey: "SelectedTab")
  }
}

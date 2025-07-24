//
//  MainViewModelTests.swift
//  PolyPalTests
//
//  Created on 2025-07-22.
//

import XCTest
@testable import PolyPal

final class MainViewModelTests: XCTestCase {
  
  var viewModel: MainViewModel!
  
  override func setUpWithError() throws {
    UserDefaults.standard.removeObject(forKey: "SelectedTab")
    viewModel = MainViewModel()
  }
  
  override func tearDownWithError() throws {
    UserDefaults.standard.removeObject(forKey: "SelectedTab")
    viewModel = nil
  }
  
  // MARK: - Initial State Tests
  
  func testInitialState() {
    XCTAssertEqual(viewModel.selectedTab, .buy)
    XCTAssertEqual(viewModel.messageBadgeCount, 0)
    XCTAssertEqual(viewModel.favoritesBadgeCount, 0)
    XCTAssertFalse(viewModel.hasPreviousTab)
    XCTAssertEqual(viewModel.totalBadgeCount, 0)
  }
  
  func testTabSectionProperties() {
    let buyTab = MainViewModel.TabSection.buy
    XCTAssertEqual(buyTab.id, 0)
    XCTAssertEqual(buyTab.title, "Buy")
    XCTAssertEqual(buyTab.icon, "magnifyingglass")
    XCTAssertEqual(buyTab.selectedIcon, "magnifyingglass")
    
    let sellTab = MainViewModel.TabSection.sell
    XCTAssertEqual(sellTab.id, 1)
    XCTAssertEqual(sellTab.title, "Sell")
    XCTAssertEqual(sellTab.icon, "plus.circle")
    XCTAssertEqual(sellTab.selectedIcon, "plus.circle.fill")
    
    let messagesTab = MainViewModel.TabSection.messages
    XCTAssertEqual(messagesTab.id, 2)
    XCTAssertEqual(messagesTab.title, "Messages")
    XCTAssertEqual(messagesTab.icon, "message")
    XCTAssertEqual(messagesTab.selectedIcon, "message.fill")
    
    let favoritesTab = MainViewModel.TabSection.favorites
    XCTAssertEqual(favoritesTab.id, 3)
    XCTAssertEqual(favoritesTab.title, "Favorites")
    XCTAssertEqual(favoritesTab.icon, "heart")
    XCTAssertEqual(favoritesTab.selectedIcon, "heart.fill")
    
    let accountTab = MainViewModel.TabSection.account
    XCTAssertEqual(accountTab.id, 4)
    XCTAssertEqual(accountTab.title, "Account")
    XCTAssertEqual(accountTab.icon, "person")
    XCTAssertEqual(accountTab.selectedIcon, "person.fill")
  }
  
  func testAllTabSections() {
    let allTabs = MainViewModel.TabSection.allCases
    XCTAssertEqual(allTabs.count, 5)
    XCTAssertTrue(allTabs.contains(.buy))
    XCTAssertTrue(allTabs.contains(.sell))
    XCTAssertTrue(allTabs.contains(.messages))
    XCTAssertTrue(allTabs.contains(.favorites))
    XCTAssertTrue(allTabs.contains(.account))
  }
  
  // MARK: - Tab Selection Tests
  
  func testSelectTab() {
    viewModel.selectTab(.sell)
    XCTAssertEqual(viewModel.selectedTab, .sell)
    XCTAssertEqual(viewModel.currentTabTitle, "Sell")
    XCTAssertEqual(viewModel.currentTabIcon, "plus.circle.fill")
  }
  
  func testTabSelectionHistory() {
    // Initially no previous tab
    XCTAssertFalse(viewModel.hasPreviousTab)
    
    // Select different tabs and verify history is tracked
    viewModel.selectTab(.sell)
    XCTAssertTrue(viewModel.hasPreviousTab)
    
    viewModel.selectTab(.messages)
    XCTAssertTrue(viewModel.hasPreviousTab)
    
    // Go back to previous tab
    viewModel.goToPreviousTab()
    XCTAssertEqual(viewModel.selectedTab, .sell)
    XCTAssertTrue(viewModel.hasPreviousTab)
    
    viewModel.goToPreviousTab()
    XCTAssertEqual(viewModel.selectedTab, .buy)
    XCTAssertFalse(viewModel.hasPreviousTab)
  }
  
  func testSelectSameTabDoesNotAddToHistory() {
    viewModel.selectTab(.buy) // Same as initial
    XCTAssertFalse(viewModel.hasPreviousTab)
    
    viewModel.selectTab(.sell)
    XCTAssertTrue(viewModel.hasPreviousTab)
    
    viewModel.selectTab(.sell) // Same tab again
    viewModel.goToPreviousTab()
    XCTAssertEqual(viewModel.selectedTab, .buy) // Should still go back to buy
  }
  
  // MARK: - Badge Management Tests
  
  func testMessageBadgeManagement() {
    // Test initial state
    XCTAssertEqual(viewModel.messageBadgeCount, 0)
    
    // Test adding notifications
    viewModel.addMessageNotification()
    XCTAssertEqual(viewModel.messageBadgeCount, 1)
    
    viewModel.addMessageNotification()
    XCTAssertEqual(viewModel.messageBadgeCount, 2)
    
    // Test updating badge count
    viewModel.updateMessageBadge(count: 5)
    XCTAssertEqual(viewModel.messageBadgeCount, 5)
    
    // Test negative count is handled
    viewModel.updateMessageBadge(count: -1)
    XCTAssertEqual(viewModel.messageBadgeCount, 0)
    
    // Test clearing badge
    viewModel.addMessageNotification()
    viewModel.clearMessageBadge()
    XCTAssertEqual(viewModel.messageBadgeCount, 0)
  }
  
  func testFavoritesBadgeManagement() {
    // Test initial state
    XCTAssertEqual(viewModel.favoritesBadgeCount, 0)
    
    // Test adding notifications
    viewModel.addFavoriteNotification()
    XCTAssertEqual(viewModel.favoritesBadgeCount, 1)
    
    viewModel.addFavoriteNotification()
    XCTAssertEqual(viewModel.favoritesBadgeCount, 2)
    
    // Test updating badge count
    viewModel.updateFavoritesBadge(count: 3)
    XCTAssertEqual(viewModel.favoritesBadgeCount, 3)
    
    // Test negative count is handled
    viewModel.updateFavoritesBadge(count: -2)
    XCTAssertEqual(viewModel.favoritesBadgeCount, 0)
    
    // Test clearing badge
    viewModel.addFavoriteNotification()
    viewModel.clearFavoritesBadge()
    XCTAssertEqual(viewModel.favoritesBadgeCount, 0)
  }
  
  func testTotalBadgeCount() {
    XCTAssertEqual(viewModel.totalBadgeCount, 0)
    
    viewModel.updateMessageBadge(count: 3)
    XCTAssertEqual(viewModel.totalBadgeCount, 3)
    
    viewModel.updateFavoritesBadge(count: 2)
    XCTAssertEqual(viewModel.totalBadgeCount, 5)
    
    viewModel.clearMessageBadge()
    XCTAssertEqual(viewModel.totalBadgeCount, 2)
  }
  
  func testSelectingTabClearsBadges() {
    // Set up badges
    viewModel.updateMessageBadge(count: 5)
    viewModel.updateFavoritesBadge(count: 3)
    
    // Selecting messages tab should clear message badge
    viewModel.selectTab(.messages)
    XCTAssertEqual(viewModel.messageBadgeCount, 0)
    XCTAssertEqual(viewModel.favoritesBadgeCount, 3) // Should remain unchanged
    
    // Reset badges
    viewModel.updateMessageBadge(count: 5)
    viewModel.updateFavoritesBadge(count: 3)
    
    // Selecting favorites tab should clear favorites badge
    viewModel.selectTab(.favorites)
    XCTAssertEqual(viewModel.favoritesBadgeCount, 0)
    XCTAssertEqual(viewModel.messageBadgeCount, 5) // Should remain unchanged
    
    // Selecting other tabs should not clear badges
    viewModel.updateMessageBadge(count: 2)
    viewModel.updateFavoritesBadge(count: 1)
    viewModel.selectTab(.buy)
    XCTAssertEqual(viewModel.messageBadgeCount, 2)
    XCTAssertEqual(viewModel.favoritesBadgeCount, 1)
  }
  
  // MARK: - Persistence Tests
  
  func testTabSelectionPersistence() {
    // Select a different tab
    viewModel.selectTab(.messages)
    
    // Create new view model to simulate app restart
    let newViewModel = MainViewModel()
    XCTAssertEqual(newViewModel.selectedTab, .messages)
  }
  
  func testTabSelectionPersistenceWithInvalidValue() {
    // Set invalid tab value in UserDefaults
    UserDefaults.standard.set(999, forKey: "SelectedTab")
    
    // Should default to .buy for invalid values
    let newViewModel = MainViewModel()
    XCTAssertEqual(newViewModel.selectedTab, .buy)
  }
  
  // MARK: - Helper Properties Tests
  
  func testCurrentTabProperties() {
    // Test buy tab properties
    XCTAssertEqual(viewModel.currentTabTitle, "Buy")
    XCTAssertEqual(viewModel.currentTabIcon, "magnifyingglass")
    
    // Test sell tab properties
    viewModel.selectTab(.sell)
    XCTAssertEqual(viewModel.currentTabTitle, "Sell")
    XCTAssertEqual(viewModel.currentTabIcon, "plus.circle.fill")
    
    // Test messages tab properties
    viewModel.selectTab(.messages)
    XCTAssertEqual(viewModel.currentTabTitle, "Messages")
    XCTAssertEqual(viewModel.currentTabIcon, "message.fill")
  }
  
  // MARK: - Reset Tests
  
  func testReset() {
    // Set up some state
    viewModel.selectTab(.account)
    viewModel.selectTab(.messages)
    viewModel.updateMessageBadge(count: 5)
    viewModel.updateFavoritesBadge(count: 3)
    
    // Verify state is set
    XCTAssertEqual(viewModel.selectedTab, .messages)
    XCTAssertTrue(viewModel.hasPreviousTab)
    XCTAssertEqual(viewModel.messageBadgeCount, 5)
    XCTAssertEqual(viewModel.favoritesBadgeCount, 3)
    
    // Reset
    viewModel.reset()
    
    // Verify everything is reset
    XCTAssertEqual(viewModel.selectedTab, .buy)
    XCTAssertFalse(viewModel.hasPreviousTab)
    XCTAssertEqual(viewModel.messageBadgeCount, 0)
    XCTAssertEqual(viewModel.favoritesBadgeCount, 0)
    XCTAssertEqual(viewModel.totalBadgeCount, 0)
    
    // Verify UserDefaults is cleared
    XCTAssertNil(UserDefaults.standard.object(forKey: "SelectedTab"))
  }
  
  // MARK: - History Limit Tests
  
  func testTabSelectionHistoryLimit() {
    // Add more than 10 tabs to history
    let tabs: [MainViewModel.TabSection] = [.sell, .messages, .favorites, .account, .buy, .sell, .messages, .favorites, .account, .buy, .sell, .messages]
    
    for tab in tabs {
      viewModel.selectTab(tab)
    }
    
    XCTAssertEqual(viewModel.selectedTab, .messages)
    XCTAssertTrue(viewModel.hasPreviousTab)
    
    // Should be able to go back, but only to the last 10 selections
    var backCount = 0
    while viewModel.hasPreviousTab && backCount < 15 { // Prevent infinite loop
      viewModel.goToPreviousTab()
      backCount += 1
    }
    
    // Should not exceed 10 back steps (the history limit)
    XCTAssertLessThanOrEqual(backCount, 10)
  }
}

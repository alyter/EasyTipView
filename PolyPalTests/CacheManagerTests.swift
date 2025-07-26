//
//  CacheManagerTests.swift
//  PolyPalTests
//
//  Created by AI Assistant on 2025-07-25.
//

import XCTest
import CoreData
@testable import PolyPal

@MainActor
final class CacheManagerTests: XCTestCase {
    
    var cacheManager: CacheManager!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        let container = NSPersistentContainer(name: "CacheModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        testContext = container.viewContext
        cacheManager = CacheManager(context: testContext)
    }
    
    override func tearDown() {
        cacheManager = nil
        testContext = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockOffer(id: String = "test_offer_1") -> Offer {
        return Offer(
            id: id,
            title: "Test Offer",
            description: "Test Description",
            price: 100.0,
            currency: "USD",
            category: "Electronics",
            condition: "New",
            location: "Test City",
            createdDate: Date(),
            updatedDate: Date(),
            expiryDate: Date().addingTimeInterval(86400), // 1 day from now
            isActive: true,
            userId: "test_user",
            images: ["image1.jpg"],
            specifications: ["brand": "TestBrand", "model": "TestModel"]
        )
    }
    
    private func createMockOffers(count: Int) -> [Offer] {
        return (1...count).map { index in
            createMockOffer(id: "test_offer_\(index)")
        }
    }
    
    // MARK: - Cache Storage Tests
    
    func testCacheOffer() async throws {
        let offer = createMockOffer()
        
        try await cacheManager.cacheOffer(offer)
        
        let cachedOffer = try await cacheManager.getCachedOffer(id: offer.id)
        XCTAssertNotNil(cachedOffer)
        XCTAssertEqual(cachedOffer?.id, offer.id)
        XCTAssertEqual(cachedOffer?.title, offer.title)
        XCTAssertEqual(cachedOffer?.price, offer.price)
    }
    
    func testCacheMultipleOffers() async throws {
        let offers = createMockOffers(count: 5)
        
        try await cacheManager.cacheOffers(offers)
        
        for offer in offers {
            let cachedOffer = try await cacheManager.getCachedOffer(id: offer.id)
            XCTAssertNotNil(cachedOffer)
            XCTAssertEqual(cachedOffer?.id, offer.id)
        }
    }
    
    func testUpdateCachedOffer() async throws {
        let originalOffer = createMockOffer()
        try await cacheManager.cacheOffer(originalOffer)
        
        var updatedOffer = originalOffer
        updatedOffer.title = "Updated Title"
        updatedOffer.price = 200.0
        
        try await cacheManager.cacheOffer(updatedOffer)
        
        let cachedOffer = try await cacheManager.getCachedOffer(id: originalOffer.id)
        XCTAssertEqual(cachedOffer?.title, "Updated Title")
        XCTAssertEqual(cachedOffer?.price, 200.0)
    }
    
    // MARK: - Cache Retrieval Tests
    
    func testGetCachedOfferNotFound() async throws {
        let cachedOffer = try await cacheManager.getCachedOffer(id: "nonexistent_offer")
        XCTAssertNil(cachedOffer)
    }
    
    func testGetAllCachedOffers() async throws {
        let offers = createMockOffers(count: 3)
        try await cacheManager.cacheOffers(offers)
        
        let cachedOffers = try await cacheManager.getAllCachedOffers()
        XCTAssertEqual(cachedOffers.count, 3)
        
        let cachedIds = Set(cachedOffers.map { $0.id })
        let originalIds = Set(offers.map { $0.id })
        XCTAssertEqual(cachedIds, originalIds)
    }
    
    func testGetCachedOffersWithPagination() async throws {
        let offers = createMockOffers(count: 10)
        try await cacheManager.cacheOffers(offers)
        
        let firstPage = try await cacheManager.getCachedOffers(limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)
        
        let secondPage = try await cacheManager.getCachedOffers(limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 5)
        
        // Ensure no overlap
        let firstPageIds = Set(firstPage.map { $0.id })
        let secondPageIds = Set(secondPage.map { $0.id })
        XCTAssertTrue(firstPageIds.isDisjoint(with: secondPageIds))
    }
    
    // MARK: - Memory Cache Tests
    
    func testMemoryCacheHit() async throws {
        let offer = createMockOffer()
        
        // Cache the offer
        try await cacheManager.cacheOffer(offer)
        
        // First retrieval should populate memory cache
        let firstRetrieval = try await cacheManager.getCachedOffer(id: offer.id)
        XCTAssertNotNil(firstRetrieval)
        
        // Second retrieval should hit memory cache
        let secondRetrieval = try await cacheManager.getCachedOffer(id: offer.id)
        XCTAssertNotNil(secondRetrieval)
        XCTAssertEqual(firstRetrieval?.id, secondRetrieval?.id)
    }
    
    func testMemoryCacheEviction() async throws {
        // Set a small memory cache size for testing
        cacheManager.setMemoryCacheLimit(2)
        
        let offers = createMockOffers(count: 3)
        try await cacheManager.cacheOffers(offers)
        
        // Access first two offers to put them in memory cache
        _ = try await cacheManager.getCachedOffer(id: offers[0].id)
        _ = try await cacheManager.getCachedOffer(id: offers[1].id)
        
        // Access third offer, should evict first offer from memory cache
        _ = try await cacheManager.getCachedOffer(id: offers[2].id)
        
        // All offers should still be retrievable (from persistent storage)
        for offer in offers {
            let cachedOffer = try await cacheManager.getCachedOffer(id: offer.id)
            XCTAssertNotNil(cachedOffer)
        }
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCacheInvalidationByAge() async throws {
        let offer = createMockOffer()
        try await cacheManager.cacheOffer(offer)
        
        // Manually set cache entry to be older than 15 minutes
        try await cacheManager.setCacheEntryAge(offerId: offer.id, age: TimeInterval(16 * 60)) // 16 minutes
        
        let isValid = await cacheManager.isCacheValid(for: offer.id)
        XCTAssertFalse(isValid)
    }
    
    func testCacheValidationWithinTimeLimit() async throws {
        let offer = createMockOffer()
        try await cacheManager.cacheOffer(offer)
        
        let isValid = await cacheManager.isCacheValid(for: offer.id)
        XCTAssertTrue(isValid)
    }
    
    func testInvalidateExpiredEntries() async throws {
        let offers = createMockOffers(count: 3)
        try await cacheManager.cacheOffers(offers)
        
        // Make first two offers expired
        try await cacheManager.setCacheEntryAge(offerId: offers[0].id, age: TimeInterval(16 * 60))
        try await cacheManager.setCacheEntryAge(offerId: offers[1].id, age: TimeInterval(17 * 60))
        
        let removedCount = try await cacheManager.invalidateExpiredEntries()
        XCTAssertEqual(removedCount, 2)
        
        // Verify expired entries are removed
        let cachedOffer1 = try await cacheManager.getCachedOffer(id: offers[0].id)
        let cachedOffer2 = try await cacheManager.getCachedOffer(id: offers[1].id)
        let cachedOffer3 = try await cacheManager.getCachedOffer(id: offers[2].id)
        
        XCTAssertNil(cachedOffer1)
        XCTAssertNil(cachedOffer2)
        XCTAssertNotNil(cachedOffer3)
    }
    
    func testInvalidateAllCache() async throws {
        let offers = createMockOffers(count: 5)
        try await cacheManager.cacheOffers(offers)
        
        let initialCount = try await cacheManager.getAllCachedOffers().count
        XCTAssertEqual(initialCount, 5)
        
        try await cacheManager.invalidateAllCache()
        
        let finalCount = try await cacheManager.getAllCachedOffers().count
        XCTAssertEqual(finalCount, 0)
    }
    
    // MARK: - Cache Size Management Tests
    
    func testCacheSizeLimit() async throws {
        // Set a small cache size limit for testing
        cacheManager.setCacheSizeLimit(3)
        
        let offers = createMockOffers(count: 5)
        try await cacheManager.cacheOffers(offers)
        
        let cachedOffers = try await cacheManager.getAllCachedOffers()
        XCTAssertLessThanOrEqual(cachedOffers.count, 3)
    }
    
    func testCacheCleanupWhenLimitExceeded() async throws {
        cacheManager.setCacheSizeLimit(2)
        
        let offers = createMockOffers(count: 4)
        
        // Cache offers one by one
        for offer in offers {
            try await cacheManager.cacheOffer(offer)
        }
        
        let cachedOffers = try await cacheManager.getAllCachedOffers()
        XCTAssertLessThanOrEqual(cachedOffers.count, 2)
    }
    
    func testGetCacheSize() async throws {
        let offers = createMockOffers(count: 3)
        try await cacheManager.cacheOffers(offers)
        
        let cacheSize = try await cacheManager.getCacheSize()
        XCTAssertEqual(cacheSize, 3)
    }
    
    func testGetCacheStorageSize() async throws {
        let offers = createMockOffers(count: 5)
        try await cacheManager.cacheOffers(offers)
        
        let storageSize = try await cacheManager.getCacheStorageSize()
        XCTAssertGreaterThan(storageSize, 0)
    }
    
    // MARK: - Offline Data Access Tests
    
    func testOfflineDataAccess() async throws {
        let offers = createMockOffers(count: 3)
        try await cacheManager.cacheOffers(offers)
        
        // Simulate offline mode
        cacheManager.setOfflineMode(true)
        
        let offlineOffers = try await cacheManager.getOfflineOffers()
        XCTAssertEqual(offlineOffers.count, 3)
        
        let offlineOffer = try await cacheManager.getOfflineOffer(id: offers[0].id)
        XCTAssertNotNil(offlineOffer)
        XCTAssertEqual(offlineOffer?.id, offers[0].id)
    }
    
    func testOfflineDataFiltering() async throws {
        let offers = createMockOffers(count: 5)
        // Modify some offers for filtering
        var modifiedOffers = offers
        modifiedOffers[0].category = "Electronics"
        modifiedOffers[1].category = "Electronics"
        modifiedOffers[2].category = "Books"
        modifiedOffers[3].category = "Books"
        modifiedOffers[4].category = "Clothing"
        
        try await cacheManager.cacheOffers(modifiedOffers)
        
        cacheManager.setOfflineMode(true)
        
        let filters = OfferFilters(category: "Electronics")
        let filteredOffers = try await cacheManager.getOfflineOffers(filters: filters)
        
        XCTAssertEqual(filteredOffers.count, 2)
        XCTAssertTrue(filteredOffers.allSatisfy { $0.category == "Electronics" })
    }
    
    // MARK: - Synchronization Tests
    
    func testMarkOfferForSync() async throws {
        let offer = createMockOffer()
        try await cacheManager.cacheOffer(offer)
        
        try await cacheManager.markOfferForSync(id: offer.id)
        
        let syncPendingOffers = try await cacheManager.getOffersNeedingSync()
        XCTAssertEqual(syncPendingOffers.count, 1)
        XCTAssertEqual(syncPendingOffers[0].id, offer.id)
    }
    
    func testClearSyncFlag() async throws {
        let offer = createMockOffer()
        try await cacheManager.cacheOffer(offer)
        try await cacheManager.markOfferForSync(id: offer.id)
        
        try await cacheManager.clearSyncFlag(for: offer.id)
        
        let syncPendingOffers = try await cacheManager.getOffersNeedingSync()
        XCTAssertEqual(syncPendingOffers.count, 0)
    }
    
    func testSyncStatusTracking() async throws {
        let offers = createMockOffers(count: 3)
        try await cacheManager.cacheOffers(offers)
        
        // Mark first two for sync
        try await cacheManager.markOfferForSync(id: offers[0].id)
        try await cacheManager.markOfferForSync(id: offers[1].id)
        
        let syncStatus = try await cacheManager.getSyncStatus()
        XCTAssertEqual(syncStatus.totalCached, 3)
        XCTAssertEqual(syncStatus.needingSync, 2)
        XCTAssertEqual(syncStatus.synced, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testCacheErrorHandling() async {
        // Test with invalid context
        let invalidCacheManager = CacheManager(context: nil)
        
        do {
            let offer = createMockOffer()
            try await invalidCacheManager.cacheOffer(offer)
            XCTFail("Expected error when using invalid context")
        } catch {
            XCTAssertTrue(error is CacheError)
        }
    }
    
    func testCacheCorruptionRecovery() async throws {
        let offers = createMockOffers(count: 3)
        try await cacheManager.cacheOffers(offers)
        
        // Simulate cache corruption
        try await cacheManager.simulateCacheCorruption()
        
        // Cache should recover gracefully
        let recoveredOffers = try await cacheManager.getAllCachedOffers()
        XCTAssertEqual(recoveredOffers.count, 0) // Cache should be cleared on corruption
        
        // Should be able to cache new offers after recovery
        let newOffer = createMockOffer(id: "recovery_test")
        try await cacheManager.cacheOffer(newOffer)
        
        let cachedOffer = try await cacheManager.getCachedOffer(id: "recovery_test")
        XCTAssertNotNil(cachedOffer)
    }
    
    // MARK: - Performance Tests
    
    func testCachePerformanceWithLargeDataset() {
        let offers = createMockOffers(count: 1000)
        
        measure {
            Task {
                try? await cacheManager.cacheOffers(offers)
            }
        }
    }
    
    func testRetrievalPerformanceWithLargeDataset() async throws {
        let offers = createMockOffers(count: 1000)
        try await cacheManager.cacheOffers(offers)
        
        measure {
            Task {
                _ = try? await cacheManager.getAllCachedOffers()
            }
        }
    }
    
    func testMemoryCachePerformance() async throws {
        let offers = createMockOffers(count: 100)
        try await cacheManager.cacheOffers(offers)
        
        // Warm up memory cache
        for offer in offers.prefix(10) {
            _ = try await cacheManager.getCachedOffer(id: offer.id)
        }
        
        measure {
            Task {
                // Access cached offers multiple times
                for offer in offers.prefix(10) {
                    _ = try? await cacheManager.getCachedOffer(id: offer.id)
                }
            }
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentCacheOperations() async throws {
        let offers = createMockOffers(count: 10)
        
        await withTaskGroup(of: Void.self) { group in
            for offer in offers {
                group.addTask {
                    try? await self.cacheManager.cacheOffer(offer)
                }
            }
        }
        
        let cachedOffers = try await cacheManager.getAllCachedOffers()
        XCTAssertEqual(cachedOffers.count, 10)
    }
    
    func testConcurrentReadOperations() async throws {
        let offers = createMockOffers(count: 5)
        try await cacheManager.cacheOffers(offers)
        
        await withTaskGroup(of: Offer?.self) { group in
            for offer in offers {
                group.addTask {
                    try? await self.cacheManager.getCachedOffer(id: offer.id)
                }
            }
            
            var retrievedCount = 0
            for await result in group {
                if result != nil {
                    retrievedCount += 1
                }
            }
            
            XCTAssertEqual(retrievedCount, 5)
        }
    }
}

// MARK: - Test Extensions

extension CacheManagerTests {
    
    struct MockCacheEntry {
        let id: String
        let data: Data
        let timestamp: Date
        let needsSync: Bool
    }
}

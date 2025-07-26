//
//  CacheManager.swift
//  PolyPal
//
//  Created by AI Assistant on 2025-07-25.
//

import Foundation
import CoreData
import OSLog

// MARK: - Cache Error Types

enum CacheError: Error, LocalizedError {
    case invalidContext
    case corruptedData
    case storageError(String)
    case syncError(String)
    case memoryPressure
    
    var errorDescription: String? {
        switch self {
        case .invalidContext:
            return "Invalid Core Data context"
        case .corruptedData:
            return "Cache data is corrupted"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .syncError(let message):
            return "Sync error: \(message)"
        case .memoryPressure:
            return "Memory pressure detected"
        }
    }
}

// MARK: - Cache Sync Status

struct CacheSyncStatus {
    let totalCached: Int
    let needingSync: Int
    let synced: Int
    let lastSyncDate: Date?
}

// MARK: - Cache Manager

@MainActor
class CacheManager: ObservableObject {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext?
    private let logger = Logger(subsystem: "com.polypal.app", category: "CacheManager")
    private let encryptionService: DataEncryptionService
    
    // Memory cache for frequently accessed offers
    private var memoryCache: NSCache<NSString, Offer> = {
        let cache = NSCache<NSString, Offer>()
        cache.countLimit = 50 // Default limit
        cache.totalCostLimit = 10 * 1024 * 1024 // 10MB
        return cache
    }()
    
    // Cache configuration
    private var cacheExpirationInterval: TimeInterval = 15 * 60 // 15 minutes
    private var maxCacheSize: Int = 1000 // Maximum number of cached offers
    private var isOfflineMode: Bool = false
    private var encryptionEnabled: Bool = true
    
    // Background queue for cache operations
    private let cacheQueue = DispatchQueue(label: "com.polypal.cache", qos: .utility)
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext?, encryptionService: DataEncryptionService = DataEncryptionService()) {
        self.context = context
        self.encryptionService = encryptionService
        setupMemoryWarningObserver()
        setupCacheCleanupTimer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func setupCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.performPeriodicCleanup()
            }
        }
    }
    
    private func handleMemoryWarning() {
        logger.warning("Memory warning received, clearing memory cache")
        memoryCache.removeAllObjects()
    }
    
    private func performPeriodicCleanup() async {
        do {
            let removedCount = try await invalidateExpiredEntries()
            if removedCount > 0 {
                logger.info("Periodic cleanup removed \(removedCount) expired entries")
            }
        } catch {
            logger.error("Periodic cleanup failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cache Storage Methods
    
    func cacheOffer(_ offer: Offer) async throws {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        try await context.perform {
            // Check if offer already exists
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", offer.id)
            
            let existingOffers = try context.fetch(fetchRequest)
            let cachedOffer = existingOffers.first ?? CachedOffer(context: context)
            
            // Update cached offer with new data
            self.updateCachedOffer(cachedOffer, with: offer)
            
            try context.save()
            
            // Update memory cache
            self.memoryCache.setObject(offer, forKey: offer.id as NSString)
            
            // Enforce cache size limit
            try await self.enforceCacheSizeLimit()
        }
        
        logger.debug("Cached offer: \(offer.id)")
    }
    
    func cacheOffers(_ offers: [Offer]) async throws {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        try await context.perform {
            for offer in offers {
                // Check if offer already exists
                let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", offer.id)
                
                let existingOffers = try context.fetch(fetchRequest)
                let cachedOffer = existingOffers.first ?? CachedOffer(context: context)
                
                // Update cached offer with new data
                self.updateCachedOffer(cachedOffer, with: offer)
                
                // Update memory cache
                self.memoryCache.setObject(offer, forKey: offer.id as NSString)
            }
            
            try context.save()
            
            // Enforce cache size limit
            try await self.enforceCacheSizeLimit()
        }
        
        logger.debug("Cached \(offers.count) offers")
    }
    
    private func updateCachedOffer(_ cachedOffer: CachedOffer, with offer: Offer) {
        cachedOffer.id = offer.id
        
        // Encrypt sensitive data if encryption is enabled
        if encryptionEnabled {
            do {
                cachedOffer.title = try encryptionService.encryptString(offer.title)
                cachedOffer.descriptionText = try encryptionService.encryptString(offer.description)
                cachedOffer.location = try encryptionService.encryptString(offer.location)
                
                // Encrypt specifications dictionary
                if !offer.specifications.isEmpty {
                    let specificationsData = try JSONEncoder().encode(offer.specifications)
                    let encryptedSpecs = try encryptionService.encrypt(specificationsData)
                    cachedOffer.encryptedSpecifications = encryptedSpecs
                    cachedOffer.specifications = nil // Clear unencrypted version
                } else {
                    cachedOffer.specifications = offer.specifications
                }
                
                // Encrypt images array
                if !offer.images.isEmpty {
                    let imagesData = try JSONEncoder().encode(offer.images)
                    let encryptedImages = try encryptionService.encrypt(imagesData)
                    cachedOffer.encryptedImages = encryptedImages
                    cachedOffer.images = nil // Clear unencrypted version
                } else {
                    cachedOffer.images = offer.images
                }
                
            } catch {
                logger.error("Failed to encrypt offer data: \(error.localizedDescription)")
                // Fall back to unencrypted storage
                cachedOffer.title = offer.title
                cachedOffer.descriptionText = offer.description
                cachedOffer.location = offer.location
                cachedOffer.images = offer.images
                cachedOffer.specifications = offer.specifications
            }
        } else {
            cachedOffer.title = offer.title
            cachedOffer.descriptionText = offer.description
            cachedOffer.location = offer.location
            cachedOffer.images = offer.images
            cachedOffer.specifications = offer.specifications
        }
        
        // Non-sensitive data (not encrypted)
        cachedOffer.price = offer.price
        cachedOffer.currency = offer.currency
        cachedOffer.category = offer.category
        cachedOffer.condition = offer.condition
        cachedOffer.createdDate = offer.createdDate
        cachedOffer.updatedDate = offer.updatedDate
        cachedOffer.expiryDate = offer.expiryDate
        cachedOffer.isActive = offer.status.isAvailable
        cachedOffer.userId = offer.sellerID
        cachedOffer.cachedDate = Date()
        cachedOffer.lastAccessDate = Date()
    }
    
    // MARK: - Cache Retrieval Methods
    
    func getCachedOffer(id: String) async throws -> Offer? {
        // Check memory cache first
        if let cachedOffer = memoryCache.object(forKey: id as NSString) {
            logger.debug("Cache hit (memory): \(id)")
            return cachedOffer
        }
        
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            guard let cachedOffer = try context.fetch(fetchRequest).first else {
                return nil
            }
            
            // Update last access date
            cachedOffer.lastAccessDate = Date()
            try context.save()
            
            let offer = self.convertToOffer(cachedOffer)
            
            // Update memory cache
            self.memoryCache.setObject(offer, forKey: id as NSString)
            
            self.logger.debug("Cache hit (persistent): \(id)")
            return offer
        }
    }
    
    func getAllCachedOffers() async throws -> [Offer] {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastAccessDate", ascending: false)]
            
            let cachedOffers = try context.fetch(fetchRequest)
            return cachedOffers.map { self.convertToOffer($0) }
        }
    }
    
    func getCachedOffers(limit: Int, offset: Int) async throws -> [Offer] {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastAccessDate", ascending: false)]
            fetchRequest.fetchLimit = limit
            fetchRequest.fetchOffset = offset
            
            let cachedOffers = try context.fetch(fetchRequest)
            return cachedOffers.map { self.convertToOffer($0) }
        }
    }
    
    private func convertToOffer(_ cachedOffer: CachedOffer) -> Offer {
        // Decrypt sensitive data if encryption is enabled
        var title = cachedOffer.title ?? ""
        var description = cachedOffer.descriptionText ?? ""
        var location = cachedOffer.location ?? ""
        var images: [String] = []
        var specifications: [String: String] = [:]
        
        if encryptionEnabled {
            do {
                // Decrypt title if it exists
                if let encryptedTitle = cachedOffer.title, !encryptedTitle.isEmpty {
                    title = try encryptionService.decryptString(encryptedTitle)
                }
                
                // Decrypt description if it exists
                if let encryptedDescription = cachedOffer.descriptionText, !encryptedDescription.isEmpty {
                    description = try encryptionService.decryptString(encryptedDescription)
                }
                
                // Decrypt location if it exists
                if let encryptedLocation = cachedOffer.location, !encryptedLocation.isEmpty {
                    location = try encryptionService.decryptString(encryptedLocation)
                }
                
                // Decrypt images if encrypted data exists
                if let encryptedImages = cachedOffer.encryptedImages {
                    let decryptedData = try encryptionService.decrypt(encryptedImages)
                    images = try JSONDecoder().decode([String].self, from: decryptedData)
                } else {
                    images = cachedOffer.images ?? []
                }
                
                // Decrypt specifications if encrypted data exists
                if let encryptedSpecs = cachedOffer.encryptedSpecifications {
                    let decryptedData = try encryptionService.decrypt(encryptedSpecs)
                    specifications = try JSONDecoder().decode([String: String].self, from: decryptedData)
                } else {
                    specifications = cachedOffer.specifications ?? [:]
                }
                
            } catch {
                logger.error("Failed to decrypt cached offer data: \(error.localizedDescription)")
                // Fall back to unencrypted data if available
                title = cachedOffer.title ?? ""
                description = cachedOffer.descriptionText ?? ""
                location = cachedOffer.location ?? ""
                images = cachedOffer.images ?? []
                specifications = cachedOffer.specifications ?? [:]
            }
        } else {
            // Use unencrypted data directly
            images = cachedOffer.images ?? []
            specifications = cachedOffer.specifications ?? [:]
        }
        
        // Create a minimal Offer struct that matches the actual model
        // Note: Some fields will have default values since they're not stored in cache
        return Offer(
            id: cachedOffer.id ?? "",
            title: title,
            description: description,
            price: cachedOffer.price,
            currency: cachedOffer.currency ?? "USD",
            category: cachedOffer.category ?? "",
            subcategory: nil,
            condition: cachedOffer.condition ?? "",
            location: location,
            sellerID: cachedOffer.userId ?? "",
            sellerName: "Unknown", // Not stored in cache
            sellerRating: nil,
            images: images,
            specifications: specifications,
            createdDate: cachedOffer.createdDate ?? Date(),
            updatedDate: cachedOffer.updatedDate ?? Date(),
            expiryDate: cachedOffer.expiryDate,
            status: cachedOffer.isActive ? .active : .expired,
            viewCount: 0, // Not stored in cache
            favoriteCount: 0, // Not stored in cache
            isNegotiable: false, // Not stored in cache
            shippingOptions: [], // Not stored in cache
            tags: [] // Not stored in cache
        )
    }
    
    // MARK: - Cache Invalidation Methods
    
    func isCacheValid(for offerId: String) async -> Bool {
        guard let context = context else {
            return false
        }
        
        do {
            return try await context.perform {
                let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", offerId)
                fetchRequest.fetchLimit = 1
                
                guard let cachedOffer = try context.fetch(fetchRequest).first else {
                    return false
                }
                
                let cacheAge = Date().timeIntervalSince(cachedOffer.cachedDate ?? Date.distantPast)
                return cacheAge < self.cacheExpirationInterval
            }
        } catch {
            logger.error("Cache validation failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func invalidateExpiredEntries() async throws -> Int {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            let expirationDate = Date().addingTimeInterval(-self.cacheExpirationInterval)
            fetchRequest.predicate = NSPredicate(format: "cachedDate < %@", expirationDate as NSDate)
            
            let expiredOffers = try context.fetch(fetchRequest)
            let removedCount = expiredOffers.count
            
            for offer in expiredOffers {
                // Remove from memory cache
                if let offerId = offer.id {
                    self.memoryCache.removeObject(forKey: offerId as NSString)
                }
                context.delete(offer)
            }
            
            try context.save()
            return removedCount
        }
    }
    
    func invalidateAllCache() async throws {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CachedOffer.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            try context.execute(deleteRequest)
            try context.save()
        }
        
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        logger.info("All cache invalidated")
    }
    
    // MARK: - Cache Size Management Methods
    
    func setCacheSizeLimit(_ limit: Int) {
        maxCacheSize = limit
        logger.debug("Cache size limit set to \(limit)")
    }
    
    func setMemoryCacheLimit(_ limit: Int) {
        memoryCache.countLimit = limit
        logger.debug("Memory cache limit set to \(limit)")
    }
    
    func getCacheSize() async throws -> Int {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            return try context.count(for: fetchRequest)
        }
    }
    
    func getCacheStorageSize() async throws -> Int64 {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            let cachedOffers = try context.fetch(fetchRequest)
            
            var totalSize: Int64 = 0
            for offer in cachedOffers {
                // Estimate size based on string lengths and data
                totalSize += Int64((offer.title?.count ?? 0) * 2) // UTF-16 encoding
                totalSize += Int64((offer.descriptionText?.count ?? 0) * 2)
                totalSize += Int64((offer.category?.count ?? 0) * 2)
                totalSize += Int64((offer.condition?.count ?? 0) * 2)
                totalSize += Int64((offer.location?.count ?? 0) * 2)
                totalSize += Int64((offer.currency?.count ?? 0) * 2)
                totalSize += Int64((offer.userId?.count ?? 0) * 2)
                
                // Estimate images array size
                if let images = offer.images {
                    totalSize += Int64(images.count * 100) // Rough estimate per image URL
                }
                
                // Estimate specifications dictionary size
                if let specs = offer.specifications {
                    for (key, value) in specs {
                        totalSize += Int64((key.count + value.count) * 2)
                    }
                }
                
                // Add fixed overhead for dates and other properties
                totalSize += 200
            }
            
            return totalSize
        }
    }
    
    private func enforceCacheSizeLimit() async throws {
        let currentSize = try await getCacheSize()
        
        if currentSize > maxCacheSize {
            let excessCount = currentSize - maxCacheSize
            try await removeOldestEntries(count: excessCount)
            logger.info("Removed \(excessCount) entries to enforce cache size limit")
        }
    }
    
    private func removeOldestEntries(count: Int) async throws {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastAccessDate", ascending: true)]
            fetchRequest.fetchLimit = count
            
            let oldestOffers = try context.fetch(fetchRequest)
            
            for offer in oldestOffers {
                // Remove from memory cache
                if let offerId = offer.id {
                    self.memoryCache.removeObject(forKey: offerId as NSString)
                }
                context.delete(offer)
            }
            
            try context.save()
        }
    }
    
    // MARK: - Offline Data Access Methods
    
    func setOfflineMode(_ isOffline: Bool) {
        isOfflineMode = isOffline
        logger.debug("Offline mode set to \(isOffline)")
    }
    
    func getOfflineOffers() async throws -> [Offer] {
        return try await getAllCachedOffers()
    }
    
    func getOfflineOffer(id: String) async throws -> Offer? {
        return try await getCachedOffer(id: id)
    }
    
    func getOfflineOffers(filters: OfferFilters) async throws -> [Offer] {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            var predicates: [NSPredicate] = []
            
            // Apply filters
            if let category = filters.category {
                predicates.append(NSPredicate(format: "category == %@", category))
            }
            
            if let condition = filters.condition {
                predicates.append(NSPredicate(format: "condition == %@", condition))
            }
            
            if let location = filters.location {
                predicates.append(NSPredicate(format: "location CONTAINS[cd] %@", location))
            }
            
            if let minPrice = filters.minPrice {
                predicates.append(NSPredicate(format: "price >= %f", minPrice))
            }
            
            if let maxPrice = filters.maxPrice {
                predicates.append(NSPredicate(format: "price <= %f", maxPrice))
            }
            
            if let searchTerm = filters.searchTerm {
                let searchPredicate = NSPredicate(format: "title CONTAINS[cd] %@ OR descriptionText CONTAINS[cd] %@", searchTerm, searchTerm)
                predicates.append(searchPredicate)
            }
            
            if !predicates.isEmpty {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            // Apply sorting
            if let sortBy = filters.sortBy {
                let ascending = filters.sortOrder == .ascending
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: ascending)]
            } else {
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastAccessDate", ascending: false)]
            }
            
            let cachedOffers = try context.fetch(fetchRequest)
            return cachedOffers.map { self.convertToOffer($0) }
        }
    }
    
    // MARK: - Synchronization Methods
    
    func markOfferForSync(id: String) async throws {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            guard let cachedOffer = try context.fetch(fetchRequest).first else {
                throw CacheError.storageError("Offer not found in cache: \(id)")
            }
            
            cachedOffer.needsSync = true
            try context.save()
        }
        
        logger.debug("Marked offer for sync: \(id)")
    }
    
    func clearSyncFlag(for offerId: String) async throws {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", offerId)
            fetchRequest.fetchLimit = 1
            
            guard let cachedOffer = try context.fetch(fetchRequest).first else {
                return // Offer not in cache, nothing to clear
            }
            
            cachedOffer.needsSync = false
            try context.save()
        }
        
        logger.debug("Cleared sync flag for offer: \(offerId)")
    }
    
    func getOffersNeedingSync() async throws -> [Offer] {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "needsSync == YES")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedDate", ascending: true)]
            
            let cachedOffers = try context.fetch(fetchRequest)
            return cachedOffers.map { self.convertToOffer($0) }
        }
    }
    
    func getSyncStatus() async throws -> CacheSyncStatus {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        return try await context.perform {
            let totalRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            let totalCached = try context.count(for: totalRequest)
            
            let syncRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            syncRequest.predicate = NSPredicate(format: "needsSync == YES")
            let needingSync = try context.count(for: syncRequest)
            
            let synced = totalCached - needingSync
            
            return CacheSyncStatus(
                totalCached: totalCached,
                needingSync: needingSync,
                synced: synced,
                lastSyncDate: UserDefaults.standard.object(forKey: "lastCacheSync") as? Date
            )
        }
    }
    
    // MARK: - Testing and Debug Methods
    
    func setCacheEntryAge(offerId: String, age: TimeInterval) async throws {
        guard let context = context else {
            throw CacheError.invalidContext
        }
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", offerId)
            fetchRequest.fetchLimit = 1
            
            guard let cachedOffer = try context.fetch(fetchRequest).first else {
                throw CacheError.storageError("Offer not found in cache: \(offerId)")
            }
            
            cachedOffer.cachedDate = Date().addingTimeInterval(-age)
            try context.save()
        }
    }
    
    func simulateCacheCorruption() async throws {
        // For testing purposes - clear all cache data
        try await invalidateAllCache()
        logger.warning("Cache corruption simulated - all data cleared")
    }
}

// MARK: - Extensions

extension OfferFilters {
    var sortBy: String? {
        switch self.sortBy {
        case .title:
            return "title"
        case .price:
            return "price"
        case .createdDate:
            return "createdDate"
        case .updatedDate:
            return "updatedDate"
        case .viewCount:
            return "lastAccessDate" // Map to available field
        case .favoriteCount:
            return "lastAccessDate" // Map to available field
        }
    }
    
    var searchTerm: String? {
        return searchQuery
    }
}

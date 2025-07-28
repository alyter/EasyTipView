//
//  Offer.swift
//  PolyPal
//
//  Created by AI Assistant on 2025-07-25.
//

import Foundation

// MARK: - Offer Data Model
struct Offer: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let price: Double
    let currency: String
    let category: String
    let subcategory: String?
    let condition: String
    let location: String
    let sellerID: String
    let sellerName: String
    let sellerRating: Double?
    let images: [String]
    let specifications: [String: String]
    let createdDate: Date
    let updatedDate: Date
    let expiryDate: Date?
    let status: OfferStatus
    let viewCount: Int
    let favoriteCount: Int
    let isNegotiable: Bool
    let shippingOptions: [ShippingOption]
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Title"
        case description = "Description"
        case price = "Price"
        case currency = "Currency"
        case category = "Category"
        case subcategory = "Subcategory"
        case condition = "Condition"
        case location = "Location"
        case sellerID = "Seller_ID"
        case sellerName = "Seller_Name"
        case sellerRating = "Seller_Rating"
        case images = "Images"
        case specifications = "Specifications"
        case createdDate = "Created_Time"
        case updatedDate = "Modified_Time"
        case expiryDate = "Expiry_Date"
        case status = "Status"
        case viewCount = "View_Count"
        case favoriteCount = "Favorite_Count"
        case isNegotiable = "Is_Negotiable"
        case shippingOptions = "Shipping_Options"
        case tags = "Tags"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        price = try container.decode(Double.self, forKey: .price)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
        category = try container.decode(String.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        condition = try container.decode(String.self, forKey: .condition)
        location = try container.decode(String.self, forKey: .location)
        sellerID = try container.decode(String.self, forKey: .sellerID)
        sellerName = try container.decode(String.self, forKey: .sellerName)
        sellerRating = try container.decodeIfPresent(Double.self, forKey: .sellerRating)
        
        // Handle images - can be string or array
        if let imageString = try? container.decode(String.self, forKey: .images) {
            images = imageString.isEmpty ? [] : [imageString]
        } else {
            images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        }
        
        // Handle specifications dictionary
        if let specsString = try? container.decode(String.self, forKey: .specifications) {
            specifications = Self.parseSpecificationsString(specsString)
        } else {
            specifications = try container.decodeIfPresent([String: String].self, forKey: .specifications) ?? [:]
        }
        
        // Handle date parsing
        createdDate = try DateParser.parseDate(from: container, forKey: .createdDate)
        updatedDate = try DateParser.parseDate(from: container, forKey: .updatedDate)
        expiryDate = try? DateParser.parseDate(from: container, forKey: .expiryDate)
        
        // Handle status
        let statusString = try container.decode(String.self, forKey: .status)
        status = OfferStatus(rawValue: statusString) ?? .active
        
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        favoriteCount = try container.decodeIfPresent(Int.self, forKey: .favoriteCount) ?? 0
        isNegotiable = try container.decodeIfPresent(Bool.self, forKey: .isNegotiable) ?? false
        shippingOptions = try container.decodeIfPresent([ShippingOption].self, forKey: .shippingOptions) ?? []
        
        // Handle tags - can be string or array
        if let tagsString = try? container.decode(String.self, forKey: .tags) {
            tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(price, forKey: .price)
        try container.encode(currency, forKey: .currency)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(subcategory, forKey: .subcategory)
        try container.encode(condition, forKey: .condition)
        try container.encode(location, forKey: .location)
        try container.encode(sellerID, forKey: .sellerID)
        try container.encode(sellerName, forKey: .sellerName)
        try container.encodeIfPresent(sellerRating, forKey: .sellerRating)
        try container.encode(images, forKey: .images)
        try container.encode(specifications, forKey: .specifications)
        try container.encode(DateParser.formatDate(createdDate), forKey: .createdDate)
        try container.encode(DateParser.formatDate(updatedDate), forKey: .updatedDate)
        try container.encodeIfPresent(expiryDate.map(DateParser.formatDate), forKey: .expiryDate)
        try container.encode(status.rawValue, forKey: .status)
        try container.encode(viewCount, forKey: .viewCount)
        try container.encode(favoriteCount, forKey: .favoriteCount)
        try container.encode(isNegotiable, forKey: .isNegotiable)
        try container.encode(shippingOptions, forKey: .shippingOptions)
        try container.encode(tags, forKey: .tags)
    }
    
    private static func parseSpecificationsString(_ string: String) -> [String: String] {
        var specs: [String: String] = [:]
        let pairs = string.components(separatedBy: ";")
        
        for pair in pairs {
            let keyValue = pair.components(separatedBy: ":")
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespaces)
                let value = keyValue[1].trimmingCharacters(in: .whitespaces)
                specs[key] = value
            }
        }
        
        return specs
    }
    
    // Factory method for creating offers from cache data
    static func fromCache(
        id: String,
        title: String,
        description: String,
        price: Double,
        currency: String,
        category: String,
        subcategory: String?,
        condition: String,
        location: String,
        sellerID: String,
        sellerName: String,
        sellerRating: Double?,
        images: [String],
        specifications: [String: String],
        createdDate: Date,
        updatedDate: Date,
        expiryDate: Date?,
        status: OfferStatus,
        viewCount: Int,
        favoriteCount: Int,
        isNegotiable: Bool,
        shippingOptions: [ShippingOption],
        tags: [String]
    ) -> Offer {
        // Create a temporary JSON representation and decode it
        let json: [String: Any] = [
            "ID": id,
            "Title": title,
            "Description": description,
            "Price": price,
            "Currency": currency,
            "Category": category,
            "Subcategory": subcategory as Any,
            "Condition": condition,
            "Location": location,
            "Seller_ID": sellerID,
            "Seller_Name": sellerName,
            "Seller_Rating": sellerRating as Any,
            "Images": images,
            "Specifications": specifications,
            "Created_Time": DateParser.formatDate(createdDate),
            "Modified_Time": DateParser.formatDate(updatedDate),
            "Expiry_Date": expiryDate.map(DateParser.formatDate) as Any,
            "Status": status.rawValue,
            "View_Count": viewCount,
            "Favorite_Count": favoriteCount,
            "Is_Negotiable": isNegotiable,
            "Shipping_Options": shippingOptions.map { option in
                [
                    "Method": option.method,
                    "Cost": option.cost,
                    "Estimated_Days": option.estimatedDays,
                    "Description": option.description as Any
                ]
            },
            "Tags": tags
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json)
            let decoder = JSONDecoder()
            return try decoder.decode(Offer.self, from: data)
        } catch {
            // Fallback to a minimal offer if decoding fails
            fatalError("Failed to create offer from cache data: \(error)")
        }
    }
}

// MARK: - Offer Status
enum OfferStatus: String, Codable, CaseIterable {
    case active = "Active"
    case sold = "Sold"
    case expired = "Expired"
    case draft = "Draft"
    case suspended = "Suspended"
    
    var displayName: String {
        return rawValue
    }
    
    var isAvailable: Bool {
        return self == .active
    }
}

// MARK: - Shipping Option
struct ShippingOption: Codable, Equatable {
    let method: String
    let cost: Double
    let estimatedDays: Int
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case method = "Method"
        case cost = "Cost"
        case estimatedDays = "Estimated_Days"
        case description = "Description"
    }
}

// MARK: - Offer Filters
struct OfferFilters: Codable, Equatable {
    var searchQuery: String?
    var category: String?
    var subcategory: String?
    var minPrice: Double?
    var maxPrice: Double?
    var condition: String?
    var location: String?
    var sellerRating: Double?
    var isNegotiable: Bool?
    var hasImages: Bool?
    var sortBy: SortOption
    var sortOrder: SortOrder
    var pageSize: Int
    var pageNumber: Int
    
    init(
        searchQuery: String? = nil,
        category: String? = nil,
        subcategory: String? = nil,
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        condition: String? = nil,
        location: String? = nil,
        sellerRating: Double? = nil,
        isNegotiable: Bool? = nil,
        hasImages: Bool? = nil,
        sortBy: SortOption = .createdDate,
        sortOrder: SortOrder = .descending,
        pageSize: Int = 20,
        pageNumber: Int = 1
    ) {
        self.searchQuery = searchQuery
        self.category = category
        self.subcategory = subcategory
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.condition = condition
        self.location = location
        self.sellerRating = sellerRating
        self.isNegotiable = isNegotiable
        self.hasImages = hasImages
        self.sortBy = sortBy
        self.sortOrder = sortOrder
        self.pageSize = pageSize
        self.pageNumber = pageNumber
    }
    
    func toQueryParameters() -> [String: String] {
        var params: [String: String] = [:]
        
        if let searchQuery = searchQuery, !searchQuery.isEmpty {
            params["search"] = searchQuery
        }
        
        if let category = category {
            params["Category"] = category
        }
        
        if let subcategory = subcategory {
            params["Subcategory"] = subcategory
        }
        
        if let minPrice = minPrice {
            params["Price_min"] = String(minPrice)
        }
        
        if let maxPrice = maxPrice {
            params["Price_max"] = String(maxPrice)
        }
        
        if let condition = condition {
            params["Condition"] = condition
        }
        
        if let location = location {
            params["Location"] = location
        }
        
        if let sellerRating = sellerRating {
            params["Seller_Rating_min"] = String(sellerRating)
        }
        
        if let isNegotiable = isNegotiable {
            params["Is_Negotiable"] = String(isNegotiable)
        }
        
        if let hasImages = hasImages, hasImages {
            params["Images_exists"] = "true"
        }
        
        params["sort_by"] = sortBy.rawValue
        params["sort_order"] = sortOrder.rawValue
        params["per_page"] = String(pageSize)
        params["page"] = String(pageNumber)
        
        return params
    }
}

// MARK: - Sort Options
enum SortOption: String, Codable, CaseIterable, Equatable {
    case createdDate = "Created_Time"
    case updatedDate = "Modified_Time"
    case price = "Price"
    case title = "Title"
    case viewCount = "View_Count"
    case favoriteCount = "Favorite_Count"
    
    var displayName: String {
        switch self {
        case .createdDate:
            return "Date Created"
        case .updatedDate:
            return "Date Updated"
        case .price:
            return "Price"
        case .title:
            return "Title"
        case .viewCount:
            return "Views"
        case .favoriteCount:
            return "Favorites"
        }
    }
}

enum SortOrder: String, Codable, CaseIterable {
    case ascending = "asc"
    case descending = "desc"
    
    var displayName: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}

// MARK: - Zoho API Response
struct ZohoAPIResponse<T: Codable>: Codable {
    let data: [T]
    let info: ResponseInfo
    
    struct ResponseInfo: Codable {
        let count: Int
        let page: Int
        let perPage: Int
        let totalCount: Int
        let hasMore: Bool
        
        enum CodingKeys: String, CodingKey {
            case count
            case page
            case perPage = "per_page"
            case totalCount = "total_count"
            case hasMore = "more_records"
        }
    }
}

// MARK: - Date Parser Utility
struct DateParser {
    private static nonisolated(unsafe) let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let fallbackFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    private static let simpleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static func parseDate<K: CodingKey>(from container: KeyedDecodingContainer<K>, forKey key: K) throws -> Date {
        let dateString = try container.decode(String.self, forKey: key)
        return parseDate(from: dateString) ?? Date()
    }
    
    static func parseDate(from dateString: String) -> Date? {
        // Try ISO8601 format first
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try fallback format
        if let date = fallbackFormatter.date(from: dateString) {
            return date
        }
        
        // Try simple date format
        if let date = simpleDateFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
    
    static func formatDate(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
}

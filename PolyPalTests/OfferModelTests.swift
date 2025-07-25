//
//  OfferModelTests.swift
//  PolyPalTests
//
//  Created by AI Assistant on 2025-07-25.
//

import XCTest
@testable import PolyPal

final class OfferModelTests: XCTestCase {
    
    // MARK: - Test Data
    
    private let sampleOfferJSON = """
    {
        "ID": "12345",
        "Title": "iPhone 14 Pro",
        "Description": "Excellent condition iPhone 14 Pro with original box",
        "Price": 899.99,
        "Currency": "USD",
        "Category": "Electronics",
        "Subcategory": "Smartphones",
        "Condition": "Like New",
        "Location": "New York, NY",
        "Seller_ID": "seller123",
        "Seller_Name": "John Doe",
        "Seller_Rating": 4.8,
        "Images": ["image1.jpg", "image2.jpg"],
        "Specifications": {"Color": "Space Black", "Storage": "256GB", "Carrier": "Unlocked"},
        "Created_Time": "2025-07-25T10:30:00.000Z",
        "Modified_Time": "2025-07-25T11:00:00.000Z",
        "Expiry_Date": "2025-08-25T10:30:00.000Z",
        "Status": "Active",
        "View_Count": 150,
        "Favorite_Count": 25,
        "Is_Negotiable": true,
        "Shipping_Options": [
            {
                "Method": "Standard",
                "Cost": 9.99,
                "Estimated_Days": 5,
                "Description": "Standard shipping"
            }
        ],
        "Tags": ["smartphone", "apple", "unlocked"]
    }
    """
    
    private let minimalOfferJSON = """
    {
        "ID": "67890",
        "Title": "Test Item",
        "Description": "Test description",
        "Price": 50.0,
        "Category": "Test Category",
        "Condition": "Good",
        "Location": "Test Location",
        "Seller_ID": "test_seller",
        "Seller_Name": "Test Seller",
        "Created_Time": "2025-07-25T12:00:00.000Z",
        "Modified_Time": "2025-07-25T12:00:00.000Z",
        "Status": "Active"
    }
    """
    
    // MARK: - Offer Decoding Tests
    
    func testOfferDecodingWithCompleteData() throws {
        let data = sampleOfferJSON.data(using: .utf8)!
        let offer = try JSONDecoder().decode(Offer.self, from: data)
        
        XCTAssertEqual(offer.id, "12345")
        XCTAssertEqual(offer.title, "iPhone 14 Pro")
        XCTAssertEqual(offer.description, "Excellent condition iPhone 14 Pro with original box")
        XCTAssertEqual(offer.price, 899.99)
        XCTAssertEqual(offer.currency, "USD")
        XCTAssertEqual(offer.category, "Electronics")
        XCTAssertEqual(offer.subcategory, "Smartphones")
        XCTAssertEqual(offer.condition, "Like New")
        XCTAssertEqual(offer.location, "New York, NY")
        XCTAssertEqual(offer.sellerID, "seller123")
        XCTAssertEqual(offer.sellerName, "John Doe")
        XCTAssertEqual(offer.sellerRating, 4.8)
        XCTAssertEqual(offer.images, ["image1.jpg", "image2.jpg"])
        XCTAssertEqual(offer.specifications["Color"], "Space Black")
        XCTAssertEqual(offer.specifications["Storage"], "256GB")
        XCTAssertEqual(offer.specifications["Carrier"], "Unlocked")
        XCTAssertEqual(offer.status, .active)
        XCTAssertEqual(offer.viewCount, 150)
        XCTAssertEqual(offer.favoriteCount, 25)
        XCTAssertTrue(offer.isNegotiable)
        XCTAssertEqual(offer.shippingOptions.count, 1)
        XCTAssertEqual(offer.shippingOptions.first?.method, "Standard")
        XCTAssertEqual(offer.shippingOptions.first?.cost, 9.99)
        XCTAssertEqual(offer.tags, ["smartphone", "apple", "unlocked"])
    }
    
    func testOfferDecodingWithMinimalData() throws {
        let data = minimalOfferJSON.data(using: .utf8)!
        let offer = try JSONDecoder().decode(Offer.self, from: data)
        
        XCTAssertEqual(offer.id, "67890")
        XCTAssertEqual(offer.title, "Test Item")
        XCTAssertEqual(offer.currency, "USD") // Default value
        XCTAssertNil(offer.subcategory)
        XCTAssertNil(offer.sellerRating)
        XCTAssertTrue(offer.images.isEmpty)
        XCTAssertTrue(offer.specifications.isEmpty)
        XCTAssertNil(offer.expiryDate)
        XCTAssertEqual(offer.viewCount, 0) // Default value
        XCTAssertEqual(offer.favoriteCount, 0) // Default value
        XCTAssertFalse(offer.isNegotiable) // Default value
        XCTAssertTrue(offer.shippingOptions.isEmpty)
        XCTAssertTrue(offer.tags.isEmpty)
    }
    
    func testOfferDecodingWithStringImages() throws {
        let jsonWithStringImage = """
        {
            "ID": "test",
            "Title": "Test",
            "Description": "Test",
            "Price": 10.0,
            "Category": "Test",
            "Condition": "Good",
            "Location": "Test",
            "Seller_ID": "test",
            "Seller_Name": "Test",
            "Images": "single_image.jpg",
            "Created_Time": "2025-07-25T12:00:00.000Z",
            "Modified_Time": "2025-07-25T12:00:00.000Z",
            "Status": "Active"
        }
        """
        
        let data = jsonWithStringImage.data(using: .utf8)!
        let offer = try JSONDecoder().decode(Offer.self, from: data)
        
        XCTAssertEqual(offer.images, ["single_image.jpg"])
    }
    
    func testOfferDecodingWithStringTags() throws {
        let jsonWithStringTags = """
        {
            "ID": "test",
            "Title": "Test",
            "Description": "Test",
            "Price": 10.0,
            "Category": "Test",
            "Condition": "Good",
            "Location": "Test",
            "Seller_ID": "test",
            "Seller_Name": "Test",
            "Tags": "tag1, tag2, tag3",
            "Created_Time": "2025-07-25T12:00:00.000Z",
            "Modified_Time": "2025-07-25T12:00:00.000Z",
            "Status": "Active"
        }
        """
        
        let data = jsonWithStringTags.data(using: .utf8)!
        let offer = try JSONDecoder().decode(Offer.self, from: data)
        
        XCTAssertEqual(offer.tags, ["tag1", "tag2", "tag3"])
    }
    
    func testOfferDecodingWithStringSpecifications() throws {
        let jsonWithStringSpecs = """
        {
            "ID": "test",
            "Title": "Test",
            "Description": "Test",
            "Price": 10.0,
            "Category": "Test",
            "Condition": "Good",
            "Location": "Test",
            "Seller_ID": "test",
            "Seller_Name": "Test",
            "Specifications": "Color: Red; Size: Large; Material: Cotton",
            "Created_Time": "2025-07-25T12:00:00.000Z",
            "Modified_Time": "2025-07-25T12:00:00.000Z",
            "Status": "Active"
        }
        """
        
        let data = jsonWithStringSpecs.data(using: .utf8)!
        let offer = try JSONDecoder().decode(Offer.self, from: data)
        
        XCTAssertEqual(offer.specifications["Color"], "Red")
        XCTAssertEqual(offer.specifications["Size"], "Large")
        XCTAssertEqual(offer.specifications["Material"], "Cotton")
    }
    
    // MARK: - Offer Encoding Tests
    
    func testOfferEncoding() throws {
        let offer = createSampleOffer()
        let data = try JSONEncoder().encode(offer)
        let decodedOffer = try JSONDecoder().decode(Offer.self, from: data)
        
        XCTAssertEqual(offer.id, decodedOffer.id)
        XCTAssertEqual(offer.title, decodedOffer.title)
        XCTAssertEqual(offer.price, decodedOffer.price)
        XCTAssertEqual(offer.status, decodedOffer.status)
    }
    
    // MARK: - OfferStatus Tests
    
    func testOfferStatusDisplayName() {
        XCTAssertEqual(OfferStatus.active.displayName, "Active")
        XCTAssertEqual(OfferStatus.sold.displayName, "Sold")
        XCTAssertEqual(OfferStatus.expired.displayName, "Expired")
        XCTAssertEqual(OfferStatus.draft.displayName, "Draft")
        XCTAssertEqual(OfferStatus.suspended.displayName, "Suspended")
    }
    
    func testOfferStatusIsAvailable() {
        XCTAssertTrue(OfferStatus.active.isAvailable)
        XCTAssertFalse(OfferStatus.sold.isAvailable)
        XCTAssertFalse(OfferStatus.expired.isAvailable)
        XCTAssertFalse(OfferStatus.draft.isAvailable)
        XCTAssertFalse(OfferStatus.suspended.isAvailable)
    }
    
    // MARK: - OfferFilters Tests
    
    func testOfferFiltersInitialization() {
        let filters = OfferFilters()
        
        XCTAssertNil(filters.searchQuery)
        XCTAssertNil(filters.category)
        XCTAssertEqual(filters.sortBy, .createdDate)
        XCTAssertEqual(filters.sortOrder, .descending)
        XCTAssertEqual(filters.pageSize, 20)
        XCTAssertEqual(filters.pageNumber, 1)
    }
    
    func testOfferFiltersCustomInitialization() {
        let filters = OfferFilters(
            searchQuery: "iPhone",
            category: "Electronics",
            minPrice: 100.0,
            maxPrice: 1000.0,
            sortBy: .price,
            sortOrder: .ascending,
            pageSize: 10,
            pageNumber: 2
        )
        
        XCTAssertEqual(filters.searchQuery, "iPhone")
        XCTAssertEqual(filters.category, "Electronics")
        XCTAssertEqual(filters.minPrice, 100.0)
        XCTAssertEqual(filters.maxPrice, 1000.0)
        XCTAssertEqual(filters.sortBy, .price)
        XCTAssertEqual(filters.sortOrder, .ascending)
        XCTAssertEqual(filters.pageSize, 10)
        XCTAssertEqual(filters.pageNumber, 2)
    }
    
    func testOfferFiltersToQueryParameters() {
        let filters = OfferFilters(
            searchQuery: "iPhone",
            category: "Electronics",
            minPrice: 100.0,
            maxPrice: 1000.0,
            condition: "New",
            location: "New York",
            isNegotiable: true,
            hasImages: true,
            sortBy: .price,
            sortOrder: .ascending,
            pageSize: 10,
            pageNumber: 2
        )
        
        let params = filters.toQueryParameters()
        
        XCTAssertEqual(params["search"], "iPhone")
        XCTAssertEqual(params["Category"], "Electronics")
        XCTAssertEqual(params["Price_min"], "100.0")
        XCTAssertEqual(params["Price_max"], "1000.0")
        XCTAssertEqual(params["Condition"], "New")
        XCTAssertEqual(params["Location"], "New York")
        XCTAssertEqual(params["Is_Negotiable"], "true")
        XCTAssertEqual(params["Images_exists"], "true")
        XCTAssertEqual(params["sort_by"], "Price")
        XCTAssertEqual(params["sort_order"], "asc")
        XCTAssertEqual(params["per_page"], "10")
        XCTAssertEqual(params["page"], "2")
    }
    
    func testOfferFiltersToQueryParametersWithNilValues() {
        let filters = OfferFilters()
        let params = filters.toQueryParameters()
        
        XCTAssertNil(params["search"])
        XCTAssertNil(params["Category"])
        XCTAssertNil(params["Price_min"])
        XCTAssertEqual(params["sort_by"], "Created_Time")
        XCTAssertEqual(params["sort_order"], "desc")
        XCTAssertEqual(params["per_page"], "20")
        XCTAssertEqual(params["page"], "1")
    }
    
    // MARK: - ZohoAPIResponse Tests
    
    func testZohoAPIResponseDecoding() throws {
        let responseJSON = """
        {
            "data": [
                {
                    "ID": "1",
                    "Title": "Test Item 1",
                    "Description": "Test",
                    "Price": 10.0,
                    "Category": "Test",
                    "Condition": "Good",
                    "Location": "Test",
                    "Seller_ID": "test",
                    "Seller_Name": "Test",
                    "Created_Time": "2025-07-25T12:00:00.000Z",
                    "Modified_Time": "2025-07-25T12:00:00.000Z",
                    "Status": "Active"
                }
            ],
            "info": {
                "count": 1,
                "page": 1,
                "per_page": 20,
                "total_count": 1,
                "more_records": false
            }
        }
        """
        
        let data = responseJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(ZohoAPIResponse<Offer>.self, from: data)
        
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data.first?.id, "1")
        XCTAssertEqual(response.info.count, 1)
        XCTAssertEqual(response.info.page, 1)
        XCTAssertEqual(response.info.perPage, 20)
        XCTAssertEqual(response.info.totalCount, 1)
        XCTAssertFalse(response.info.hasMore)
    }
    
    // MARK: - DateParser Tests
    
    func testDateParserISO8601Format() {
        let dateString = "2025-07-25T10:30:00.000Z"
        let date = DateParser.parseDate(from: dateString)
        
        XCTAssertNotNil(date)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = formatter.date(from: dateString)
        
        XCTAssertEqual(date, expectedDate)
    }
    
    func testDateParserFallbackFormat() {
        let dateString = "2025-07-25T10:30:00.000+0000"
        let date = DateParser.parseDate(from: dateString)
        
        XCTAssertNotNil(date)
    }
    
    func testDateParserSimpleFormat() {
        let dateString = "2025-07-25"
        let date = DateParser.parseDate(from: dateString)
        
        XCTAssertNotNil(date)
    }
    
    func testDateParserInvalidFormat() {
        let dateString = "invalid-date"
        let date = DateParser.parseDate(from: dateString)
        
        XCTAssertNil(date)
    }
    
    func testDateParserFormatDate() {
        let date = Date()
        let formattedString = DateParser.formatDate(date)
        let parsedDate = DateParser.parseDate(from: formattedString)
        
        XCTAssertNotNil(parsedDate)
        // Allow for small time differences due to precision
        XCTAssertEqual(date.timeIntervalSince1970, parsedDate!.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - SortOption Tests
    
    func testSortOptionDisplayNames() {
        XCTAssertEqual(SortOption.createdDate.displayName, "Date Created")
        XCTAssertEqual(SortOption.updatedDate.displayName, "Date Updated")
        XCTAssertEqual(SortOption.price.displayName, "Price")
        XCTAssertEqual(SortOption.title.displayName, "Title")
        XCTAssertEqual(SortOption.viewCount.displayName, "Views")
        XCTAssertEqual(SortOption.favoriteCount.displayName, "Favorites")
    }
    
    func testSortOrderDisplayNames() {
        XCTAssertEqual(SortOrder.ascending.displayName, "Ascending")
        XCTAssertEqual(SortOrder.descending.displayName, "Descending")
    }
    
    // MARK: - ShippingOption Tests
    
    func testShippingOptionDecoding() throws {
        let shippingJSON = """
        {
            "Method": "Express",
            "Cost": 15.99,
            "Estimated_Days": 2,
            "Description": "Express shipping"
        }
        """
        
        let data = shippingJSON.data(using: .utf8)!
        let shipping = try JSONDecoder().decode(ShippingOption.self, from: data)
        
        XCTAssertEqual(shipping.method, "Express")
        XCTAssertEqual(shipping.cost, 15.99)
        XCTAssertEqual(shipping.estimatedDays, 2)
        XCTAssertEqual(shipping.description, "Express shipping")
    }
    
    // MARK: - Helper Methods
    
    private func createSampleOffer() -> Offer {
        let data = sampleOfferJSON.data(using: .utf8)!
        return try! JSONDecoder().decode(Offer.self, from: data)
    }
}

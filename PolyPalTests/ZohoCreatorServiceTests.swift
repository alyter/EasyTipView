//
//  ZohoCreatorServiceTests.swift
//  PolyPalTests
//
//  Created by Agent on 7/25/25.
//

import XCTest
import Combine
@testable import PolyPal

class ZohoCreatorServiceTests: XCTestCase {
    
    var service: ZohoCreatorService!
    var mockConfiguration: ZohoConfiguration!
    var mockSession: MockURLSession!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockConfiguration = ZohoConfiguration.shared
        mockSession = MockURLSession()
        service = ZohoCreatorService(configuration: mockConfiguration, session: mockSession)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        service = nil
        mockConfiguration = nil
        mockSession = nil
        cancellables = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Authentication Tests
    
    func testAuthenticate_Success() throws {
        let expectation = XCTestExpectation(description: "Authentication should succeed")
        
        service.authenticate(clientId: "test_client", clientSecret: "test_secret", redirectUri: "test://redirect")
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Authentication should not fail")
                    }
                },
                receiveValue: { token in
                    XCTAssertTrue(token.contains("mock_access_token"))
                    XCTAssertTrue(self.service.isAuthenticated)
                    XCTAssertNotNil(self.service.authToken)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testRefreshToken_Success() throws {
        let expectation = XCTestExpectation(description: "Token refresh should succeed")
        
        // First authenticate
        service.isAuthenticated = true
        service.authToken = "initial_token"
        
        service.refreshToken()
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Token refresh should not fail")
                    }
                },
                receiveValue: { token in
                    XCTAssertTrue(token.contains("refreshed_token"))
                    XCTAssertEqual(self.service.authToken, token)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Data Operations Tests
    
    func testFetchRecords_NotAuthenticated() throws {
        let expectation = XCTestExpectation(description: "Should fail when not authenticated")
        
        service.fetchRecords(from: "test_form")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is ZohoCreatorError)
                        if case ZohoCreatorError.notAuthenticated = error {
                            expectation.fulfill()
                        } else {
                            XCTFail("Expected notAuthenticated error")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value when not authenticated")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchRecords_Success() throws {
        let expectation = XCTestExpectation(description: "Should fetch records successfully")
        
        // Setup authentication
        service.isAuthenticated = true
        service.authToken = "test_token"
        
        // Setup mock response
        let mockRecord = ZohoRecord(
            id: "123",
            data: ["field1": AnyCodable("value1")],
            createdTime: "2025-07-25T14:00:00Z",
            modifiedTime: "2025-07-25T14:00:00Z"
        )
        let mockResponse = ZohoRecordsResponse(
            data: [mockRecord],
            result: ZohoResult(message: "Success", status: "success")
        )
        
        let responseData = try JSONEncoder().encode(mockResponse)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://creator.zoho.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        service.fetchRecords(from: "test_form")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail: \(error)")
                    }
                },
                receiveValue: { records in
                    XCTAssertEqual(records.count, 1)
                    XCTAssertEqual(records.first?.id, "123")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCreateRecord_Success() throws {
        let expectation = XCTestExpectation(description: "Should create record successfully")
        
        // Setup authentication
        service.isAuthenticated = true
        service.authToken = "test_token"
        
        // Setup mock response
        let mockRecord = ZohoRecord(
            id: "456",
            data: ["field1": AnyCodable("new_value")],
            createdTime: "2025-07-25T14:00:00Z",
            modifiedTime: "2025-07-25T14:00:00Z"
        )
        let mockResponse = ZohoCreateResponse(
            data: mockRecord,
            result: ZohoResult(message: "Record created", status: "success")
        )
        
        let responseData = try JSONEncoder().encode(mockResponse)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://creator.zoho.com")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )
        
        let testData = ["field1": "new_value", "field2": 42] as [String: Any]
        
        service.createRecord(in: "test_form", data: testData)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail: \(error)")
                    }
                },
                receiveValue: { record in
                    XCTAssertEqual(record.id, "456")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateRecord_Success() throws {
        let expectation = XCTestExpectation(description: "Should update record successfully")
        
        // Setup authentication
        service.isAuthenticated = true
        service.authToken = "test_token"
        
        // Setup mock response
        let mockRecord = ZohoRecord(
            id: "789",
            data: ["field1": AnyCodable("updated_value")],
            createdTime: "2025-07-25T14:00:00Z",
            modifiedTime: "2025-07-25T15:00:00Z"
        )
        let mockResponse = ZohoUpdateResponse(
            data: mockRecord,
            result: ZohoResult(message: "Record updated", status: "success")
        )
        
        let responseData = try JSONEncoder().encode(mockResponse)
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://creator.zoho.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let testData = ["field1": "updated_value"] as [String: Any]
        
        service.updateRecord(in: "test_form", recordId: "789", data: testData)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail: \(error)")
                    }
                },
                receiveValue: { record in
                    XCTAssertEqual(record.id, "789")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteRecord_Success() throws {
        let expectation = XCTestExpectation(description: "Should delete record successfully")
        
        // Setup authentication
        service.isAuthenticated = true
        service.authToken = "test_token"
        
        // Setup mock response
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://creator.zoho.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        service.deleteRecord(from: "test_form", recordId: "999")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail: \(error)")
                    }
                },
                receiveValue: { success in
                    XCTAssertTrue(success)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testZohoCreatorError_LocalizedDescription() {
        XCTAssertEqual(
            ZohoCreatorError.notAuthenticated.localizedDescription,
            "Not authenticated with Zoho Creator"
        )
        XCTAssertEqual(
            ZohoCreatorError.invalidURL.localizedDescription,
            "Invalid URL for Zoho Creator API"
        )
        XCTAssertEqual(
            ZohoCreatorError.invalidResponse.localizedDescription,
            "Invalid response from Zoho Creator API"
        )
        
        let networkError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        XCTAssertEqual(
            ZohoCreatorError.networkError(networkError).localizedDescription,
            "Network error: Test error"
        )
        
        XCTAssertEqual(
            ZohoCreatorError.apiError("API failed").localizedDescription,
            "Zoho Creator API error: API failed"
        )
    }
    
    // MARK: - AnyCodable Tests
    
    func testAnyCodable_Encoding() throws {
        let intValue = AnyCodable(42)
        let stringValue = AnyCodable("test")
        let boolValue = AnyCodable(true)
        let doubleValue = AnyCodable(3.14)
        
        let encoder = JSONEncoder()
        
        XCTAssertNoThrow(try encoder.encode(intValue))
        XCTAssertNoThrow(try encoder.encode(stringValue))
        XCTAssertNoThrow(try encoder.encode(boolValue))
        XCTAssertNoThrow(try encoder.encode(doubleValue))
    }
    
    func testAnyCodable_Decoding() throws {
        let decoder = JSONDecoder()
        
        let intData = "42".data(using: .utf8)!
        let intValue = try decoder.decode(AnyCodable.self, from: intData)
        XCTAssertEqual(intValue.value as? Int, 42)
        
        let stringData = "\"test\"".data(using: .utf8)!
        let stringValue = try decoder.decode(AnyCodable.self, from: stringData)
        XCTAssertEqual(stringValue.value as? String, "test")
        
        let boolData = "true".data(using: .utf8)!
        let boolValue = try decoder.decode(AnyCodable.self, from: boolData)
        XCTAssertEqual(boolValue.value as? Bool, true)
        
        let doubleData = "3.14".data(using: .utf8)!
        let doubleValue = try decoder.decode(AnyCodable.self, from: doubleData)
        XCTAssertEqual(doubleValue.value as? Double, 3.14)
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    override func dataTaskPublisher(for request: URLRequest) -> URLSession.DataTaskPublisher {
        let mockPublisher = MockDataTaskPublisher(
            data: data,
            response: response,
            error: error
        )
        return mockPublisher.eraseToAnyPublisher() as! URLSession.DataTaskPublisher
    }
}

struct MockDataTaskPublisher: Publisher {
    typealias Output = URLSession.DataTaskPublisher.Output
    typealias Failure = URLSession.DataTaskPublisher.Failure
    
    let data: Data?
    let response: URLResponse?
    let error: Error?
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = MockSubscription(
            subscriber: subscriber,
            data: data,
            response: response,
            error: error
        )
        subscriber.receive(subscription: subscription)
    }
}

class MockSubscription<S: Subscriber>: Subscription where S.Input == URLSession.DataTaskPublisher.Output, S.Failure == URLSession.DataTaskPublisher.Failure {
    
    private var subscriber: S?
    private let data: Data?
    private let response: URLResponse?
    private let error: Error?
    
    init(subscriber: S, data: Data?, response: URLResponse?, error: Error?) {
        self.subscriber = subscriber
        self.data = data
        self.response = response
        self.error = error
    }
    
    func request(_ demand: Subscribers.Demand) {
        guard let subscriber = subscriber else { return }
        
        if let error = error {
            subscriber.receive(completion: .failure(error as! URLError))
        } else {
            let output = (data: data ?? Data(), response: response ?? URLResponse())
            _ = subscriber.receive(output)
            subscriber.receive(completion: .finished)
        }
    }
    
    func cancel() {
        subscriber = nil
    }
}

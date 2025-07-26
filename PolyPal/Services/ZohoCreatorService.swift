//
//  ZohoCreatorService.swift
//  PolyPal
//
//  Created by Agent on 7/25/25.
//

import Foundation
import ZohoPortalAuth
import ZCUIFramework
import Combine

/// Service for interacting with Zoho Creator APIs
class ZohoCreatorService: ObservableObject {
    
    // MARK: - Properties
    
    private let configuration: ZohoConfiguration
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    private let certificatePinningManager: CertificatePinningManager
    
    @Published var isAuthenticated = false
    @Published var authToken: String?
    
    /// Public access to the URLSession for testing purposes
    var urlSession: URLSession {
        return session
    }
    
    // Rate limiting properties
    private let maxRetries: Int = 3
    private let baseDelay: TimeInterval = 1.0
    private let maxDelay: TimeInterval = 60.0
    private var requestQueue = DispatchQueue(label: "zoho.api.requests", qos: .utility)
    private var lastRequestTime: Date = Date.distantPast
    private let minimumRequestInterval: TimeInterval = 0.1 // 100ms between requests
    
    // MARK: - Initialization
    
    init(configuration: ZohoConfiguration = ZohoConfiguration.shared, 
         session: URLSession? = nil,
         enableCertificatePinning: Bool = true) {
        self.configuration = configuration
        self.certificatePinningManager = CertificatePinningManager(enablePinning: enableCertificatePinning)
        
        if let session = session {
            self.session = session
        } else {
            // Create custom URLSession with certificate pinning
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.timeoutIntervalForRequest = 30.0
            sessionConfiguration.timeoutIntervalForResource = 60.0
            
            self.session = URLSession(
                configuration: sessionConfiguration,
                delegate: self.certificatePinningManager,
                delegateQueue: nil
            )
        }
    }
    
    // MARK: - Rate Limiting and Retry Logic
    
    /// Executes a network request with rate limiting and exponential backoff retry
    private func executeWithRetry<T>(_ operation: @escaping () -> AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        return operation()
            .catch { error -> AnyPublisher<T, Error> in
                if self.shouldRetry(error: error) {
                    return self.retryWithExponentialBackoff(operation, attempt: 1)
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Retries an operation with exponential backoff
    private func retryWithExponentialBackoff<T>(_ operation: @escaping () -> AnyPublisher<T, Error>, attempt: Int) -> AnyPublisher<T, Error> {
        guard attempt <= maxRetries else {
            return Fail(error: ZohoCreatorError.maxRetriesExceeded).eraseToAnyPublisher()
        }
        
        let delay = min(baseDelay * pow(2.0, Double(attempt - 1)), maxDelay)
        
        return Future<T, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                operation()
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                if self.shouldRetry(error: error) && attempt < self.maxRetries {
                                    self.retryWithExponentialBackoff(operation, attempt: attempt + 1)
                                        .sink(
                                            receiveCompletion: { promise(.failure($0.error ?? error)) },
                                            receiveValue: { promise(.success($0)) }
                                        )
                                        .store(in: &self.cancellables)
                                } else {
                                    promise(.failure(error))
                                }
                            }
                        },
                        receiveValue: { value in
                            promise(.success(value))
                        }
                    )
                    .store(in: &self.cancellables)
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Determines if an error should trigger a retry
    private func shouldRetry(error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        if let httpResponse = (error as NSError).userInfo["response"] as? HTTPURLResponse {
            // Retry on server errors (5xx) and rate limiting (429)
            return httpResponse.statusCode >= 500 || httpResponse.statusCode == 429
        }
        
        return false
    }
    
    /// Enforces rate limiting between requests
    private func enforceRateLimit() -> AnyPublisher<Void, Never> {
        return Future<Void, Never> { promise in
            self.requestQueue.async {
                let now = Date()
                let timeSinceLastRequest = now.timeIntervalSince(self.lastRequestTime)
                
                if timeSinceLastRequest < self.minimumRequestInterval {
                    let delay = self.minimumRequestInterval - timeSinceLastRequest
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.lastRequestTime = Date()
                        promise(.success(()))
                    }
                } else {
                    self.lastRequestTime = now
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Authentication
    
    /// Authenticate with Zoho Creator using OAuth 2.0
    func authenticate(clientId: String, clientSecret: String, redirectUri: String) -> AnyPublisher<String, Error> {
        // Implementation for OAuth 2.0 authentication flow
        // This would typically involve:
        // 1. Redirecting to Zoho's authorization URL
        // 2. Handling the callback with authorization code
        // 3. Exchanging code for access token
        
        return Future<String, Error> { promise in
            // For now, return a mock token
            // In real implementation, this would handle the OAuth flow
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let mockToken = "mock_access_token_\(Date().timeIntervalSince1970)"
                self.authToken = mockToken
                self.isAuthenticated = true
                promise(.success(mockToken))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Refresh the authentication token
    func refreshToken() -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // Mock implementation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let refreshedToken = "refreshed_token_\(Date().timeIntervalSince1970)"
                self.authToken = refreshedToken
                promise(.success(refreshedToken))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Data Operations
    
    /// Fetch records from a Zoho Creator form
    func fetchRecords(from formName: String, criteria: String? = nil) -> AnyPublisher<[ZohoRecord], Error> {
        guard isAuthenticated, let token = authToken else {
            return Fail(error: ZohoCreatorError.notAuthenticated)
                .eraseToAnyPublisher()
        }
        
        return enforceRateLimit()
            .flatMap { _ in
                self.executeWithRetry {
                    self.performFetchRecords(formName: formName, criteria: criteria, token: token)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Internal method to perform the actual fetch records request
    private func performFetchRecords(formName: String, criteria: String?, token: String) -> AnyPublisher<[ZohoRecord], Error> {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        let configData = try! configuration.loadConfiguration()
        urlComponents.host = configData.creatorDomain
        urlComponents.path = "/api/v2/\(configData.appOwnerName)/\(configData.appLinkName)/report/\(formName)"
        
        if let criteria = criteria {
            urlComponents.queryItems = [URLQueryItem(name: "criteria", value: criteria)]
        }
        
        guard let url = urlComponents.url else {
            return Fail(error: ZohoCreatorError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.setValue("Zoho-oauthtoken \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ZohoRecordsResponse.self, decoder: JSONDecoder())
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Create a new record in Zoho Creator
    func createRecord(in formName: String, data: [String: Any]) -> AnyPublisher<ZohoRecord, Error> {
        guard isAuthenticated, let token = authToken else {
            return Fail(error: ZohoCreatorError.notAuthenticated)
                .eraseToAnyPublisher()
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        let configData = try! configuration.loadConfiguration()
        urlComponents.host = configData.creatorDomain
        urlComponents.path = "/api/v2/\(configData.appOwnerName)/\(configData.appLinkName)/form/\(formName)"
        
        guard let url = urlComponents.url else {
            return Fail(error: ZohoCreatorError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Zoho-oauthtoken \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let requestData = ZohoCreateRequest(data: data)
            request.httpBody = try JSONEncoder().encode(requestData)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ZohoCreateResponse.self, decoder: JSONDecoder())
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Update an existing record in Zoho Creator
    func updateRecord(in formName: String, recordId: String, data: [String: Any]) -> AnyPublisher<ZohoRecord, Error> {
        guard isAuthenticated, let token = authToken else {
            return Fail(error: ZohoCreatorError.notAuthenticated)
                .eraseToAnyPublisher()
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        let configData = try! configuration.loadConfiguration()
        urlComponents.host = configData.creatorDomain
        urlComponents.path = "/api/v2/\(configData.appOwnerName)/\(configData.appLinkName)/report/\(formName)/\(recordId)"
        
        guard let url = urlComponents.url else {
            return Fail(error: ZohoCreatorError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Zoho-oauthtoken \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let requestData = ZohoUpdateRequest(data: data)
            request.httpBody = try JSONEncoder().encode(requestData)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ZohoUpdateResponse.self, decoder: JSONDecoder())
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Delete a record from Zoho Creator
    func deleteRecord(from formName: String, recordId: String) -> AnyPublisher<Bool, Error> {
        guard isAuthenticated, let token = authToken else {
            return Fail(error: ZohoCreatorError.notAuthenticated)
                .eraseToAnyPublisher()
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        let configData = try! configuration.loadConfiguration()
        urlComponents.host = configData.creatorDomain
        urlComponents.path = "/api/v2/\(configData.appOwnerName)/\(configData.appLinkName)/report/\(formName)/\(recordId)"
        
        guard let url = urlComponents.url else {
            return Fail(error: ZohoCreatorError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Zoho-oauthtoken \(token)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .map { response in
                return (response.response as? HTTPURLResponse)?.statusCode == 200
            }
            .mapError { $0 as Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Data Models

/// Represents a record in Zoho Creator
struct ZohoRecord: Codable, Identifiable {
    let id: String
    let data: [String: AnyCodable]
    let createdTime: String?
    let modifiedTime: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case data
        case createdTime = "Added_Time"
        case modifiedTime = "Modified_Time"
    }
}

/// Response structure for fetching records
struct ZohoRecordsResponse: Codable {
    let data: [ZohoRecord]
    let result: ZohoResult
}

/// Response structure for creating records
struct ZohoCreateResponse: Codable {
    let data: ZohoRecord
    let result: ZohoResult
}

/// Response structure for updating records
struct ZohoUpdateResponse: Codable {
    let data: ZohoRecord
    let result: ZohoResult
}

/// Request structure for creating records
struct ZohoCreateRequest: Codable {
    let data: [String: AnyCodable]
    
    init(data: [String: Any]) {
        self.data = data.mapValues { AnyCodable($0) }
    }
}

/// Request structure for updating records
struct ZohoUpdateRequest: Codable {
    let data: [String: AnyCodable]
    
    init(data: [String: Any]) {
        self.data = data.mapValues { AnyCodable($0) }
    }
}

/// Result information from Zoho API responses
struct ZohoResult: Codable {
    let message: String
    let status: String
}

/// Type-erased wrapper for Any values in Codable contexts
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }
}

// MARK: - Error Types

enum ZohoCreatorError: Error, LocalizedError {
    case notAuthenticated
    case configurationError
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    case maxRetriesExceeded
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Zoho Creator"
        case .configurationError:
            return "Failed to load Zoho Creator configuration"
        case .invalidURL:
            return "Invalid URL for Zoho Creator API"
        case .invalidResponse:
            return "Invalid response from Zoho Creator API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "Zoho Creator API error: \(message)"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}

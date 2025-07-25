# API Specification

This is the API specification for the spec detailed in @.agent-os/specs/2025-07-25-zoho-creator-integration/spec.md

> Created: 2025-07-25
> Version: 1.0.0

## Zoho Creator API Integration

### Authentication Endpoints

#### POST /oauth/v2/token
**Purpose:** Obtain access token using OAuth 2.0 authorization code flow
**Parameters:** 
- `grant_type`: "authorization_code"
- `client_id`: Application client ID
- `client_secret`: Application client secret
- `redirect_uri`: Configured redirect URI
- `code`: Authorization code from user consent

**Response:**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600,
  "token_type": "Bearer",
  "scope": "ZohoCreator.report.READ"
}
```

**Errors:** 
- 400: Invalid request parameters
- 401: Invalid client credentials
- 403: Access denied

#### POST /oauth/v2/token (Refresh)
**Purpose:** Refresh expired access token
**Parameters:**
- `grant_type`: "refresh_token"
- `refresh_token`: Valid refresh token
- `client_id`: Application client ID
- `client_secret`: Application client secret

**Response:** Same as above
**Errors:** Same as above

### Data Retrieval Endpoints

#### GET /creator/v2/applications/{app_name}/reports/{report_name}/records
**Purpose:** Fetch offer records from Zoho Creator
**Parameters:**
- `from`: Starting record index (default: 1)
- `limit`: Number of records to fetch (max: 200, default: 20)
- `criteria`: Filter criteria in Zoho Creator format
- `sort_column`: Column name for sorting
- `sort_order`: "asc" or "desc"

**Headers:**
- `Authorization`: "Zoho-oauthtoken {access_token}"

**Response:**
```json
{
  "data": [
    {
      "ID": "12345",
      "Title": "High-Grade PVC Pellets",
      "Description": "Premium quality PVC pellets for injection molding",
      "Material_Type": "PVC",
      "Quantity": 1000,
      "Unit": "kg",
      "Price_Per_Unit": 2.50,
      "Currency": "USD",
      "Vendor_ID": "VENDOR123",
      "Vendor_Name": "PlasticCorp Inc",
      "Location": "Houston, TX",
      "Image_URLs": ["https://example.com/image1.jpg"],
      "Specifications": {
        "Grade": "Medical Grade",
        "Color": "Natural",
        "Melt_Index": "12 g/10min"
      },
      "Created_Time": "2025-07-25T10:30:00Z",
      "Modified_Time": "2025-07-25T10:30:00Z",
      "Expiry_Date": "2025-08-25T23:59:59Z",
      "Is_Active": true
    }
  ],
  "info": {
    "count": 1,
    "more_records": true,
    "next_page_token": "eyJwYWdlIjoyLCJsaW1pdCI6MjB9"
  }
}
```

**Errors:**
- 401: Invalid or expired token
- 403: Insufficient permissions
- 404: Application or report not found
- 429: Rate limit exceeded
- 500: Internal server error

#### GET /creator/v2/applications/{app_name}/reports/{report_name}/records/{record_id}
**Purpose:** Fetch specific offer record by ID
**Parameters:**
- `record_id`: Unique record identifier

**Headers:**
- `Authorization`: "Zoho-oauthtoken {access_token}"

**Response:**
```json
{
  "data": {
    "ID": "12345",
    "Title": "High-Grade PVC Pellets",
    // ... same structure as above
  }
}
```

**Errors:** Same as above plus:
- 404: Record not found

### Mobile App Service Layer

#### ZohoCreatorService Methods

```swift
class ZohoCreatorService {
    func authenticate() async throws -> AuthToken
    func refreshToken() async throws -> AuthToken
    func fetchOffers(page: Int, limit: Int, filters: OfferFilters?) async throws -> OfferResponse
    func fetchOffer(id: String) async throws -> Offer
    func searchOffers(query: String, filters: OfferFilters?) async throws -> OfferResponse
}
```

#### Error Handling

```swift
enum ZohoAPIError: Error {
    case authenticationFailed
    case tokenExpired
    case rateLimitExceeded
    case networkError(Error)
    case invalidResponse
    case recordNotFound
    case insufficientPermissions
}
```

## Rate Limiting Strategy

### Zoho Creator API Limits
- **Requests per minute:** 200 per user
- **Daily requests:** 15,000 per user
- **Concurrent connections:** 10 per user

### Mobile App Implementation
- **Request queuing:** Implement request queue to respect rate limits
- **Exponential backoff:** Wait 1s, 2s, 4s, 8s on rate limit errors
- **Caching:** Reduce API calls through intelligent caching
- **Batch requests:** Combine multiple record requests when possible

## Data Synchronization Strategy

### Initial Load
1. Fetch first page of offers (20 records)
2. Cache results locally
3. Load additional pages on demand

### Incremental Updates
1. Check for updates every 15 minutes when app is active
2. Use `Modified_Time` field to identify changed records
3. Update local cache with new/modified records
4. Remove expired or inactive offers

### Offline Handling
1. Serve cached data when network unavailable
2. Queue failed requests for retry when connection restored
3. Show offline indicator in UI
4. Sync queued requests on network restoration

## Security Considerations

### Token Management
- Store tokens in iOS Keychain with highest security level
- Implement automatic token refresh 5 minutes before expiration
- Clear tokens on app uninstall or user logout

### API Security
- Use certificate pinning for Zoho API endpoints
- Validate all API responses before processing
- Sanitize user input in search queries
- Log security events for monitoring

### Data Protection
- Encrypt cached offer data using iOS Data Protection
- Implement secure data deletion on cache cleanup
- Use secure random generation for request IDs
- Validate data integrity on cache retrieval

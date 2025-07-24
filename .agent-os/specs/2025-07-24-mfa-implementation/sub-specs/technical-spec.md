# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-24-mfa-implementation/spec.md

> Created: 2025-07-24
> Version: 1.0.0

## Technical Requirements

### TOTP Implementation
- Implement RFC 6238 Time-based One-Time Password algorithm
- Use HMAC-SHA1 with 30-second time windows
- Generate 6-digit codes with proper zero-padding
- Support clock drift tolerance (±1 time window)
- Secure secret key generation using iOS CryptoKit

### QR Code Generation
- Generate otpauth:// URLs compatible with Google Authenticator, Authy, etc.
- Include issuer name "PolyPal" and user email in QR code
- Use Core Image framework for QR code rendering
- Ensure QR codes are high-resolution and scannable

### Backup Code System
- Generate 10 unique 8-character alphanumeric backup codes
- Store codes securely using iOS Keychain Services
- Mark codes as used after single consumption
- Provide regeneration capability with user confirmation

### Security Requirements
- Store TOTP secrets in iOS Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
- Implement rate limiting for MFA verification attempts (max 5 attempts per 5 minutes)
- Clear sensitive data from memory after use
- Use secure random number generation for all cryptographic operations

### Integration Points
- Extend existing AuthenticationViewModel with MFA methods
- Add MFA status to UserProfile model
- Integrate with AccountSettingsView for MFA management
- Update login flow to check MFA requirement after password validation

## Approach Options

**Option A:** Third-party TOTP Library
- Pros: Faster implementation, battle-tested code, comprehensive features
- Cons: External dependency, potential security audit requirements, larger app size

**Option B:** Custom TOTP Implementation (Selected)
- Pros: Full control over implementation, no external dependencies, smaller footprint
- Cons: More development time, requires thorough testing, potential for implementation bugs

**Rationale:** Given the security-critical nature of MFA and the relatively straightforward TOTP algorithm, implementing a custom solution provides better control and reduces external dependencies while maintaining security standards.

## External Dependencies

**No new external dependencies required** - Implementation will use iOS native frameworks:

- **CryptoKit** - For HMAC-SHA1 and secure random generation
- **Core Image** - For QR code generation and rendering
- **Security Framework** - For Keychain storage of secrets and backup codes
- **Foundation** - For Base32 encoding/decoding and time calculations

**Justification:** Using native iOS frameworks ensures optimal performance, security, and compatibility while avoiding third-party dependency management and potential security vulnerabilities.

## Data Models

### MFAConfiguration
```swift
struct MFAConfiguration: Codable {
    let isEnabled: Bool
    let secretKey: String // Base32 encoded
    let backupCodes: [String]
    let usedBackupCodes: Set<String>
    let setupDate: Date
    let lastUsedDate: Date?
}
```

### MFASetupData
```swift
struct MFASetupData {
    let secretKey: Data
    let qrCodeURL: String
    let backupCodes: [String]
    let qrCodeImage: UIImage
}
```

## Implementation Architecture

### MFAManager
Central service class responsible for:
- TOTP generation and validation
- QR code creation
- Backup code management
- Keychain integration
- Rate limiting enforcement

### MFASetupView
SwiftUI view for MFA setup wizard:
- Display QR code for scanning
- Verification code input
- Backup codes display and download
- Setup completion confirmation

### MFAVerificationView
Enhanced existing MFAView with:
- TOTP code input with real-time validation
- Backup code option toggle
- Rate limiting feedback
- Biometric authentication integration

## Security Considerations

### Threat Mitigation
- **Brute Force Attacks:** Rate limiting with exponential backoff
- **Secret Extraction:** Keychain storage with device-only access
- **Replay Attacks:** Time window validation prevents code reuse
- **Social Engineering:** Clear user education about backup codes

### Compliance
- Follows NIST SP 800-63B guidelines for multi-factor authentication
- Implements TOTP according to RFC 6238 specifications
- Uses cryptographically secure random number generation
- Provides secure backup recovery mechanism

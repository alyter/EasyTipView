# Technical Stack

> Last Updated: 2025-07-22
> Version: 1.0.0

## Core Technologies

### Mobile Application Framework
- **Framework:** Swift (iOS)
- **Version:** Swift 6.0+
- **Platform:** iOS 15.0+
- **IDE:** Xcode 15+

### Backend Framework
- **Framework:** Node.js
- **Version:** Node.js 22 LTS
- **Runtime:** Express.js or Fastify
- **Package Manager:** npm

### Database
- **Primary:** PostgreSQL
- **Version:** 17+
- **ORM:** Prisma or TypeORM
- **Connection Pooling:** pg-pool

## Integration & APIs

### Zoho Integration
- **SDK:** Zoho Mobile SDK for iOS
- **Version:** Latest stable
- **APIs:** Zoho Creator API v2
- **Authentication:** OAuth 2.0

### External Services
- **Push Notifications:** Apple Push Notification Service (APNs)
- **Authentication:** JWT with MFA support
- **File Storage:** AWS S3 or similar for offer images

## Frontend & UI

### Mobile UI Framework
- **Native:** SwiftUI
- **UI Components:** Custom components following iOS design guidelines
- **Navigation:** UIKit Navigation Controller
- **State Management:** Combine framework

### Web Components (Admin Panel)
- **CSS Framework:** TailwindCSS 4.0+
- **JavaScript:** Vanilla JS or lightweight framework
- **Build Tool:** Vite

## Infrastructure

### Application Hosting
- **Platform:** AWS or Digital Ocean
- **Service:** EC2 instances or App Platform
- **Load Balancing:** Application Load Balancer
- **Region:** US-East (primary)

### Database Hosting
- **Provider:** AWS RDS or Digital Ocean Managed PostgreSQL
- **Service:** Managed PostgreSQL
- **Backups:** Daily automated snapshots
- **Monitoring:** CloudWatch or built-in monitoring

### Asset Storage
- **Provider:** Zoho

## Development & Deployment

### Code Repository
- **Platform:** GitHub
- **Repository:** Private repository
- **Branching Strategy:** GitFlow (main, develop, feature branches)

### CI/CD Pipeline
- **Platform:** GitHub Actions
- **iOS Build:** Xcode Cloud or GitHub Actions with macOS runners
- **Backend Deploy:** Automated deployment on merge to main
- **Testing:** Automated test suite execution

### Development Tools
- **iOS Simulator:** For iOS development and testing
- **API Testing:** Postman or Insomnia
- **Database Client:** TablePlus or pgAdmin
- **Version Control:** Git with conventional commits

## Security & Monitoring

### Authentication & Authorization
- **Mobile Auth:** Biometric authentication (Face ID/Touch ID)
- **MFA:** Time-based OTP (TOTP)
- **Session Management:** JWT with refresh tokens
- **API Security:** Rate limiting and request validation

### Monitoring & Analytics
- **Application Monitoring:** Sentry or similar
- **Performance:** New Relic or Datadog
- **Crash Reporting:** Firebase Crashlytics or Bugsnag
- **Usage Analytics:** Firebase Analytics or Mixpanel

### Data Protection
- **Encryption:** AES-256 for sensitive data at rest
- **Transport:** TLS 1.3 for all API communications
- **Compliance:** GDPR and industry-standard data protection
- **Backup Strategy:** Encrypted backups with 30-day retention

## Development Environment

### Local Development
- **iOS Development:** Xcode with iOS Simulator
- **Backend:** Docker containers for consistent environment
- **Database:** Local PostgreSQL instance or Docker container
- **API Gateway:** Local proxy for Zoho API integration

### Testing Strategy
- **Unit Tests:** XCTest for iOS, Jest for Node.js
- **Integration Tests:** API endpoint testing
- **UI Tests:** XCUITest for iOS automation
- **Performance Tests:** XCTMetric for iOS performance monitoring

## Third-Party Dependencies

### iOS Dependencies (CocoaPods/Swift Package Manager)
- **Zoho Mobile SDK** - Integration with Zoho Creator
- **Alamofire** - HTTP networking library
- **KeychainAccess** - Secure keychain wrapper
- **SwiftyJSON** - JSON parsing
- **Firebase** - Push notifications and analytics

### Node.js Dependencies
- **express** - Web framework
- **prisma** - Database ORM
- **jsonwebtoken** - JWT implementation
- **bcrypt** - Password hashing
- **helmet** - Security middleware
- **cors** - Cross-origin resource sharing
- **express-rate-limit** - API rate limiting

### Justification for Key Dependencies
- **Zoho Mobile SDK:** Essential for seamless integration with existing Zoho Creator data
- **PostgreSQL:** Reliable, feature-rich database with excellent JSON support for flexible offer data
- **SwiftUI:** Modern iOS development approach with better maintainability
- **Node.js:** JavaScript ecosystem provides rapid development and extensive package availability

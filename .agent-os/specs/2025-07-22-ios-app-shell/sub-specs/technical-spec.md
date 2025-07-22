# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-22-ios-app-shell/spec.md

> Created: 2025-07-22
> Version: 1.0.0

## Technical Requirements

### SwiftUI Architecture
- App must use SwiftUI for all UI components and navigation
- Minimum iOS 15.0+ deployment target for SwiftUI features
- Use Combine framework for state management and data flow
- Implement MVVM architecture pattern for clean separation of concerns

### Authentication Flow Requirements
- Welcome/splash screen with app branding and navigation to login
- Login screen with email/username and password fields
- Registration screen with required user information fields
- MFA verification screen with TOTP code input
- Password reset flow with email verification
- Smooth transitions between authentication states

### Main Navigation Structure
- TabView with 5 main sections: Buy, Sell, Messages, Favorites, Account
- Each tab should have appropriate SF Symbols icons
- Navigation state persistence when switching between tabs
- Badge support for notifications (Messages tab)
- Proper tab selection highlighting and accessibility

### State Management
- Authentication state management using @StateObject/@ObservableObject
- Navigation state coordination between authentication and main app
- User session state tracking (authenticated vs unauthenticated)
- Proper state cleanup on logout

### UI/UX Specifications
- Follow iOS Human Interface Guidelines for navigation and layout
- Use iOS system fonts and colors for consistency
- Implement proper safe area handling for all screen sizes
- Support both light and dark mode appearance
- Accessibility labels and traits for VoiceOver support

## Approach Options

**Option A:** Single ContentView with Navigation Coordinator
- Pros: Centralized navigation logic, easier state management
- Cons: Single view can become complex, harder to test individual flows

**Option B:** Separate Authentication and Main App Views (Selected)
- Pros: Clear separation of concerns, easier testing, better modularity
- Cons: More complex state coordination between views

**Rationale:** Option B provides better code organization and testability, which is crucial for the app shell foundation. The authentication flow and main app navigation are distinct user experiences that benefit from separation.

## External Dependencies

### Swift Package Manager Dependencies
- **No external UI dependencies** - Use native SwiftUI components only for the shell
- **KeychainAccess** - Secure storage for authentication tokens (future integration)
- **Combine** - Built-in reactive framework for state management

### iOS Framework Dependencies
- **SwiftUI** - Primary UI framework
- **Combine** - State management and reactive programming
- **LocalAuthentication** - For future biometric authentication integration
- **Foundation** - Core Swift functionality

**Justification:** Keeping external dependencies minimal for the app shell ensures stability and reduces complexity. Native SwiftUI components provide all needed functionality for basic navigation and authentication flow structure.

## File Structure

```
PolyPal/
├── PolyPalApp.swift                 // Main app entry point
├── ContentView.swift                // Root content view with auth state
├── Views/
│   ├── Authentication/
│   │   ├── WelcomeView.swift       // Welcome/splash screen
│   │   ├── LoginView.swift         // Login form
│   │   ├── RegisterView.swift      // Registration form
│   │   ├── MFAView.swift           // MFA verification
│   │   └── PasswordResetView.swift // Password reset
│   ├── Main/
│   │   ├── MainTabView.swift       // Main tab container
│   │   ├── BuyView.swift           // Buy section placeholder
│   │   ├── SellView.swift          // Sell section placeholder
│   │   ├── MessagesView.swift      // Messages section placeholder
│   │   ├── FavoritesView.swift     // Favorites section placeholder
│   │   └── AccountView.swift       // Account section placeholder
├── ViewModels/
│   ├── AuthenticationViewModel.swift // Auth state management
│   └── MainViewModel.swift         // Main app state management
├── Models/
│   ├── User.swift                  // User data model
│   └── AuthenticationState.swift  // Auth state enum
└── Extensions/
    └── View+Extensions.swift       // SwiftUI view extensions
```

## Performance Considerations

- Lazy loading of tab content to improve startup time
- Efficient state management to prevent unnecessary view updates
- Proper memory management for view controllers and state objects
- Fast authentication state transitions without flickering

## Testing Strategy

- Unit tests for ViewModels and authentication logic
- UI tests for navigation flows and authentication process
- Snapshot tests for consistent UI appearance
- Accessibility testing for VoiceOver compliance

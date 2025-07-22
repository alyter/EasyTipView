//
//  ContentView.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var authViewModel = AuthenticationViewModel()
  
  var body: some View {
    Group {
      if authViewModel.isAuthenticated {
        MainTabView()
          .environmentObject(authViewModel)
      } else {
        AuthenticationFlowView()
          .environmentObject(authViewModel)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
  }
}

struct AuthenticationFlowView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @State private var currentView: AuthView = .welcome
  
  enum AuthView {
    case welcome
    case login
    case register
    case mfa
    case passwordReset
  }
  
  var body: some View {
    NavigationView {
      Group {
        switch currentView {
        case .welcome:
          WelcomeView { action in
            handleAuthAction(action)
          }
        case .login:
          LoginView { action in
            handleAuthAction(action)
          }
        case .register:
          RegisterView { action in
            handleAuthAction(action)
          }
        case .mfa:
          MFAView { action in
            handleAuthAction(action)
          }
        case .passwordReset:
          PasswordResetView { action in
            handleAuthAction(action)
          }
        }
      }
      .animation(.easeInOut(duration: 0.25), value: currentView)
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
  
  private func handleAuthAction(_ action: AuthAction) {
    switch action {
    case .showLogin:
      currentView = .login
    case .showRegister:
      currentView = .register
    case .showWelcome:
      currentView = .welcome
    case .showMFA:
      currentView = .mfa
    case .showPasswordReset:
      currentView = .passwordReset
    case .dismissPasswordReset:
      currentView = .login
    }
  }
}

enum AuthAction {
  case showLogin
  case showRegister
  case showWelcome
  case showMFA
  case showPasswordReset
  case dismissPasswordReset
}

// Placeholder views - these will be implemented in Task 2
struct WelcomeView: View {
  let onAction: (AuthAction) -> Void
  
  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      
      // App Logo/Brand
      Image(systemName: "recycle")
        .font(.system(size: 80))
        .foregroundColor(.blue)
      
      Text("PolyPal")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Text("Connecting the Plastics Industry")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      Spacer()
      
      VStack(spacing: 16) {
        Button("Get Started") {
          onAction(.showLogin)
        }
        .buttonStyle(PrimaryButtonStyle())
        
        Button("Create Account") {
          onAction(.showRegister)
        }
        .buttonStyle(SecondaryButtonStyle())
      }
      .padding(.bottom, 32)
    }
    .padding()
  }
}

struct LoginView: View {
  let onAction: (AuthAction) -> Void
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @State private var email: String = ""
  @State private var password: String = ""
  
  var body: some View {
    VStack(spacing: 24) {
      Text("Welcome Back")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      VStack(spacing: 16) {
        TextField("Email", text: $email)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.emailAddress)
          .keyboardType(.emailAddress)
          .autocapitalization(.none)
        
        SecureField("Password", text: $password)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.password)
      }
      
      if let errorMessage = authViewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
      }
      
      Button("Sign In") {
        authViewModel.login(email: email, password: password)
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(!authViewModel.canAuthenticate)
      
      Button("Forgot Password?") {
        onAction(.showPasswordReset)
      }
      .font(.caption)
      .foregroundColor(.blue)
      
      HStack {
        Text("Don't have an account?")
          .font(.caption)
        Button("Sign Up") {
          onAction(.showRegister)
        }
        .font(.caption)
        .foregroundColor(.blue)
      }
    }
    .padding()
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Back") {
          onAction(.showWelcome)
        }
      }
    }
  }
}

struct RegisterView: View {
  let onAction: (AuthAction) -> Void
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @State private var email: String = ""
  @State private var password: String = ""
  @State private var confirmPassword: String = ""
  @State private var selectedRole: User.UserRole = .buyer
  
  var body: some View {
    VStack(spacing: 24) {
      Text("Create Account")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      VStack(spacing: 16) {
        TextField("Email", text: $email)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.emailAddress)
          .keyboardType(.emailAddress)
          .autocapitalization(.none)
        
        Picker("I am a", selection: $selectedRole) {
          Text("Buyer").tag(User.UserRole.buyer)
          Text("Vendor").tag(User.UserRole.vendor)
        }
        .pickerStyle(SegmentedPickerStyle())
        
        SecureField("Password", text: $password)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.newPassword)
        
        SecureField("Confirm Password", text: $confirmPassword)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.newPassword)
      }
      
      if let errorMessage = authViewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
      }
      
      Button("Create Account") {
        authViewModel.register(
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          role: selectedRole
        )
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(!authViewModel.canAuthenticate)
      
      HStack {
        Text("Already have an account?")
          .font(.caption)
        Button("Sign In") {
          onAction(.showLogin)
        }
        .font(.caption)
        .foregroundColor(.blue)
      }
    }
    .padding()
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Back") {
          onAction(.showWelcome)
        }
      }
    }
  }
}

struct MFAView: View {
  let onAction: (AuthAction) -> Void
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @State private var code: String = ""
  
  var body: some View {
    VStack(spacing: 24) {
      Text("Enter Verification Code")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Text("Please enter the 6-digit code from your authenticator app")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      TextField("123456", text: $code)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.title2)
      
      if let errorMessage = authViewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
      }
      
      Button("Verify") {
        authViewModel.verifyMFA(code: code)
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(!authViewModel.canAuthenticate)
    }
    .padding()
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct PasswordResetView: View {
  let onAction: (AuthAction) -> Void
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @State private var email: String = ""
  
  var body: some View {
    VStack(spacing: 24) {
      Text("Reset Password")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Text("Enter your email address and we'll send you a link to reset your password")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      TextField("Email", text: $email)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
      
      if let errorMessage = authViewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
      }
      
      Button("Send Reset Link") {
        authViewModel.requestPasswordReset(email: email)
        onAction(.dismissPasswordReset)
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(!authViewModel.canAuthenticate)
    }
    .padding()
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Cancel") {
          onAction(.dismissPasswordReset)
        }
      }
    }
  }
}

// Placeholder MainTabView - will be implemented in Task 3
struct MainTabView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  
  var body: some View {
    TabView {
      Text("Buy")
        .tabItem {
          Image(systemName: "magnifyingglass")
          Text("Buy")
        }
      
      Text("Sell")
        .tabItem {
          Image(systemName: "plus.circle")
          Text("Sell")
        }
      
      Text("Messages")
        .tabItem {
          Image(systemName: "message")
          Text("Messages")
        }
      
      Text("Favorites")
        .tabItem {
          Image(systemName: "heart")
          Text("Favorites")
        }
      
      VStack {
        Text("Account")
        Button("Logout") {
          authViewModel.logout()
        }
        .buttonStyle(SecondaryButtonStyle())
      }
      .tabItem {
        Image(systemName: "person")
        Text("Account")
      }
    }
  }
}

// Button Styles
struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(8)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
  }
}

struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.clear)
      .foregroundColor(.blue)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.blue, lineWidth: 1)
      )
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
  }
}

#Preview {
  ContentView()
}

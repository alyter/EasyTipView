//
//  ContentView.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var authViewModel = AuthenticationViewModel()
  @StateObject private var mainViewModel = MainViewModel()
  
  var body: some View {
    Group {
      if authViewModel.isAuthenticated {
        MainTabView()
          .environmentObject(authViewModel)
          .environmentObject(mainViewModel)
      } else {
        AuthenticationFlowView()
          .environmentObject(authViewModel)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
    .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
      if !isAuthenticated {
        // Reset main app state when user logs out
        mainViewModel.reset()
      }
    }
  }
}

struct AuthenticationFlowView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  
  var body: some View {
    NavigationView {
      Group {
        if authViewModel.showingLogin {
          LoginView()
        } else if authViewModel.showingRegister {
          RegisterView()
        } else if authViewModel.showingMFA {
          MFAView()
        } else if authViewModel.showingPasswordReset {
          PasswordResetView()
        } else {
          WelcomeView()
        }
      }
    }
    .navigationViewStyle(StackNavigationViewStyle())
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

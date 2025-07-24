//
//  WelcomeView.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import SwiftUI

struct WelcomeView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color.blue.opacity(0.8),
            Color.purple.opacity(0.6)
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 40) {
          Spacer()
          
          // App logo and branding
          VStack(spacing: 20) {
            // Logo placeholder - using SF Symbol for now
              Image("polypal-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

          }
          
          Spacer()
          
          // Action buttons
          VStack(spacing: 16) {
            // Login button
            Button(action: {
              authViewModel.navigateToLogin()
            }) {
              HStack {
                Image(systemName: "person.fill")
                Text("Sign In")
                  .fontWeight(.semibold)
              }
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.white)
              .foregroundColor(.blue)
              .cornerRadius(12)
              .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("Sign in to your account")
            .accessibilityHint("Navigate to login screen")
            
            // Register button
            Button(action: {
              authViewModel.navigateToRegister()
            }) {
              HStack {
                Image(systemName: "person.badge.plus")
                Text("Create Account")
                  .fontWeight(.semibold)
              }
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.clear)
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.white, lineWidth: 2)
              )
              .foregroundColor(.white)
            }
            .accessibilityLabel("Create a new account")
            .accessibilityHint("Navigate to registration screen")
          }
          .padding(.horizontal, 40)
          
          Spacer()
          
          // Footer text
          VStack(spacing: 8) {
            Text("Buy, sell, and discover amazing items")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.8))
              .multilineTextAlignment(.center)
            
            Text("Join thousands of satisfied users")
              .font(.caption)
              .foregroundColor(.white.opacity(0.7))
              .multilineTextAlignment(.center)
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
      }
    }
    .navigationBarHidden(true)
  }
}

// MARK: - Preview

struct WelcomeView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      WelcomeView()
        .environmentObject(AuthenticationViewModel())
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
      
      WelcomeView()
        .environmentObject(AuthenticationViewModel())
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
      
      WelcomeView()
        .environmentObject(AuthenticationViewModel())
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
        .previewDisplayName("iPhone SE")
      
      WelcomeView()
        .environmentObject(AuthenticationViewModel())
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro Max"))
        .previewDisplayName("iPhone 16 Pro Max")
    }
  }
}

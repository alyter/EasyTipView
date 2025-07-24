//
//  MFAView.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import SwiftUI

struct MFAView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @State private var localMFACode: String = ""
  @FocusState private var isCodeFieldFocused: Bool
  
  var body: some View {
    VStack(spacing: 32) {
      headerSection
      
      codeInputSection
      
      if let errorMessage = authViewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
          .multilineTextAlignment(.center)
      }
      
      actionButtons
      
      Spacer()
    }
    .padding(.horizontal, 24)
    .navigationTitle("Verification")
    .navigationBarTitleDisplayMode(.large)
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Back") {
          authViewModel.navigateBackFromMFA()
        }
      }
    }
    .onAppear {
      localMFACode = authViewModel.mfaCode
      isCodeFieldFocused = true
    }
    .onChange(of: localMFACode) { newValue in
      let formatted = authViewModel.formatMFACode(newValue)
      if formatted != localMFACode {
        localMFACode = formatted
      }
      authViewModel.mfaCode = formatted
    }
  }
  
  private var headerSection: some View {
    VStack(spacing: 16) {
      Image(systemName: "lock.shield.fill")
        .font(.system(size: 60))
        .foregroundColor(.blue)
      
      VStack(spacing: 8) {
        Text("Enter Verification Code")
          .font(.largeTitle)
          .fontWeight(.bold)
        
        Text("Please enter the 6-digit code from your authenticator app")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .lineLimit(nil)
      }
    }
  }
  
  private var codeInputSection: some View {
    VStack(spacing: 16) {
      TextField("Enter 6-digit code", text: $localMFACode)
        .textFieldStyle(CustomTextFieldStyle())
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.title2)
        .focused($isCodeFieldFocused)
      
      Text("Code expires in 30 seconds")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
  
  private var actionButtons: some View {
    VStack(spacing: 16) {
      Button("Verify Code") {
        Task {
          await authViewModel.verifyMFA(authViewModel.mfaCode)
        }
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(!authViewModel.canAuthenticate || !authViewModel.isValidMFACode(localMFACode))
      
      Button("Resend Code") {
        Task {
          await authViewModel.resendMFACode()
        }
      }
      .buttonStyle(SecondaryButtonStyle())
      .disabled(!authViewModel.canAuthenticate)
    }
  }
}

#Preview {
  NavigationView {
    MFAView()
      .environmentObject({
        let vm = AuthenticationViewModel()
        vm.authenticationState = .mfaRequired
        return vm
      }())
  }
}

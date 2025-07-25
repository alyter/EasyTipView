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
  @State private var backupCode: String = ""
  @State private var showingBackupCodeInput: Bool = false
  @FocusState private var isCodeFieldFocused: Bool
  @FocusState private var isBackupCodeFieldFocused: Bool
  
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
      if showingBackupCodeInput {
        backupCodeInputSection
      } else {
        totpCodeInputSection
      }
      
      Button(showingBackupCodeInput ? "Use authenticator code instead" : "Use backup code instead") {
        withAnimation(.easeInOut(duration: 0.3)) {
          showingBackupCodeInput.toggle()
          if showingBackupCodeInput {
            isBackupCodeFieldFocused = true
            isCodeFieldFocused = false
          } else {
            isCodeFieldFocused = true
            isBackupCodeFieldFocused = false
          }
        }
      }
      .font(.caption)
      .foregroundColor(.blue)
    }
  }
  
  private var totpCodeInputSection: some View {
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
  
  private var backupCodeInputSection: some View {
    VStack(spacing: 16) {
      TextField("Enter backup code", text: $backupCode)
        .textFieldStyle(CustomTextFieldStyle())
        .textInputAutocapitalization(.characters)
        .multilineTextAlignment(.center)
        .font(.title2)
        .focused($isBackupCodeFieldFocused)
        .onChange(of: backupCode) { newValue in
          backupCode = authViewModel.formatBackupCode(newValue)
        }
      
      Text("Format: XXXX-XXXX")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
  
  private var actionButtons: some View {
    VStack(spacing: 16) {
      Button(showingBackupCodeInput ? "Verify Backup Code" : "Verify Code") {
        Task {
          if showingBackupCodeInput {
            await authViewModel.verifyBackupCode(backupCode)
          } else {
            await authViewModel.verifyMFAWithTOTP(localMFACode)
          }
        }
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(!authViewModel.canAuthenticate || 
                (showingBackupCodeInput ? !authViewModel.isValidBackupCode(backupCode) : !authViewModel.isValidMFACode(localMFACode)))
      
      if !showingBackupCodeInput {
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

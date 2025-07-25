//
//  MFASetupView.swift
//  PolyPal
//
//  Created by PolyPal on 7/24/25.
//

import SwiftUI
import UIKit

struct MFASetupView: View {
  
  // MARK: - Setup Steps
  
  enum SetupStep: Int, CaseIterable {
    case introduction = 0
    case qrCode = 1
    case verification = 2
    case backupCodes = 3
    case completion = 4
    
    var title: String {
      switch self {
      case .introduction:
        return "Enable Two-Factor Authentication"
      case .qrCode:
        return "Scan QR Code"
      case .verification:
        return "Verify Setup"
      case .backupCodes:
        return "Save Backup Codes"
      case .completion:
        return "Setup Complete"
      }
    }
    
    var description: String {
      switch self {
      case .introduction:
        return "Add an extra layer of security to your account"
      case .qrCode:
        return "Use your authenticator app to scan this QR code"
      case .verification:
        return "Enter the 6-digit code from your authenticator app"
      case .backupCodes:
        return "Save these codes in a secure location"
      case .completion:
        return "Two-factor authentication is now enabled"
      }
    }
  }
  
  // MARK: - State Properties
  
  @State private var currentStep: SetupStep = .introduction
  @State private var secretKey: String = ""
  @State private var verificationCode: String = ""
  @State private var backupCodes: [String] = []
  @State private var qrCodeImage: UIImage?
  @State private var isLoading: Bool = false
  @State private var errorMessage: String?
  @State private var showingError: Bool = false
  @State private var showingShareSheet: Bool = false
  
  // MARK: - Managers
  
  private let mfaManager = MFAManager()
  private let backupCodeManager = BackupCodeManager()
  private let qrCodeManager = QRCodeManager()
  
  // MARK: - Environment
  
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Progress Indicator
        progressIndicator
        
        // Content
        ScrollView {
          VStack(spacing: 24) {
            stepContent
          }
          .padding(.horizontal, 24)
          .padding(.vertical, 32)
        }
        
        // Navigation Buttons
        navigationButtons
      }
      .navigationTitle(currentStep.title)
      .navigationBarTitleDisplayMode(.large)
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .alert("Error", isPresented: $showingError) {
        Button("OK") {
          errorMessage = nil
        }
      } message: {
        Text(errorMessage ?? "An unexpected error occurred")
      }
      .sheet(isPresented: $showingShareSheet) {
        ShareSheet(items: [backupCodesText])
      }
      .onAppear {
        generateSecretKey()
      }
    }
  }
  
  // MARK: - Progress Indicator
  
  private var progressIndicator: some View {
    VStack(spacing: 8) {
      HStack {
        ForEach(SetupStep.allCases, id: \.rawValue) { step in
          Circle()
            .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 12, height: 12)
          
          if step != SetupStep.allCases.last {
            Rectangle()
              .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
              .frame(height: 2)
          }
        }
      }
      .padding(.horizontal, 24)
      
      Text("Step \(currentStep.rawValue + 1) of \(SetupStep.allCases.count)")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 16)
    .background(Color(.systemBackground))
  }
  
  // MARK: - Step Content
  
  @ViewBuilder
  private var stepContent: some View {
    switch currentStep {
    case .introduction:
      introductionStep
    case .qrCode:
      qrCodeStep
    case .verification:
      verificationStep
    case .backupCodes:
      backupCodesStep
    case .completion:
      completionStep
    }
  }
  
  // MARK: - Introduction Step
  
  private var introductionStep: some View {
    VStack(spacing: 24) {
      Image(systemName: "shield.checkered")
        .font(.system(size: 80))
        .foregroundColor(.blue)
      
      VStack(spacing: 16) {
        Text("Secure Your Account")
          .font(.title2)
          .font(.system(size: 22, weight: .semibold))
        
        Text("Two-factor authentication adds an extra layer of security to your PolyPal account. You'll need both your password and a code from your authenticator app to sign in.")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      }
      
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("Protects against unauthorized access")
        }
        
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("Works with popular authenticator apps")
        }
        
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("Includes backup codes for recovery")
        }
      }
      .font(.subheadline)
      
      Text("You'll need an authenticator app like Google Authenticator, Authy, or 1Password to continue.")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.top, 8)
    }
  }
  
  // MARK: - QR Code Step
  
  private var qrCodeStep: some View {
    VStack(spacing: 24) {
      VStack(spacing: 16) {
        Text("Scan with your authenticator app")
          .font(.headline)
        
        Text("Open your authenticator app and scan this QR code to add your PolyPal account.")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      }
      
      // QR Code Display
      if let qrCodeImage = qrCodeImage {
        Image(uiImage: qrCodeImage)
          .interpolation(.none)
          .resizable()
          .scaledToFit()
          .frame(width: 200, height: 200)
          .background(Color.white)
          .cornerRadius(12)
          .shadow(radius: 4)
      } else if isLoading {
        ProgressView()
          .frame(width: 200, height: 200)
      } else {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.2))
          .frame(width: 200, height: 200)
          .overlay(
            Text("QR Code\nUnavailable")
              .multilineTextAlignment(.center)
              .foregroundColor(.secondary)
          )
      }
      
      // Manual Entry Option
      VStack(spacing: 8) {
        Text("Can't scan? Enter this code manually:")
          .font(.caption)
          .foregroundColor(.secondary)
        
        Text(secretKey)
          .font(.system(.caption, design: .monospaced))
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(.systemGray6))
          .cornerRadius(8)
          .onTapGesture {
            UIPasteboard.general.string = secretKey
          }
        
        Text("Tap to copy")
          .font(.caption2)
          .foregroundColor(.blue)
      }
      
      // Recommended Apps
      VStack(alignment: .leading, spacing: 8) {
        Text("Recommended authenticator apps:")
          .font(.caption)
          .foregroundColor(.secondary)
        
        HStack(spacing: 16) {
          Text("• Google Authenticator")
          Text("• Authy")
          Text("• 1Password")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
      }
    }
  }
  
  // MARK: - Verification Step
  
  private var verificationStep: some View {
    VStack(spacing: 24) {
      VStack(spacing: 16) {
        Text("Enter verification code")
          .font(.headline)
        
        Text("Enter the 6-digit code from your authenticator app to verify the setup.")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      }
      
      // Verification Code Input
      VStack(spacing: 16) {
        TextField("000000", text: $verificationCode)
          .font(.system(.title, design: .monospaced))
          .multilineTextAlignment(.center)
          .keyboardType(.numberPad)
          .textContentType(.oneTimeCode)
          .frame(maxWidth: 200)
          .padding(.vertical, 16)
          .background(Color(.systemGray6))
          .cornerRadius(12)
          .onChange(of: verificationCode) { newValue in
            // Limit to 6 digits
            if newValue.count > 6 {
              verificationCode = String(newValue.prefix(6))
            }
            // Remove non-numeric characters
            verificationCode = newValue.filter { $0.isNumber }
          }
        
        if !verificationCode.isEmpty && verificationCode.count < 6 {
          Text("Enter all 6 digits")
            .font(.caption)
            .foregroundColor(.orange)
        }
      }
      
      Text("The code changes every 30 seconds")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
  
  // MARK: - Backup Codes Step
  
  private var backupCodesStep: some View {
    VStack(spacing: 24) {
      VStack(spacing: 16) {
        Text("Save your backup codes")
          .font(.headline)
        
        Text("These codes can be used to access your account if you lose your authenticator device. Save them in a secure location.")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      }
      
      // Backup Codes Display
      VStack(spacing: 12) {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
          ForEach(Array(backupCodes.enumerated()), id: \.offset) { index, code in
            Text(code)
              .font(.system(.body, design: .monospaced))
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Color(.systemGray6))
              .cornerRadius(8)
          }
        }
        
        Button(action: {
          showingShareSheet = true
        }) {
          HStack {
            Image(systemName: "square.and.arrow.up")
            Text("Save Codes")
          }
          .font(.subheadline)
          .foregroundColor(.blue)
        }
        .padding(.top, 8)
      }
      
      // Warning
      VStack(spacing: 8) {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
          Text("Important")
            .font(.system(size: 16, weight: .semibold))
        }
        
        Text("Each backup code can only be used once. Store them securely and don't share them with anyone.")
          .font(.caption)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color.orange.opacity(0.1))
      .cornerRadius(12)
    }
  }
  
  // MARK: - Completion Step
  
  private var completionStep: some View {
    VStack(spacing: 24) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 80))
        .foregroundColor(.green)
      
      VStack(spacing: 16) {
        Text("Setup Complete!")
          .font(.title2)
          .font(.system(size: 22, weight: .semibold))
        
        Text("Two-factor authentication is now enabled for your PolyPal account. You'll need to enter a code from your authenticator app each time you sign in.")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      }
      
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("Your account is now more secure")
        }
        
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("Backup codes have been saved")
        }
        
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("You can manage MFA in account settings")
        }
      }
      .font(.subheadline)
    }
  }
  
  // MARK: - Navigation Buttons
  
  private var navigationButtons: some View {
    VStack(spacing: 16) {
      HStack(spacing: 16) {
        // Back Button
        if currentStep != .introduction && currentStep != .completion {
          Button("Back") {
            withAnimation {
              currentStep = SetupStep(rawValue: currentStep.rawValue - 1) ?? .introduction
            }
          }
          .font(.subheadline)
          .foregroundColor(.blue)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(12)
        }
        
        // Next/Continue Button
        Button(nextButtonTitle) {
          handleNextButtonTap()
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isNextButtonEnabled ? Color.blue : Color.gray)
        .cornerRadius(12)
        .disabled(!isNextButtonEnabled || isLoading)
      }
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 34) // Account for safe area
    .background(Color(.systemBackground))
  }
  
  // MARK: - Computed Properties
  
  private var nextButtonTitle: String {
    switch currentStep {
    case .introduction:
      return "Get Started"
    case .qrCode:
      return "I've Scanned the Code"
    case .verification:
      return "Verify Code"
    case .backupCodes:
      return "I've Saved My Codes"
    case .completion:
      return "Done"
    }
  }
  
  private var isNextButtonEnabled: Bool {
    switch currentStep {
    case .introduction, .qrCode, .backupCodes, .completion:
      return true
    case .verification:
      return verificationCode.count == 6
    }
  }
  
  private var backupCodesText: String {
    let header = "PolyPal Backup Codes\n" +
                "Generated: \(Date().formatted(date: .abbreviated, time: .shortened))\n" +
                "Account: Your PolyPal Account\n\n" +
                "IMPORTANT: Each code can only be used once. Store securely.\n\n"
    
    let codes = backupCodes.enumerated().map { index, code in
      "\(index + 1). \(code)"
    }.joined(separator: "\n")
    
    return header + codes
  }
  
  // MARK: - Methods
  
  private func generateSecretKey() {
    let secretData = mfaManager.generateSecretKey()
    secretKey = mfaManager.base32Encode(secretData)
    generateQRCode()
  }
  
  private func generateQRCode() {
    guard !secretKey.isEmpty else { return }
    
    isLoading = true
    
    DispatchQueue.global(qos: .userInitiated).async {
      if let otpAuthURL = self.qrCodeManager.generateOTPAuthURL(
        secret: self.secretKey,
        accountName: "Your Account", // This would be the actual user's email/username
        issuer: "PolyPal"
      ) {
        let qrImage = self.qrCodeManager.generateQRCodeImage(from: otpAuthURL)
        
        DispatchQueue.main.async {
          self.qrCodeImage = qrImage
          self.isLoading = false
        }
      } else {
        DispatchQueue.main.async {
          self.showError("Failed to generate QR code URL")
          self.isLoading = false
        }
      }
    }
  }
  
  private func generateBackupCodes() {
    backupCodes = backupCodeManager.generateBackupCodes()
    let success = backupCodeManager.storeBackupCodes(backupCodes, for: "current_user") // This would be the actual user ID
    if !success {
      showError("Failed to store backup codes")
    }
  }
  
  private func handleNextButtonTap() {
    switch currentStep {
    case .introduction:
      withAnimation {
        currentStep = .qrCode
      }
      
    case .qrCode:
      withAnimation {
        currentStep = .verification
      }
      
    case .verification:
      verifyCode()
      
    case .backupCodes:
      withAnimation {
        currentStep = .completion
      }
      
    case .completion:
      dismiss()
    }
  }
  
  private func verifyCode() {
    guard verificationCode.count == 6 else { return }
    
    isLoading = true
    
    guard let secretData = mfaManager.base32Decode(secretKey) else {
      showError("Invalid secret key format")
      isLoading = false
      return
    }
    
    let isValid = mfaManager.validateTOTP(code: verificationCode, secretKey: secretData)
    
    if isValid {
      // TODO: Store the secret key securely in Keychain
      // For now, we'll just proceed to backup codes
      
      // Generate backup codes
      generateBackupCodes()
      
      withAnimation {
        currentStep = .backupCodes
      }
    } else {
      showError("Invalid verification code. Please try again.")
    }
    
    isLoading = false
  }
  
  private func showError(_ message: String) {
    errorMessage = message
    showingError = true
  }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]
  
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct MFASetupView_Previews: PreviewProvider {
  static var previews: some View {
    MFASetupView()
  }
}

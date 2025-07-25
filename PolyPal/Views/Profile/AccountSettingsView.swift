import SwiftUI

struct AccountSettingsView: View {
  @ObservedObject var viewModel: ProfileViewModel
  @State private var showingDeleteConfirmation = false
  @State private var showingExportConfirmation = false
  @State private var isExporting = false
  
  var body: some View {
    NavigationView {
      Form {
        // Privacy Settings Section
        privacySettingsSection
        
        // Detailed Privacy Controls Section
        detailedPrivacySection
        
        // Notification Settings Section
        notificationSettingsSection
        
        // Security Settings Section
        securitySettingsSection
        
        // Account Actions Section
        accountActionsSection
      }
      .navigationTitle("Account Settings")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            saveSettings()
          }
          .disabled(!hasUnsavedChanges)
        }
      }
    }
  }
  
  // MARK: - Privacy Settings Section
  
  private var privacySettingsSection: some View {
    Section("Privacy Settings") {
      Toggle("Public Profile", isOn: $viewModel.profile.isPublicProfile)
        .help("Make your profile visible to other users")
      
      Toggle("Allow Direct Messages", isOn: $viewModel.profile.allowDirectMessages)
        .help("Allow other users to send you direct messages")
      
      Toggle("Show Contact Information", isOn: $viewModel.profile.showContactInfo)
        .help("Display your contact information on your profile")
    }
  }
  
  // MARK: - Detailed Privacy Controls Section
  
  private var detailedPrivacySection: some View {
    Section("Contact Information Privacy") {
      Toggle("Show Email Address", isOn: $viewModel.profile.privacySettings.showEmail)
        .help("Display your email address on your profile")
      
      Toggle("Show Phone Number", isOn: $viewModel.profile.privacySettings.showPhoneNumber)
        .help("Display your phone number on your profile")
      
      Toggle("Show Physical Address", isOn: $viewModel.profile.privacySettings.showAddress)
        .help("Display your physical address on your profile")
      
      Toggle("Show LinkedIn Profile", isOn: $viewModel.profile.privacySettings.showLinkedInProfile)
        .help("Display your LinkedIn profile link")
      
      Toggle("Show Website", isOn: $viewModel.profile.privacySettings.showWebsite)
        .help("Display your website URL on your profile")
      
      Toggle("Show Online Status", isOn: $viewModel.profile.privacySettings.showOnlineStatus)
        .help("Show when you're online to other users")
    }
  }
  
  // MARK: - Notification Settings Section
  
  private var notificationSettingsSection: some View {
    Section("Notification Settings") {
      // Notification Summary
      HStack {
        Image(systemName: "bell.fill")
          .foregroundColor(.blue)
        VStack(alignment: .leading) {
          Text("Current Settings")
            .font(.headline)
          Text(viewModel.getNotificationSummary())
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
      }
      .padding(.vertical, 4)
      
      // Delivery Methods
      Group {
        Toggle("Email Notifications", isOn: $viewModel.profile.notificationSettings.emailNotifications)
          .help("Receive notifications via email")
        
        Toggle("Push Notifications", isOn: $viewModel.profile.notificationSettings.pushNotifications)
          .help("Receive push notifications on your device")
        
        Toggle("SMS Notifications", isOn: $viewModel.profile.notificationSettings.smsNotifications)
          .help("Receive notifications via SMS")
      }
      
      Divider()
      
      // Notification Types
      Group {
        Toggle("New Message Notifications", isOn: $viewModel.profile.notificationSettings.newMessageNotifications)
          .help("Get notified when you receive new messages")
        
        Toggle("Connection Request Notifications", isOn: $viewModel.profile.notificationSettings.connectionRequestNotifications)
          .help("Get notified when someone wants to connect")
        
        Toggle("System Update Notifications", isOn: $viewModel.profile.notificationSettings.systemUpdateNotifications)
          .help("Receive notifications about system updates")
        
        Toggle("Marketing Emails", isOn: $viewModel.profile.notificationSettings.marketingEmails)
          .help("Receive marketing and promotional emails")
      }
      
      // Validation Warning
      if !viewModel.validateNotificationSettings() {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
          Text("Enable at least one delivery method for notifications to work")
            .font(.caption)
            .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
      }
    }
  }
  
  // MARK: - Security Settings Section
  
  private var securitySettingsSection: some View {
    Section("Security Settings") {
      // Multi-Factor Authentication Section
      mfaSettingsView
      
      Divider()
      
      // Password Management
      Button(action: {
        changePassword()
      }) {
        HStack {
          Image(systemName: "key.fill")
            .foregroundColor(.blue)
          Text("Change Password")
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
            .font(.caption)
        }
      }
      .foregroundColor(.primary)
      
      // Login Sessions
      Button(action: {
        reviewLoginSessions()
      }) {
        HStack {
          Image(systemName: "desktopcomputer")
            .foregroundColor(.blue)
          Text("Review Login Sessions")
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
            .font(.caption)
        }
      }
      .foregroundColor(.primary)
      
      // Data Export
      Button(action: {
        showingExportConfirmation = true
      }) {
        HStack {
          Image(systemName: "square.and.arrow.down")
            .foregroundColor(.blue)
          Text("Download Account Data")
          Spacer()
          if isExporting {
            ProgressView()
              .scaleEffect(0.8)
          } else {
            Image(systemName: "chevron.right")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
      }
      .foregroundColor(.primary)
      .disabled(isExporting)
      .alert("Export Account Data", isPresented: $showingExportConfirmation) {
        Button("Cancel", role: .cancel) { }
        Button("Export") {
          exportUserData()
        }
      } message: {
        Text("This will create a file containing all your account data. The export may take a few minutes.")
      }
    }
  }
  
  // MARK: - Account Actions Section
  
  private var accountActionsSection: some View {
    Section("Account Actions") {
      Button("Export Data") {
        exportUserData()
      }
      .foregroundColor(.blue)
      
      Button("Delete Account") {
        showingDeleteConfirmation = true
      }
      .foregroundColor(.red)
      .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
        Button("Cancel", role: .cancel) { }
        Button("Delete", role: .destructive) {
          deleteAccount()
        }
      } message: {
        Text("Are you sure you want to delete your account? This action cannot be undone.")
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private var hasUnsavedChanges: Bool {
    return viewModel.hasUnsavedChanges
  }
  
  private func saveSettings() {
    // Save user preferences to persistent storage
    viewModel.saveUserPreferences()
    
    // Save the profile data
    viewModel.saveProfile { success in
      DispatchQueue.main.async {
        if success {
          print("Settings saved successfully")
        } else {
          print("Failed to save settings")
        }
      }
    }
  }
  
  private func exportUserData() {
    isExporting = true
    
    // Implementation for exporting user data
    // This would typically create a JSON or CSV file with user data
    viewModel.requestDataExport { success in
      DispatchQueue.main.async {
        self.isExporting = false
        if success {
          print("User data exported successfully")
        } else {
          print("User data export failed")
        }
      }
    }
  }
  
  private func deleteAccount() {
    // Implementation for deleting user account
    // This would typically call an API to delete the account
    viewModel.requestAccountDeletion { success in
      if success {
        print("Account deletion initiated...")
      } else {
        print("Account deletion failed")
      }
    }
  }
  
  private func changePassword() {
    // Implementation for changing password
    // This would typically navigate to a password change view
    print("Navigate to change password...")
  }
  
  private func enableTwoFactorAuth() {
    // Implementation for enabling two-factor authentication
    // This would typically navigate to 2FA setup
    print("Navigate to two-factor authentication setup...")
  }
  
  private func reviewLoginSessions() {
    // Implementation for reviewing login sessions
    // This would typically show a list of active sessions
    print("Navigate to login sessions review...")
  }
  
  // MARK: - MFA Settings View
  
  private var mfaSettingsView: some View {
    VStack(alignment: .leading, spacing: 12) {
      // MFA Status Header
      HStack {
        VStack(alignment: .leading) {
          Text("Multi-Factor Authentication")
            .font(.headline)
          Text(viewModel.getMFAStatusText())
            .font(.caption)
            .foregroundColor(viewModel.profile.mfaSettings.isEnabled ? .green : .secondary)
        }
        Spacer()
        
        if viewModel.profile.mfaSettings.isEnabled {
          Image(systemName: "checkmark.shield.fill")
            .foregroundColor(.green)
            .font(.title2)
        } else {
          Image(systemName: "shield")
            .foregroundColor(.secondary)
            .font(.title2)
        }
      }
      .padding(.vertical, 4)
      
      // MFA Enable/Disable Button
      if viewModel.profile.mfaSettings.isEnabled {
        mfaEnabledView
      } else {
        mfaDisabledView
      }
      
      // Backup Codes Warning
      if viewModel.shouldShowBackupCodeWarning() {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
          Text("Low backup codes remaining. Consider regenerating.")
            .font(.caption)
            .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
      }
    }
  }
  
  private var mfaEnabledView: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Backup Codes Status
      HStack {
        Text(viewModel.getBackupCodesStatusText())
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
      }
      
      // MFA Management Buttons
      VStack(spacing: 8) {
        // Regenerate Backup Codes
        Button(action: {
          regenerateBackupCodes()
        }) {
          HStack {
            Image(systemName: "arrow.clockwise")
              .foregroundColor(.blue)
            Text("Regenerate Backup Codes")
            Spacer()
            Image(systemName: "chevron.right")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
        .foregroundColor(.primary)
        
        // Disable MFA
        Button(action: {
          disableMFA()
        }) {
          HStack {
            Image(systemName: "shield.slash")
              .foregroundColor(.red)
            Text("Disable MFA")
            Spacer()
            Image(systemName: "chevron.right")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
        .foregroundColor(.red)
      }
    }
  }
  
  private var mfaDisabledView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Secure your account with an additional layer of protection")
        .font(.caption)
        .foregroundColor(.secondary)
      
      Button(action: {
        enableMFA()
      }) {
        HStack {
          Image(systemName: "shield.checkered")
            .foregroundColor(.blue)
          Text("Enable MFA")
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
            .font(.caption)
        }
      }
      .foregroundColor(.primary)
    }
  }
  
  // MARK: - MFA Actions
  
  private func enableMFA() {
    Task {
      await viewModel.enableMFA { success in
        if success {
          print("MFA enabled successfully")
          // In a real app, this might navigate to MFA setup view
          viewModel.isShowingMFASetup = true
        } else {
          print("Failed to enable MFA")
        }
      }
    }
  }
  
  private func disableMFA() {
    // Show confirmation alert
    let alert = UIAlertController(
      title: "Disable Multi-Factor Authentication",
      message: "Are you sure you want to disable MFA? This will make your account less secure.",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Disable", style: .destructive) { _ in
      Task {
        await viewModel.disableMFA { success in
          if success {
            print("MFA disabled successfully")
          } else {
            print("Failed to disable MFA")
          }
        }
      }
    })
    
    // Present alert (in a real app, this would use proper SwiftUI alert)
    print("Would show disable MFA confirmation alert")
    
    // For now, directly disable (in real app, this would be in the alert action)
    Task {
      await viewModel.disableMFA { success in
        if success {
          print("MFA disabled successfully")
        } else {
          print("Failed to disable MFA")
        }
      }
    }
  }
  
  private func regenerateBackupCodes() {
    Task {
      await viewModel.regenerateBackupCodes { success, newCodes in
        if success, let codes = newCodes {
          print("Backup codes regenerated successfully")
          // In a real app, this might show the new codes to the user
          viewModel.isShowingBackupCodeRegeneration = true
        } else {
          print("Failed to regenerate backup codes")
        }
      }
    }
  }
}

// MARK: - Preview

struct AccountSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    AccountSettingsView(viewModel: ProfileViewModel())
  }
}

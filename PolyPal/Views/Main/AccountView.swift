import SwiftUI

struct AccountView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @StateObject private var profileViewModel = ProfileViewModel()
  @State private var showingAccountSettings = false
  @State private var showingProfile = false
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Image(systemName: "person.circle.fill")
          .font(.system(size: 60))
          .foregroundColor(.purple)
        
        Text("Account")
          .font(.largeTitle)
          .fontWeight(.bold)
        
        Text("Manage your profile and settings")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        
        Spacer()
        
        VStack(spacing: 16) {
          Button("View Profile") {
            showingProfile = true
          }
          .buttonStyle(SecondaryButtonStyle())
          
          Button("Account Settings") {
            showingAccountSettings = true
          }
          .buttonStyle(SecondaryButtonStyle())
          
          Button("Help & Support") {
            // Help functionality will be added later
          }
          .buttonStyle(SecondaryButtonStyle())
          
          Button("Logout") {
            authViewModel.logout()
          }
          .buttonStyle(LogoutButtonStyle())
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingProfile) {
          Text("Profile Display Coming Soon")
            .padding()
        }
        .sheet(isPresented: $showingAccountSettings) {
          AccountSettingsView(viewModel: profileViewModel)
        }
        
        Spacer()
      }
      .padding()
      .navigationTitle("Account")
      .navigationBarTitleDisplayMode(.large)
    }
    .accessibilityLabel("Account section")
    .accessibilityHint("Manage your profile and settings")
  }
}

struct LogoutButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.red)
      .foregroundColor(.white)
      .cornerRadius(8)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
  }
}


#Preview {
  AccountView()
    .environmentObject(AuthenticationViewModel())
}

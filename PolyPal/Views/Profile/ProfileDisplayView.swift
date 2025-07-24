import SwiftUI

struct ProfileDisplayView: View {
  let profile: UserProfile
  @ObservedObject var viewModel: ProfileViewModel
  @State private var showingEditView = false
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // Profile Header
        profileHeaderSection
        
        // Basic Information
        basicInfoSection
        
        // Contact Information
        contactInfoSection
        
        // Company Information
        companyInfoSection
        
        // Additional Information
        additionalInfoSection
        
        // Action Buttons
        actionButtonsSection
      }
      .padding()
    }
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Edit") {
          showingEditView = true
        }
      }
    }
    .sheet(isPresented: $showingEditView) {
      NavigationView {
        ProfileEditView(profile: profile, viewModel: viewModel)
      }
    }
  }
  
  // MARK: - Profile Header Section
  
  private var profileHeaderSection: some View {
    HStack {
      // Profile Image
      AsyncImage(url: URL(string: profile.profileImageURL ?? "")) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Image(systemName: "person.circle.fill")
          .font(.system(size: 80))
          .foregroundColor(.gray)
      }
      .frame(width: 80, height: 80)
      .clipShape(Circle())
      
      VStack(alignment: .leading, spacing: 4) {
        Text(profile.fullName)
          .font(.title2)
          .fontWeight(.bold)
        
        if !profile.jobTitle.isEmpty {
          Text(profile.jobTitle)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        
        if !profile.companyName.isEmpty {
          Text(profile.companyName)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
      
      Spacer()
    }
  }
  
  // MARK: - Basic Information Section
  
  private var basicInfoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Basic Information")
        .font(.headline)
        .padding(.bottom, 4)
      
      if let dateOfBirth = profile.dateOfBirth {
        InfoRow(label: "Date of Birth", value: DateFormatter.displayFormatter.string(from: dateOfBirth))
      }
      
      if let bio = profile.bio, !bio.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Text("Bio")
            .font(.subheadline)
            .fontWeight(.medium)
          Text(bio)
            .font(.body)
        }
      }
    }
  }
  
  // MARK: - Contact Information Section
  
  private var contactInfoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Contact Information")
        .font(.headline)
        .padding(.bottom, 4)
      
      if profile.showContactInfo {
        InfoRow(label: "Email", value: profile.email)
        InfoRow(label: "Phone", value: profile.phoneNumber)
        InfoRow(label: "Preferred Contact", value: profile.preferredContactMethod.rawValue.capitalized)
      } else {
        Text("Contact information is private")
          .font(.body)
          .foregroundColor(.secondary)
          .italic()
      }
    }
  }
  
  // MARK: - Company Information Section
  
  private var companyInfoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Company Information")
        .font(.headline)
        .padding(.bottom, 4)
      
      if !profile.companyName.isEmpty {
        InfoRow(label: "Company", value: profile.companyName)
      }
      
      if !profile.jobTitle.isEmpty {
        InfoRow(label: "Job Title", value: profile.jobTitle)
      }
    }
  }
  
  // MARK: - Additional Information Section
  
  private var additionalInfoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Additional Information")
        .font(.headline)
        .padding(.bottom, 4)
      
      if let website = profile.website, !website.isEmpty {
        InfoRow(label: "Website", value: website, isLink: true)
      }
      
      if let linkedIn = profile.linkedInProfile, !linkedIn.isEmpty {
        InfoRow(label: "LinkedIn", value: linkedIn, isLink: true)
      }
      
      // Address Information
      let addressComponents = [profile.address, profile.city, profile.state, profile.zipCode].filter { !$0.isEmpty }
      if !addressComponents.isEmpty {
        InfoRow(label: "Address", value: addressComponents.joined(separator: ", "))
      }
    }
  }
  
  // MARK: - Action Buttons Section
  
  private var actionButtonsSection: some View {
    VStack(spacing: 12) {
      if profile.allowDirectMessages {
        Button(action: {
          // Handle send message action
        }) {
          HStack {
            Image(systemName: "message")
            Text("Send Message")
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
        }
      }
      
      Button(action: {
        // Handle share profile action
      }) {
        HStack {
          Image(systemName: "square.and.arrow.up")
          Text("Share Profile")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
        .foregroundColor(.primary)
        .cornerRadius(8)
      }
    }
  }
}

// MARK: - Info Row Component

struct InfoRow: View {
  let label: String
  let value: String
  let isLink: Bool
  
  init(label: String, value: String, isLink: Bool = false) {
    self.label = label
    self.value = value
    self.isLink = isLink
  }
  
  var body: some View {
    HStack(alignment: .top) {
      Text(label)
        .font(.subheadline)
        .fontWeight(.medium)
        .frame(width: 100, alignment: .leading)
      
      if isLink {
        Link(value, destination: URL(string: value) ?? URL(string: "https://example.com")!)
          .font(.body)
      } else {
        Text(value)
          .font(.body)
      }
      
      Spacer()
    }
  }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
  static let displayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
  }()
}

// MARK: - Preview

struct ProfileDisplayView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      ProfileDisplayView(
        profile: UserProfile(
          firstName: "John",
          lastName: "Doe",
          email: "john.doe@example.com",
          phoneNumber: "(555) 123-4567",
          companyName: "Tech Corp",
          jobTitle: "Software Engineer",
          address: "123 Main St",
          city: "San Francisco",
          state: "CA",
          zipCode: "94105",
          country: "United States",
          bio: "Passionate software engineer with 5 years of experience in iOS development.",
          website: "https://johndoe.dev",
          linkedInProfile: "https://linkedin.com/in/johndoe"
        ),
        viewModel: ProfileViewModel()
      )
    }
  }
}

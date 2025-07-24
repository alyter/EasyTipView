import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct ProfileEditView: View {
  let profile: UserProfile
  @ObservedObject var viewModel: ProfileViewModel
  @Environment(\.dismiss) private var dismiss
  
  @State private var firstName: String
  @State private var lastName: String
  @State private var email: String
  @State private var phoneNumber: String
  @State private var companyName: String
  @State private var jobTitle: String
  @State private var address: String
  @State private var city: String
  @State private var state: String
  @State private var zipCode: String
  @State private var country: String
  @State private var bio: String
  @State private var website: String
  @State private var linkedIn: String
  @State private var preferredContactMethod: ContactMethod
  @State private var isPublicProfile: Bool
  @State private var allowDirectMessages: Bool
  @State private var showContactInfo: Bool
  @State private var profileImageURL: String?
  
  @State private var showingImagePicker = false
  @State private var selectedImage: PhotosPickerItem?
  @State private var isLoading = false
  @State private var showingAlert = false
  @State private var alertMessage = ""
  
  init(profile: UserProfile, viewModel: ProfileViewModel) {
    self.profile = profile
    self.viewModel = viewModel
    
    // Initialize state variables with profile data
    _firstName = State(initialValue: profile.firstName)
    _lastName = State(initialValue: profile.lastName)
    _email = State(initialValue: profile.email)
    _phoneNumber = State(initialValue: profile.phoneNumber)
    _companyName = State(initialValue: profile.companyName)
    _jobTitle = State(initialValue: profile.jobTitle)
    _address = State(initialValue: profile.address)
    _city = State(initialValue: profile.city)
    _state = State(initialValue: profile.state)
    _zipCode = State(initialValue: profile.zipCode)
    _country = State(initialValue: profile.country)
    _bio = State(initialValue: profile.bio ?? "")
    _website = State(initialValue: profile.website ?? "")
    _linkedIn = State(initialValue: profile.linkedIn ?? "")
    _preferredContactMethod = State(initialValue: profile.preferredContactMethod)
    _isPublicProfile = State(initialValue: profile.isPublicProfile)
    _allowDirectMessages = State(initialValue: profile.allowDirectMessages)
    _showContactInfo = State(initialValue: profile.showContactInfo)
    _profileImageURL = State(initialValue: profile.profileImageURL)
  }
  
  var body: some View {
    NavigationView {
      Form {
        // Profile Image Section
        profileImageSection
        
        // Basic Information
        basicInfoSection
        
        // Company Information
        companyInfoSection
        
        // Contact Information
        contactInfoSection
        
        // Location Information
        locationInfoSection
        
        // Bio Section
        bioSection
        
        // Social Links
        socialLinksSection
        
        // Privacy Settings
        privacySettingsSection
      }
      .navigationTitle("Edit Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            saveProfile()
          }
          .disabled(isLoading || !isFormValid)
        }
      }
      .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
      .onChange(of: selectedImage) { newValue in
        if let newValue = newValue {
          loadImage(from: newValue)
        }
      }
      .alert("Profile Update", isPresented: $showingAlert) {
        Button("OK") { }
      } message: {
        Text(alertMessage)
      }
      .overlay {
        if isLoading {
          ProgressView("Saving...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
        }
      }
    }
  }
  
  // MARK: - Profile Image Section
  private var profileImageSection: some View {
    Section {
      HStack {
        Spacer()
        
        VStack(spacing: 12) {
          AsyncImage(url: URL(string: profileImageURL ?? "")) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Image(systemName: "person.circle.fill")
              .font(.system(size: 60))
              .foregroundColor(.gray)
          }
          .frame(width: 100, height: 100)
          .clipShape(Circle())
          .overlay(
            Circle()
              .stroke(Color.blue, lineWidth: 2)
          )
          
          Button("Change Photo") {
            showingImagePicker = true
          }
          .font(.caption)
        }
        
        Spacer()
      }
      .padding(.vertical, 8)
    }
  }
  
  // MARK: - Basic Information Section
  private var basicInfoSection: some View {
    Section("Basic Information") {
      HStack {
        TextField("First Name", text: $firstName)
        TextField("Last Name", text: $lastName)
      }
      
      TextField("Email", text: $email)
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
      
      TextField("Phone Number", text: $phoneNumber)
        .keyboardType(.phonePad)
    }
  }
  
  // MARK: - Company Information Section
  private var companyInfoSection: some View {
    Section("Company Information") {
      TextField("Company Name", text: $companyName)
      TextField("Job Title", text: $jobTitle)
    }
  }
  
  // MARK: - Contact Information Section
  private var contactInfoSection: some View {
    Section("Contact Preferences") {
      Picker("Preferred Contact Method", selection: $preferredContactMethod) {
        ForEach(ContactMethod.allCases, id: \.self) { method in
          Text(method.rawValue.capitalized).tag(method)
        }
      }
      .pickerStyle(.menu)
    }
  }
  
  // MARK: - Location Information Section
  private var locationInfoSection: some View {
    Section("Location") {
      TextField("Address", text: $address)
      
      HStack {
        TextField("City", text: $city)
        TextField("State", text: $state)
      }
      
      HStack {
        TextField("ZIP Code", text: $zipCode)
        TextField("Country", text: $country)
      }
    }
  }
  
  // MARK: - Bio Section
  private var bioSection: some View {
    Section("About") {
      TextField("Bio", text: $bio, axis: .vertical)
        .lineLimit(3...6)
    }
  }
  
  // MARK: - Social Links Section
  private var socialLinksSection: some View {
    Section("Social Links") {
      TextField("Website", text: $website)
        .keyboardType(.URL)
        .autocapitalization(.none)
      
      TextField("LinkedIn", text: $linkedIn)
        .keyboardType(.URL)
        .autocapitalization(.none)
    }
  }
  
  // MARK: - Privacy Settings Section
  private var privacySettingsSection: some View {
    Section("Privacy Settings") {
      Toggle("Public Profile", isOn: $isPublicProfile)
      Toggle("Allow Direct Messages", isOn: $allowDirectMessages)
      Toggle("Show Contact Information", isOn: $showContactInfo)
    }
  }
  
  // MARK: - Form Validation
  private var isFormValid: Bool {
    !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    isValidEmail(email)
  }
  
  private func isValidEmail(_ email: String) -> Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return emailPredicate.evaluate(with: email)
  }
  
  // MARK: - Image Loading
  private func loadImage(from item: PhotosPickerItem) {
    Task {
      if let data = try? await item.loadTransferable(type: Data.self) {
        // In a real app, you would upload this to a server and get back a URL
        // For now, we'll simulate this with a placeholder URL
        await MainActor.run {
          profileImageURL = "https://example.com/uploaded-image.jpg"
        }
      }
    }
  }
  
  // MARK: - Save Profile
  private func saveProfile() {
    isLoading = true
    
    let updatedProfile = UserProfile(
      id: profile.id,
      firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
      lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
      email: email.trimmingCharacters(in: .whitespacesAndNewlines),
      phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
      companyName: companyName.trimmingCharacters(in: .whitespacesAndNewlines),
      jobTitle: jobTitle.trimmingCharacters(in: .whitespacesAndNewlines),
      address: address.trimmingCharacters(in: .whitespacesAndNewlines),
      city: city.trimmingCharacters(in: .whitespacesAndNewlines),
      state: state.trimmingCharacters(in: .whitespacesAndNewlines),
      zipCode: zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
      country: country.trimmingCharacters(in: .whitespacesAndNewlines),
      bio: bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines),
      website: website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : website.trimmingCharacters(in: .whitespacesAndNewlines),
      linkedIn: linkedIn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : linkedIn.trimmingCharacters(in: .whitespacesAndNewlines),
      preferredContactMethod: preferredContactMethod,
      isPublicProfile: isPublicProfile,
      allowDirectMessages: allowDirectMessages,
      showContactInfo: showContactInfo,
      profileImageURL: profileImageURL
    )
    
    Task {
      do {
        await viewModel.saveProfile()
        await MainActor.run {
          isLoading = false
          alertMessage = "Profile updated successfully!"
          showingAlert = true
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
          }
        }
      } catch {
        await MainActor.run {
          isLoading = false
          alertMessage = "Failed to update profile: \(error.localizedDescription)"
          showingAlert = true
        }
      }
    }
  }
}

// MARK: - Preview
@available(iOS 16.0, *)
struct ProfileEditView_Previews: PreviewProvider {
  @available(iOS 16.0, *)
  static var previews: some View {
    ProfileEditView(
      profile: UserProfile(
        id: "preview-id",
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        phoneNumber: "555-0123",
        companyName: "Acme Corp",
        jobTitle: "Senior Manager",
        address: "123 Main St",
        city: "San Francisco",
        state: "CA",
        zipCode: "94105",
        country: "United States",
        bio: "Experienced professional in the plastics industry.",
        website: "https://johndoe.com",
        linkedIn: "https://linkedin.com/in/johndoe",
        preferredContactMethod: .email,
        isPublicProfile: true,
        allowDirectMessages: true,
        showContactInfo: true,
        profileImageURL: nil
      ),
      viewModel: ProfileViewModel()
    )
  }
}

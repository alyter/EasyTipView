//
//  ProfileCreationWizardView.swift
//  PolyPal
//
//  Created on 2025-07-24.
//

import SwiftUI

struct ProfileCreationWizardView: View {
  @StateObject private var viewModel = ProfileViewModel()
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Progress Bar
        ProgressView(value: viewModel.creationProgress)
          .progressViewStyle(LinearProgressViewStyle(tint: .blue))
          .padding(.horizontal)
          .padding(.top)
        
        // Step Indicator
        HStack {
          Text("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
            .font(.caption)
            .foregroundColor(.secondary)
          
          Spacer()
          
          Text("\(Int(viewModel.creationProgress * 100))% Complete")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        
        // Current Step Content
        TabView(selection: $viewModel.currentStep) {
          BasicInfoStepView(viewModel: viewModel)
            .tag(0)
          
          ContactInfoStepView(viewModel: viewModel)
            .tag(1)
          
          LocationInfoStepView(viewModel: viewModel)
            .tag(2)
          
          PreferencesStepView(viewModel: viewModel)
            .tag(3)
          
          ReviewStepView(viewModel: viewModel)
            .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentStep)
        
        // Navigation Buttons
        HStack {
          Button("Back") {
            viewModel.previousStep()
          }
          .disabled(viewModel.isFirstStep)
          
          Spacer()
          
          if viewModel.isLastStep {
            Button("Complete Profile") {
              completeProfileCreation()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.loadingState == .loading)
          } else {
            Button("Next") {
              viewModel.nextStep()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canProceedToNextStep)
          }
        }
        .padding()
      }
      .navigationTitle("Create Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
        Button("OK") {
          viewModel.clearErrors()
        }
      } message: {
        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
        }
      }
    }
  }
  
  private func completeProfileCreation() {
    viewModel.saveProfile()
    
    // Wait for save completion then dismiss
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      if viewModel.loadingState == .loaded {
        dismiss()
      }
    }
  }
}

// MARK: - Basic Info Step

struct BasicInfoStepView: View {
  @ObservedObject var viewModel: ProfileViewModel
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Basic Information")
            .font(.title2)
            .fontWeight(.semibold)
          
          Text("Let's start with some basic information about you.")
            .font(.body)
            .foregroundColor(.secondary)
        }
        
        VStack(spacing: 16) {
          // Profile Image
          ProfileImageSelectionView(viewModel: viewModel)
          
          // First Name
          VStack(alignment: .leading, spacing: 4) {
            Text("First Name")
              .font(.headline)
            
            TextField("Enter your first name", text: $viewModel.profile.firstName)
              .textFieldStyle(RoundedBorderTextFieldStyle())
          }
          
          // Last Name
          VStack(alignment: .leading, spacing: 4) {
            Text("Last Name")
              .font(.headline)
            
            TextField("Enter your last name", text: $viewModel.profile.lastName)
              .textFieldStyle(RoundedBorderTextFieldStyle())
          }
          
          // Date of Birth
          VStack(alignment: .leading, spacing: 4) {
            Text("Date of Birth")
              .font(.headline)
            
            DatePicker(
              "Select your date of birth",
              selection: Binding(
                get: { viewModel.profile.dateOfBirth ?? Date() },
                set: { viewModel.profile.dateOfBirth = $0 }
              ),
              displayedComponents: .date
            )
            .datePickerStyle(CompactDatePickerStyle())
          }
        }
        
        Spacer(minLength: 100)
      }
      .padding()
    }
  }
}

// MARK: - Contact Info Step

struct ContactInfoStepView: View {
  @ObservedObject var viewModel: ProfileViewModel
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Contact Information")
            .font(.title2)
            .fontWeight(.semibold)
          
          Text("How can people reach you?")
            .font(.body)
            .foregroundColor(.secondary)
        }
        
        VStack(spacing: 16) {
          // Email
          VStack(alignment: .leading, spacing: 4) {
            Text("Email Address")
              .font(.headline)
            
            TextField("Enter your email", text: $viewModel.profile.email)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .keyboardType(.emailAddress)
              .autocapitalization(.none)
          }
          
          // Phone Number
          VStack(alignment: .leading, spacing: 4) {
            Text("Phone Number")
              .font(.headline)
            
            TextField("Enter your phone number", text: $viewModel.profile.phoneNumber)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .keyboardType(.phonePad)
              .onChange(of: viewModel.profile.phoneNumber) { _ in
                viewModel.formatPhoneNumber()
              }
          }
        }
        
        // Validation Errors
        if !viewModel.validationErrors.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            ForEach(viewModel.validationErrors, id: \.self) { error in
              Text(error)
                .font(.caption)
                .foregroundColor(.red)
            }
          }
          .padding(.top)
        }
        
        Spacer(minLength: 100)
      }
      .padding()
    }
  }
}

// MARK: - Location Info Step

struct LocationInfoStepView: View {
  @ObservedObject var viewModel: ProfileViewModel
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Location Information")
            .font(.title2)
            .fontWeight(.semibold)
          
          Text("Where are you located?")
            .font(.body)
            .foregroundColor(.secondary)
        }
        
        VStack(spacing: 16) {
          // Address
          VStack(alignment: .leading, spacing: 4) {
            Text("Street Address")
              .font(.headline)
            
            TextField("Enter your address", text: $viewModel.profile.address)
              .textFieldStyle(RoundedBorderTextFieldStyle())
          }
          
          // City
          VStack(alignment: .leading, spacing: 4) {
            Text("City")
              .font(.headline)
            
            TextField("Enter your city", text: $viewModel.profile.city)
              .textFieldStyle(RoundedBorderTextFieldStyle())
          }
          
          HStack(spacing: 12) {
            // State
            VStack(alignment: .leading, spacing: 4) {
              Text("State")
                .font(.headline)
              
              TextField("State", text: $viewModel.profile.state)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Zip Code
            VStack(alignment: .leading, spacing: 4) {
              Text("Zip Code")
                .font(.headline)
              
              TextField("Zip", text: $viewModel.profile.zipCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            }
          }
        }
        
        Spacer(minLength: 100)
      }
      .padding()
    }
  }
}

// MARK: - Preferences Step

struct PreferencesStepView: View {
  @ObservedObject var viewModel: ProfileViewModel
  @State private var newInterest = ""
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Preferences & Interests")
            .font(.title2)
            .fontWeight(.semibold)
          
          Text("Tell us about your interests (optional).")
            .font(.body)
            .foregroundColor(.secondary)
        }
        
        VStack(spacing: 16) {
          // Interests
          VStack(alignment: .leading, spacing: 8) {
            Text("Interests")
              .font(.headline)
            
            // Add Interest Field
            HStack {
              TextField("Add an interest", text: $newInterest)
                .textFieldStyle(RoundedBorderTextFieldStyle())
              
              Button("Add") {
                if !newInterest.isEmpty {
                  // Note: Interests functionality will be added in future update
                  newInterest = ""
                }
              }
              .disabled(newInterest.isEmpty)
            }
            
            // Interest Tags - Coming Soon
            Text("Interest tags will be available in a future update")
              .font(.caption)
              .foregroundColor(.secondary)
              .italic()
          }
          
          // Bio
          VStack(alignment: .leading, spacing: 4) {
            Text("Bio (Optional)")
              .font(.headline)
            
            TextField("Tell us about yourself", text: Binding(
              get: { viewModel.profile.bio ?? "" },
              set: { viewModel.profile.bio = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
          }
        }
        
        Spacer(minLength: 100)
      }
      .padding()
    }
  }
}

// MARK: - Review Step

struct ReviewStepView: View {
  @ObservedObject var viewModel: ProfileViewModel
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Review Your Profile")
            .font(.title2)
            .fontWeight(.semibold)
          
          Text("Please review your information before completing.")
            .font(.body)
            .foregroundColor(.secondary)
        }
        
        VStack(spacing: 16) {
          ProfileSummaryCard(profile: viewModel.profile)
          
          // Completion Status
          VStack(alignment: .leading, spacing: 8) {
            Text("Profile Completion")
              .font(.headline)
            
            ProgressView(value: viewModel.profileCompletionPercentage)
              .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            Text("\(Int(viewModel.profileCompletionPercentage * 100))% Complete")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding()
          .background(Color.gray.opacity(0.1))
          .cornerRadius(12)
        }
        
        if viewModel.loadingState == .loading {
          HStack {
            Spacer()
            ProgressView("Saving profile...")
            Spacer()
          }
          .padding()
        }
        
        Spacer(minLength: 100)
      }
      .padding()
    }
  }
}

// MARK: - Supporting Views

struct ProfileImageSelectionView: View {
  @ObservedObject var viewModel: ProfileViewModel
  
  var body: some View {
    VStack {
      Button {
        viewModel.presentImagePicker()
      } label: {
        ZStack {
          Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 100, height: 100)
          
          if let image = viewModel.selectedImage {
            Image(uiImage: image)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 100, height: 100)
              .clipShape(Circle())
          } else {
            VStack {
              Image(systemName: "camera.fill")
                .font(.title2)
              Text("Add Photo")
                .font(.caption)
            }
            .foregroundColor(.blue)
          }
        }
      }
      
      if viewModel.isUploadingImage {
        ProgressView(value: viewModel.imageUploadProgress)
          .frame(width: 100)
      }
    }
  }
}

struct ProfileSummaryCard: View {
  let profile: UserProfile
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Basic Info
      VStack(alignment: .leading, spacing: 4) {
        Text("Basic Information")
          .font(.headline)
        
        Text("\(profile.firstName) \(profile.lastName)")
          .font(.body)
        
        if let dateOfBirth = profile.dateOfBirth {
          Text("Born: \(dateOfBirth, style: .date)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      Divider()
      
      // Contact Info
      VStack(alignment: .leading, spacing: 4) {
        Text("Contact Information")
          .font(.headline)
        
        Text(profile.email)
          .font(.body)
        
        Text(profile.phoneNumber)
          .font(.body)
      }
      
      Divider()
      
      // Location
      VStack(alignment: .leading, spacing: 4) {
        Text("Location")
          .font(.headline)
        
        Text("\(profile.address)")
          .font(.body)
        
        Text("\(profile.city), \(profile.state) \(profile.zipCode)")
          .font(.body)
      }
      
      // Interests section will be added in future update
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
  }
}

#Preview {
  ProfileCreationWizardView()
}

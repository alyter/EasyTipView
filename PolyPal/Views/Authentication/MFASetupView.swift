//
//  MFASetupView.swift
//  PolyPal
//
//  Placeholder file - MFA functionality removed
//

import SwiftUI

struct MFASetupView: View {
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Image(systemName: "exclamationmark.triangle")
          .font(.system(size: 60))
          .foregroundColor(.orange)
        
        VStack(spacing: 16) {
          Text("MFA Setup Removed")
            .font(.title2)
            .fontWeight(.semibold)
          
          Text("Multi-factor authentication setup has been removed from this version of the app.")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
        }
        
        Button("Close") {
          dismiss()
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.blue)
        .cornerRadius(12)
        .padding(.horizontal, 24)
      }
      .padding(24)
      .navigationTitle("MFA Setup")
      .navigationBarTitleDisplayMode(.large)
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  MFASetupView()
}

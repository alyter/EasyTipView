import SwiftUI

struct BuyView: View {
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Image(systemName: "cart.fill")
          .font(.system(size: 60))
          .foregroundColor(.blue)
        
        Text("Buy")
          .font(.largeTitle)
          .fontWeight(.bold)
        
        Text("Browse and purchase plastic materials")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        
        Spacer()
        
        Text("Coming Soon")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding()
          .background(Color.gray.opacity(0.1))
          .cornerRadius(8)
      }
      .padding()
      .navigationTitle("Buy")
      .navigationBarTitleDisplayMode(.large)
    }
    .accessibilityLabel("Buy section")
    .accessibilityHint("Browse and purchase plastic materials")
  }
}

#Preview {
  BuyView()
}

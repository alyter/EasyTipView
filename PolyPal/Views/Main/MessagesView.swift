import SwiftUI

struct MessagesView: View {
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Image(systemName: "message.fill")
          .font(.system(size: 60))
          .foregroundColor(.blue)
        
        Text("Messages")
          .font(.largeTitle)
          .fontWeight(.bold)
        
        Text("Chat with buyers and sellers")
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
      .navigationTitle("Messages")
      .navigationBarTitleDisplayMode(.large)
    }
    .accessibilityLabel("Messages section")
    .accessibilityHint("Chat with buyers and sellers")
  }
}

#Preview {
  MessagesView()
}

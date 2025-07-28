import SwiftUI

struct SellView: View {
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Image(systemName: "plus.circle.fill")
          .font(.system(size: 60))
          .foregroundColor(.green)
        
        Text("Sell")
          .font(.largeTitle)
          .fontWeight(.bold)
        
        Text("List and sell your plastic materials")
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
    .navigationTitle("Sell")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    #endif
    }
    .accessibilityLabel("Sell section")
    .accessibilityHint("List and sell your plastic materials")
  }
}

#Preview {
  SellView()
}

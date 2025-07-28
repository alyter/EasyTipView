import SwiftUI

struct FavoritesView: View {
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Image(systemName: "heart.fill")
          .font(.system(size: 60))
          .foregroundColor(.red)
        
        Text("Favorites")
          .font(.largeTitle)
          .fontWeight(.bold)
        
        Text("Your saved items and preferred sellers")
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
    .navigationTitle("Favorites")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    #endif
    }
    .accessibilityLabel("Favorites section")
    .accessibilityHint("Your saved items and preferred sellers")
  }
}

#Preview {
  FavoritesView()
}

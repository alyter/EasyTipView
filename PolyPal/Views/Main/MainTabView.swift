import SwiftUI

struct MainTabView: View {
  @StateObject private var mainViewModel = MainViewModel()
  
  var body: some View {
    TabView(selection: $mainViewModel.selectedTab) {
      BuyView()
        .tabItem {
          Image(systemName: "cart")
          Text("Buy")
        }
        .tag(MainViewModel.TabSection.buy)
      
      SellView()
        .tabItem {
          Image(systemName: "plus.circle")
          Text("Sell")
        }
        .tag(MainViewModel.TabSection.sell)
      
      MessagesView()
        .tabItem {
          Image(systemName: "message")
          Text("Messages")
        }
        .tag(MainViewModel.TabSection.messages)
        .badge(mainViewModel.messageBadgeCount > 0 ? "\(mainViewModel.messageBadgeCount)" : nil)
      
      FavoritesView()
        .tabItem {
          Image(systemName: "heart")
          Text("Favorites")
        }
        .tag(MainViewModel.TabSection.favorites)
        .badge(mainViewModel.favoritesBadgeCount > 0 ? "\(mainViewModel.favoritesBadgeCount)" : nil)
      
      AccountView()
        .tabItem {
          Image(systemName: "person.circle")
          Text("Account")
        }
        .tag(MainViewModel.TabSection.account)
    }
    .accentColor(.blue)
    .onAppear {
      // Configure tab bar appearance
      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = UIColor.systemBackground
      
      UITabBar.appearance().standardAppearance = appearance
      UITabBar.appearance().scrollEdgeAppearance = appearance
    }
  }
}

#Preview {
  MainTabView()
}

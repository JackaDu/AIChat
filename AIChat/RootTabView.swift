import SwiftUI

struct RootTabView: View {
    @StateObject private var appwriteService = AppwriteService()
    @StateObject private var preferencesManager: UserPreferencesManager
    @StateObject private var wrongWordManager: WrongWordManager
    @StateObject private var phoneticService = PhoneticService()
    @State private var showingProfileSetup = false
    
    init() {
        let appwriteService = AppwriteService()
        _appwriteService = StateObject(wrappedValue: appwriteService)
        _preferencesManager = StateObject(wrappedValue: UserPreferencesManager(appwriteService: appwriteService))
        _wrongWordManager = StateObject(wrappedValue: WrongWordManager(appwriteService: appwriteService))
        _phoneticService = StateObject(wrappedValue: PhoneticService())
    }
    
    var body: some View {
        Group {
            if appwriteService.isAuthenticated {
                // User is authenticated, show main app
                if preferencesManager.userPreferences.isFirstLaunch {
                    TextbookSelectionView(userPreferences: $preferencesManager.userPreferences)
                        .environmentObject(preferencesManager)
                        .environmentObject(wrongWordManager)
                        .environmentObject(appwriteService)
                        .environmentObject(phoneticService)
                        .environmentObject(ThemeManager.shared)
                        .themeAware(themeManager: ThemeManager.shared)
                } else if preferencesManager.userPreferences.userNickname.isEmpty {
                    // 用户已登录但未设置个人资料
                    UserProfileSetupView()
                        .environmentObject(preferencesManager)
                        .environmentObject(wrongWordManager)
                        .environmentObject(appwriteService)
                        .environmentObject(phoneticService)
                        .environmentObject(ThemeManager.shared)
                        .themeAware(themeManager: ThemeManager.shared)
                } else {
                    MainTabView()
                        .environmentObject(preferencesManager)
                        .environmentObject(wrongWordManager)
                        .environmentObject(appwriteService)
                        .environmentObject(phoneticService)
                        .environmentObject(ThemeManager.shared)
                        .themeAware(themeManager: ThemeManager.shared)
                }
            } else {
                // User is not authenticated, show login/signup
                AuthenticationView()
                    .environmentObject(appwriteService)
                    .environmentObject(ThemeManager.shared)
                    .themeAware(themeManager: ThemeManager.shared)
            }
        }
        .onAppear {
            // 同步主题管理器与用户偏好设置
            ThemeManager.shared.syncWithUserPreferences(preferencesManager.userPreferences)
        }
    }
}

// MARK: - 主要标签页视图
struct MainTabView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var appwriteService: AppwriteService
    @EnvironmentObject var phoneticService: PhoneticService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            TodayTasksView()
                .environmentObject(preferencesManager)
                .environmentObject(wrongWordManager)
                .environmentObject(appwriteService)
                .environmentObject(phoneticService)
                .environmentObject(ThemeManager.shared)
                .themeAware(themeManager: ThemeManager.shared)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("首页")
                }
                .tag(0)
            
            // 错题本页面
            WrongWordBookView()
                .environmentObject(preferencesManager)
                .environmentObject(wrongWordManager)
                .environmentObject(phoneticService)
                .environmentObject(ThemeManager.shared)
                .themeAware(themeManager: ThemeManager.shared)
                .tabItem {
                    // 更强调错题本功能：书本+警告符号
                    Image(systemName: selectedTab == 1 ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                        .symbolRenderingMode(.hierarchical)
                    Text("错题本")
                }
                .tag(1)
            
            // 我的页面
            ProfileDataView()
                .environmentObject(preferencesManager)
                .environmentObject(wrongWordManager)
                .environmentObject(appwriteService)
                .environmentObject(phoneticService)
                .environmentObject(ThemeManager.shared)
                .themeAware(themeManager: ThemeManager.shared)
                .tabItem {
                    // 用户图标：人物符号
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                        .symbolRenderingMode(.hierarchical)
                    Text("我的")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

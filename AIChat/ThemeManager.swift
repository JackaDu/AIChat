import SwiftUI

// MARK: - 主题管理器
@MainActor
class ThemeManager: ObservableObject {
    @Published var isNightMode: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let nightModeKey = "NightModeEnabled"
    
    // 单例模式
    static let shared = ThemeManager()
    
    private init() {
        // 从UserDefaults加载夜间模式设置
        self.isNightMode = userDefaults.bool(forKey: nightModeKey)
        print("🌙 主题管理器初始化，夜间模式: \(isNightMode)")
    }
    
    func toggleNightMode() {
        isNightMode.toggle()
        saveNightMode()
    }
    
    func setNightMode(_ enabled: Bool) {
        isNightMode = enabled
        saveNightMode()
    }
    
    private func saveNightMode() {
        userDefaults.set(isNightMode, forKey: nightModeKey)
        print("🌙 夜间模式设置已保存: \(isNightMode)")
    }
    
    // 从UserPreferences同步夜间模式设置
    func syncWithUserPreferences(_ userPreferences: UserPreferences) {
        // 只有当UserPreferences中的值确实不同时才更新
        // 避免覆盖用户刚刚设置的值
        if isNightMode != userPreferences.isNightMode {
            print("🌙 ThemeManager同步夜间模式: \(userPreferences.isNightMode)")
            isNightMode = userPreferences.isNightMode
            // 注意：这里不调用saveNightMode()，因为UserPreferences已经保存了
        }
    }
}

// MARK: - 主题颜色扩展
extension Color {
    // 背景颜色
    static var themeBackground: Color {
        UserDefaults.standard.bool(forKey: "NightModeEnabled") ? Color.black : Color.white
    }
    
    static var themeSecondaryBackground: Color {
        UserDefaults.standard.bool(forKey: "NightModeEnabled") ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.gray.opacity(0.05)
    }
    
    static var themeCardBackground: Color {
        UserDefaults.standard.bool(forKey: "NightModeEnabled") ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
    
    // 文字颜色
    static var themePrimaryText: Color {
        UserDefaults.standard.bool(forKey: "NightModeEnabled") ? Color.white : Color.primary
    }
    
    static var themeSecondaryText: Color {
        UserDefaults.standard.bool(forKey: "NightModeEnabled") ? Color.gray : Color.secondary
    }
    
    // 边框颜色
    static var themeBorder: Color {
        UserDefaults.standard.bool(forKey: "NightModeEnabled") ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
    }
    
    // 强调色
    static var themeAccent: Color {
        UserDefaults.standard.bool(forKey: "NightModeEnabled") ? Color.blue.opacity(0.8) : Color.blue
    }
}

// MARK: - 主题视图修饰符
struct ThemeViewModifier: ViewModifier {
    @ObservedObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.isNightMode ? .dark : .light)
    }
}

extension View {
    func themeAware(themeManager: ThemeManager) -> some View {
        self.modifier(ThemeViewModifier(themeManager: themeManager))
    }
}

// MARK: - 夜间模式主题样式
struct NightModeStyle {
    static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let primaryBackground = Color.black
    static let secondaryBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let primaryText = Color.white
    static let secondaryText = Color.gray
    static let border = Color.gray.opacity(0.3)
    static let accent = Color.blue.opacity(0.8)
}

// MARK: - 日间模式主题样式
struct DayModeStyle {
    static let cardBackground = Color.white
    static let primaryBackground = Color.white
    static let secondaryBackground = Color.gray.opacity(0.05)
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let border = Color.gray.opacity(0.2)
    static let accent = Color.blue
}

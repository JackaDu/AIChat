import SwiftUI

// MARK: - 我的页面（简化版）
struct ProfileDataView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var appwriteService: AppwriteService
    @State private var showingSettings = false
    @State private var showingDataReset = false
    @State private var showingLogoutAlert = false
    @State private var showingLearningPlan = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 简化的用户信息
                SimpleUserInfo()
                
                // 核心功能列表
                VStack(spacing: 0) {
                    // 学习规划总览
                    Button {
                        showingLearningPlan = true
                    } label: {
                        SimpleStatRow(
                            icon: "sitemap.fill",
                            title: "学习规划总览",
                            value: "了解学习系统"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // 设置
                    Button {
                        showingSettings = true
                    } label: {
                        SimpleStatRow(
                            icon: "gearshape.fill",
                            title: "设置",
                            value: ""
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // 重置数据
                    Button {
                        showingDataReset = true
                    } label: {
                        SimpleStatRow(
                            icon: "trash.fill",
                            title: "重置数据",
                            value: "",
                            isDestructive: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // 退出登录
                    Button {
                        showingLogoutAlert = true
                    } label: {
                        SimpleStatRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "退出登录",
                            value: "",
                            isDestructive: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .background(themeManager.isNightMode ? NightModeStyle.cardBackground : DayModeStyle.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .background(themeManager.isNightMode ? NightModeStyle.secondaryBackground : DayModeStyle.secondaryBackground)
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingSettings) {
            SimpleSettingsView()
                .environmentObject(preferencesManager)
        }
        .sheet(isPresented: $showingLearningPlan) {
            LearningPlanOverviewView()
                .environmentObject(wrongWordManager)
                .environmentObject(preferencesManager)
        }
        .alert("重置数据", isPresented: $showingDataReset) {
            Button("取消", role: .cancel) { }
            Button("确认重置", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("此操作将清除所有学习数据，包括错题本和学习记录。确定要继续吗？")
        }
        .alert("退出登录", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("确认退出", role: .destructive) {
                logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
        .onAppear {
            syncData()
            // 同步主题管理器与用户偏好设置
            themeManager.setNightMode(preferencesManager.userPreferences.isNightMode)
        }
    }
    
    private func syncData() {
        wrongWordManager.updateTodayReviewWords()
    }
    
    private func resetAllData() {
        wrongWordManager.clearAllData()
    }
    
    private func logout() {
        Task {
            do {
                try await appwriteService.signOut()
                print("✅ 用户已退出登录")
            } catch {
                print("❌ 退出登录失败: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 简化用户信息
struct SimpleUserInfo: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    
    private var userNickname: String {
        let nickname = preferencesManager.userPreferences.userNickname
        return nickname.isEmpty ? "英语学习者" : nickname
    }
    
    private var avatarColor: Color {
        let colorString = preferencesManager.userPreferences.userAvatarColor
        return stringToColor(colorString)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 用户头像
            Circle()
                .fill(avatarColor)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: preferencesManager.userPreferences.userAvatar)
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                )
            
            VStack(spacing: 4) {
                Text(userNickname)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("坚持学习，每天进步")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 30)
    }
    
    // MARK: - 颜色转换辅助方法
    private func stringToColor(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        case "indigo": return .indigo
        case "brown": return .brown
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - 简化统计行
struct SimpleStatRow: View {
    let icon: String
    let title: String
    let value: String
    var isDestructive: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(isDestructive ? .red : .blue)
                .frame(width: 24)
            
            // 标题
            Text(title)
                .font(.body)
                .foregroundStyle(isDestructive ? .red : .primary)
            
            Spacer()
            
            // 数值
            if !value.isEmpty {
                Text(value)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - 简化设置视图
struct SimpleSettingsView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var appwriteService: AppwriteService
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutAlert = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // 夜间模式
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    
                    Text("夜间模式")
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { 
                            return themeManager.isNightMode 
                        },
                        set: { newValue in
                            preferencesManager.userPreferences.isNightMode = newValue
                            themeManager.setNightMode(newValue)
                        }
                    ))
                    .labelsHidden()
                }
                .listRowBackground(Color.clear)
                
                // 发音类型选择
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        
                        Text("发音类型")
                            .font(.body)
                        
                        Spacer()
                    }
                    
                    // 发音类型选择器
                    HStack(spacing: 16) {
                        ForEach(PronunciationType.allCases, id: \.self) { type in
                            Button(action: {
                                preferencesManager.userPreferences.pronunciationType = type
                            }) {
                                HStack(spacing: 8) {
                                    Text(type.emoji)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(type.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // 选中指示器
                                    if preferencesManager.userPreferences.pronunciationType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(preferencesManager.userPreferences.pronunciationType == type ? 
                                              Color.blue.opacity(0.1) : Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(preferencesManager.userPreferences.pronunciationType == type ? 
                                                Color.blue : Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .listRowBackground(Color.clear)
                
                // 注销登录
                Button {
                    showingLogoutAlert = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                            .frame(width: 20)
                        
                        Text("注销登录")
                            .font(.body)
                            .foregroundStyle(.red)
                        
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("注销登录", isPresented: $showingLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("确认注销", role: .destructive) {
                    logout()
                }
            } message: {
                Text("确定要注销登录吗？注销后需要重新登录才能使用应用。")
            }
            .onAppear {
                // 同步主题管理器与用户偏好设置
                themeManager.syncWithUserPreferences(preferencesManager.userPreferences)
            }
        }
    }
    
    private func logout() {
        Task {
            do {
                try await appwriteService.signOut()
                print("✅ 用户已注销登录")
            } catch {
                print("❌ 注销登录失败: \(error.localizedDescription)")
            }
        }
    }
}


// MARK: - 设置行
struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isDestructive ? .red : .blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(isDestructive ? .red : .primary)
                
                Spacer()
                
                Text(value)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileDataView()
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}
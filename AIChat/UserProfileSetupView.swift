import SwiftUI

// MARK: - 用户个人资料设置视图
struct UserProfileSetupView: View {
    @EnvironmentObject var appwriteService: AppwriteService
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var wrongWordManager: WrongWordManager
    
    @State private var nickname = ""
    @State private var selectedAvatarIndex = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // 预设头像选项
    private let avatarOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "person.2.circle.fill",
        "person.3.sequence.fill",
        "graduationcap.fill",
        "book.fill",
        "brain.head.profile",
        "star.circle.fill",
        "heart.circle.fill",
        "leaf.circle.fill",
        "flame.circle.fill",
        "bolt.circle.fill"
    ]
    
    // 头像颜色选项
    private let avatarColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red,
        .yellow, .cyan, .mint, .indigo, .brown, .gray
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 标题区域
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("完善个人资料")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("让我们更好地了解你")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // 昵称输入区域
                VStack(alignment: .leading, spacing: 12) {
                    Text("昵称")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("请输入你的昵称", text: $nickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if nickname.isEmpty {
                        Text("昵称将显示在学习界面中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 头像选择区域
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择头像")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(0..<avatarOptions.count, id: \.self) { index in
                            Button(action: {
                                selectedAvatarIndex = index
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(avatarColors[index % avatarColors.count])
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: avatarOptions[index])
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(selectedAvatarIndex == index ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                // 完成按钮
                VStack(spacing: 16) {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: completeProfileSetup) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isLoading ? "设置中..." : "完成设置")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(nickname.isEmpty ? Color.gray : Color.blue)
                        )
                    }
                    .disabled(nickname.isEmpty || isLoading)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - 完成个人资料设置
    private func completeProfileSetup() {
        guard !nickname.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 更新用户偏好设置
                var updatedPreferences = preferencesManager.userPreferences
                updatedPreferences.userNickname = nickname
                updatedPreferences.userAvatar = avatarOptions[selectedAvatarIndex]
                updatedPreferences.userAvatarColor = colorToString(avatarColors[selectedAvatarIndex % avatarColors.count])
                updatedPreferences.isFirstLaunch = false
                
                // 保存到本地
                await preferencesManager.updateUserPreferences(updatedPreferences)
                
                // 更新 Appwrite 数据库中的用户信息
                try await updateUserProfileInDatabase()
                
                await MainActor.run {
                    isLoading = false
                    // 这里可以触发导航到主界面
                    print("✅ 个人资料设置完成: \(nickname)")
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "设置失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - 更新数据库中的用户信息
    private func updateUserProfileInDatabase() async throws {
        // 这里可以调用 AppwriteService 来更新用户信息
        // 暂时只打印日志
        print("📝 更新用户资料到数据库:")
        print("   昵称: \(nickname)")
        print("   头像: \(avatarOptions[selectedAvatarIndex])")
        print("   头像颜色: \(avatarColors[selectedAvatarIndex % avatarColors.count])")
    }
    
    // MARK: - 颜色转换辅助方法
    private func colorToString(_ color: Color) -> String {
        switch color {
        case .blue: return "blue"
        case .green: return "green"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        case .red: return "red"
        case .yellow: return "yellow"
        case .cyan: return "cyan"
        case .mint: return "mint"
        case .indigo: return "indigo"
        case .brown: return "brown"
        case .gray: return "gray"
        default: return "blue"
        }
    }
}

// MARK: - 预览
#Preview {
    UserProfileSetupView()
        .environmentObject(AppwriteService())
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
        .environmentObject(WrongWordManager())
}

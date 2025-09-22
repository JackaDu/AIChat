import SwiftUI

// MARK: - 设置页面
struct AppSettingsView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("当前教材")
                        Spacer()
                        Text("人教版") // 简化为静态文本
                            .foregroundStyle(.secondary)
                    }
                    
                    NavigationLink {
                        LearningModeSettingsView()
                            .environmentObject(preferencesManager)
                    } label: {
                        HStack {
                            Text("默认学习模式")
                            Spacer()
                            Text(preferencesManager.userPreferences.defaultLearningMode.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        DailyStudyAmountSettingsView()
                            .environmentObject(preferencesManager)
                    } label: {
                        HStack {
                            Text("每日学习量")
                            Spacer()
                            Text(preferencesManager.userPreferences.dailyStudyAmount.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        UnitSelectionView()
                            .environmentObject(preferencesManager)
                    } label: {
                        HStack {
                            Text("学习单元")
                            Spacer()
                            Text(preferencesManager.userPreferences.selectedUnitsDisplayText)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("学习设置")
                }
                
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("应用信息")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 学习模式设置页面
struct LearningModeSettingsView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // 顶部说明
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("选择默认学习模式")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("选择你更喜欢的学习方式。学习时也可以随时切换。")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 40)
                
                // 学习模式选项
                VStack(spacing: 16) {
                    ForEach(LearningDirection.allCases, id: \.self) { mode in
                        LearningDirectionCard(
                            mode: mode,
                            isSelected: preferencesManager.userPreferences.defaultLearningMode == mode
                        ) {
                            preferencesManager.userPreferences.defaultLearningMode = mode
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 底部提示
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.orange)
                        Text("学习时可以随时切换模式")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("系统会记住你的选择，下次学习时自动使用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("学习模式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 学习方向卡片
struct LearningDirectionCard: View {
    let mode: LearningDirection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标区域
                VStack(spacing: 4) {
                    Text(mode.emoji)
                        .font(.system(size: 32))
                    
                    Image(systemName: mode == .recognizeMeaning ? "arrow.right" : "arrow.left")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .blue)
                }
                .frame(width: 60)
                
                // 文字描述
                VStack(alignment: .leading, spacing: 8) {
                    Text(mode.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 选中标识
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .blue : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .blue : .clear, lineWidth: 2)
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}

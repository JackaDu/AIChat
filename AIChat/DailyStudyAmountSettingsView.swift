import SwiftUI

// MARK: - 每日学习量设置界面
struct DailyStudyAmountSettingsView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmount: DailyStudyAmount
    
    init() {
        // 初始化时需要从环境对象获取当前值，这里先设置默认值
        _selectedAmount = State(initialValue: .ten)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(DailyStudyAmount.allCases, id: \.self) { amount in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(amount.emoji)
                                        .font(.title2)
                                    
                                    Text(amount.displayName)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    if selectedAmount == amount {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(amount.color)
                                            .font(.title2)
                                    }
                                }
                                
                                Text(amount.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedAmount = amount
                            }
                        }
                    }
                } header: {
                    Text("选择每日学习量")
                } footer: {
                    Text("选择适合你的学习节奏。学习量会影响每日新词数量和复习安排，可以随时调整。")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("学习建议")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "初学者建议从5-10个单词开始")
                            BulletPoint(text: "根据记忆效果逐步调整学习量")
                            BulletPoint(text: "保持每日学习比增加学习量更重要")
                            BulletPoint(text: "艾宾浩斯曲线会根据学习量智能安排复习")
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("使用提示")
                }
            }
            .navigationTitle("每日学习量")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            selectedAmount = preferencesManager.userPreferences.dailyStudyAmount
        }
    }
    
    private func saveSettings() {
        preferencesManager.updateDailyStudyAmount(selectedAmount)
        dismiss()
    }
}

// MARK: - 项目符号列表项
private struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
                .fontWeight(.bold)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DailyStudyAmountSettingsView()
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}

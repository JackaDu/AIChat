import SwiftUI

// MARK: - 学习量选择界面
struct StudyAmountSelectionView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmount: DailyStudyAmount = .ten
    @State private var showingAnimation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // 顶部说明
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                            .scaleEffect(showingAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showingAnimation)
                        
                        Text("设置学习量")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("选择适合你的每日学习量，\n我们会根据艾宾浩斯记忆曲线安排复习")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 40)
                    
                    // 学习量选项
                    VStack(spacing: 16) {
                        Text("选择每日学习量")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 16) {
                            ForEach(DailyStudyAmount.allCases, id: \.self) { amount in
                                StudyAmountCard(
                                    amount: amount,
                                    isSelected: selectedAmount == amount,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedAmount = amount
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    // 推荐说明
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("个性化推荐")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        Text("初学者建议从5-10个单词开始，随着记忆能力提升可以逐步增加。学习量可以随时在设置中修改。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                    .padding()
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 确认按钮
                    Button {
                        confirmSelection()
                    } label: {
                        HStack {
                            Text("开始学习")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [selectedAmount.color, selectedAmount.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: selectedAmount.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            showingAnimation = true
        }
    }
    
    private func confirmSelection() {
        preferencesManager.updateDailyStudyAmount(selectedAmount)
        dismiss()
    }
}

// MARK: - 学习量卡片
private struct StudyAmountCard: View {
    let amount: DailyStudyAmount
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 图标和数量
                VStack(spacing: 8) {
                    Text(amount.emoji)
                        .font(.system(size: 32))
                    
                    Text(amount.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                
                // 描述
                Text(amount.description)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [amount.color, amount.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemGray6)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? amount.color : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? amount.color.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StudyAmountSelectionView()
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}

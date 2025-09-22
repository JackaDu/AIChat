import Foundation
import SwiftUI

// MARK: - 复习模式枚举
enum ReviewMode: String, CaseIterable, Codable {
    case multipleChoice = "multipleChoice"    // 选择题模式
    case spelling = "spelling"                // 拼写模式
    case selfAssessment = "selfAssessment"    // 自我检测模式
    
    var displayName: String {
        switch self {
        case .multipleChoice:
            return "选择题模式"
        case .spelling:
            return "拼写模式"
        case .selfAssessment:
            return "自我检测模式"
        }
    }
    
    var description: String {
        switch self {
        case .multipleChoice:
            return "快速复习，适合日常回顾"
        case .spelling:
            return "检验真正掌握，需要拼写单词"
        case .selfAssessment:
            return "自我评估，标记记得/不记得"
        }
    }
    
    var emoji: String {
        switch self {
        case .multipleChoice:
            return "🔘"
        case .spelling:
            return "✍️"
        case .selfAssessment:
            return "🤔"
        }
    }
    
    var icon: String {
        switch self {
        case .multipleChoice:
            return "list.bullet.circle"
        case .spelling:
            return "pencil.circle"
        case .selfAssessment:
            return "person.circle"
        }
    }
}

// MARK: - 复习模式管理器
@MainActor
class ReviewModeManager: ObservableObject {
    @Published var selectedMode: ReviewMode {
        didSet {
            UserDefaults.standard.set(selectedMode.rawValue, forKey: "selectedReviewMode")
        }
    }
    
    @Published var showModeSelection = false
    
    init() {
        // 从UserDefaults读取保存的复习模式，默认为选择题模式
        if let savedMode = UserDefaults.standard.string(forKey: "selectedReviewMode"),
           let mode = ReviewMode(rawValue: savedMode) {
            self.selectedMode = mode
        } else {
            self.selectedMode = .multipleChoice
        }
    }
    
    // 切换复习模式
    func switchMode(_ mode: ReviewMode) {
        selectedMode = mode
    }
    
    // 获取当前模式的详细描述
    func getCurrentModeDescription() -> String {
        return selectedMode.description
    }
    
    // 重置为默认模式
    func resetToDefault() {
        selectedMode = .multipleChoice
    }
}

// MARK: - 复习模式选择视图
struct ReviewModeSelectionView: View {
    @ObservedObject var modeManager: ReviewModeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Text("选择复习模式")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("不同的模式适合不同的学习阶段")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // 模式选择列表
                VStack(spacing: 16) {
                    ForEach(ReviewMode.allCases, id: \.self) { mode in
                        ReviewModeCard(
                            mode: mode,
                            isSelected: modeManager.selectedMode == mode,
                            onSelect: {
                                modeManager.switchMode(mode)
                                dismiss()
                            }
                        )
                    }
                }
                
                Spacer()
                
                // 底部说明
                VStack(spacing: 8) {
                    Text("💡 提示")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    
                    Text("您可以在设置中随时更改默认复习模式")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 复习模式卡片
struct ReviewModeCard: View {
    let mode: ReviewMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 模式图标
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? .blue : .blue.opacity(0.1))
                    )
                
                // 模式信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.emoji)
                            .font(.title3)
                        
                        Text(mode.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(isSelected ? .white : .primary)
                    }
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 选择指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .blue : .gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .blue : .gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 复习模式设置视图
struct ReviewModeSettingsView: View {
    @ObservedObject var modeManager: ReviewModeManager
    
    var body: some View {
        VStack(spacing: 20) {
            // 当前模式显示
            VStack(spacing: 16) {
                HStack {
                    Text(modeManager.selectedMode.emoji)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前复习模式")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(modeManager.selectedMode.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(modeManager.selectedMode.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 模式说明
            VStack(spacing: 16) {
                Text("模式说明")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    ForEach(ReviewMode.allCases, id: \.self) { mode in
                        HStack(spacing: 12) {
                            Text(mode.emoji)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
            
            // 操作按钮
            VStack(spacing: 12) {
                Button {
                    modeManager.showModeSelection = true
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("更改复习模式")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    modeManager.resetToDefault()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重置为默认模式")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .navigationTitle("复习模式设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $modeManager.showModeSelection) {
            ReviewModeSelectionView(modeManager: modeManager)
        }
    }
}

#Preview {
    ReviewModeSettingsView(modeManager: ReviewModeManager())
}

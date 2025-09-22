import SwiftUI

// MARK: - 拼写强化内嵌面板
struct SpellingReinforcementPanel: View {
    let wrongWord: StudyWord
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 错误提示
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("答错了")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            // 单词信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("单词:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(wrongWord.word)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("含义:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(wrongWord.meaning)
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 建议文本
            Text("建议通过拼写练习加强记忆")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 操作按钮
            HStack(spacing: 12) {
                // 拒绝按钮
                Button(action: onReject) {
                    Text("跳过")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                // 接受按钮
                Button(action: onAccept) {
                    HStack {
                        Image(systemName: "keyboard")
                            .font(.subheadline)
                        Text("拼写强化")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 会话结束内嵌面板
struct SessionCompletePanel: View {
    let stats: SessionStats
    let wrongWords: [StudyWord]
    let onPracticeWrongWords: () -> Void
    let onReturnHome: () -> Void
    let onNewRound: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 完成标题
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("学习完成")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 统计信息
            VStack(spacing: 12) {
                HStack {
                    SessionStatItem(title: "总词数", value: "\(stats.totalWords)")
                    Spacer()
                    SessionStatItem(title: "正确", value: "\(stats.correctCount)")
                    Spacer()
                    SessionStatItem(title: "错误", value: "\(stats.wrongCount)")
                }
                
                HStack {
                    SessionStatItem(title: "准确率", value: String(format: "%.1f%%", stats.accuracy * 100))
                    Spacer()
                    SessionStatItem(title: "用时", value: formatTime(stats.timeSpent))
                    Spacer()
                    Spacer() // 占位
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 错词提示
            if !wrongWords.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("本轮有 \(wrongWords.count) 个错词")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            // 操作按钮
            VStack(spacing: 12) {
                // 练错题按钮（主要操作）
                if !wrongWords.isEmpty {
                    Button(action: onPracticeWrongWords) {
                        HStack {
                            Image(systemName: "keyboard")
                                .font(.subheadline)
                            Text("练错题")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                
                // 次要操作按钮
                HStack(spacing: 12) {
                    Button(action: onNewRound) {
                        Text("再来一轮")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Button(action: onReturnHome) {
                        Text("回首页")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 统计项组件
struct SessionStatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 内嵌面板容器
struct EmbeddedPanelContainer: View {
    @ObservedObject var modeManager: UnifiedModeManager
    let wrongWord: StudyWord?
    
    var body: some View {
        ZStack {
            if modeManager.showEmbeddedPanel {
                // 背景遮罩
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // 点击背景关闭面板
                        modeManager.hideEmbeddedPanel()
                    }
                
                // 面板内容
                VStack {
                    Spacer()
                    
                    switch modeManager.embeddedPanelType {
                    case .spellingReinforcement:
                        if let word = wrongWord {
                            SpellingReinforcementPanel(
                                wrongWord: word,
                                onAccept: {
                                    modeManager.acceptSpellingReinforcement()
                                },
                                onReject: {
                                    modeManager.rejectSpellingReinforcement()
                                }
                            )
                        }
                        
                    case .sessionComplete:
                        if let context = modeManager.navigationContext,
                           let stats = context.sessionStats {
                            SessionCompletePanel(
                                stats: stats,
                                wrongWords: context.wrongWords,
                                onPracticeWrongWords: {
                                    modeManager.practiceWrongWords()
                                },
                                onReturnHome: {
                                    modeManager.returnToHome()
                                },
                                onNewRound: {
                                    modeManager.startNewRound()
                                }
                            )
                        }
                        
                    case .none, .wordDetail:
                        EmptyView()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: modeManager.showEmbeddedPanel)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SpellingReinforcementPanel(
            wrongWord: StudyWord(
                word: "example",
                meaning: "n.例子;实例",
                example: "This is an example sentence.",
                difficulty: "1",
                category: "general",
                grade: .high1,
                source: .imported,
                isCorrect: false,
                answerTime: 0,
                preGeneratedOptions: [],
                misleadingChineseOptions: [],
                misleadingEnglishOptions: []
            ),
            onAccept: {},
            onReject: {}
        )
        
        SessionCompletePanel(
            stats: SessionStats(
                totalWords: 10,
                correctCount: 8,
                wrongCount: 2,
                accuracy: 0.8,
                timeSpent: 125
            ),
            wrongWords: [],
            onPracticeWrongWords: {},
            onReturnHome: {},
            onNewRound: {}
        )
    }
    .padding()
}

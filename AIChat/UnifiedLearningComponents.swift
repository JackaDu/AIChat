import SwiftUI

// MARK: - 统一学习界面组件

/// 统一的学习进度头部
struct LearningProgressHeader: View {
    let title: String
    let subtitle: String
    let currentIndex: Int
    let totalCount: Int
    let progressColor: Color
    
    init(
        title: String,
        subtitle: String = "",
        currentIndex: Int,
        totalCount: Int,
        progressColor: Color = .blue
    ) {
        self.title = title
        self.subtitle = subtitle
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.progressColor = progressColor
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题区域
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // 进度数字
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(currentIndex + 1) / \(totalCount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(progressColor)
                    
                    Text("完成进度")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 统一的进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor.opacity(0.1))
                        .frame(height: 8)
                    
                    // 进度
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(max(totalCount, 1)),
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

/// 统一的学习卡片
struct UnifiedLearningCard: View {
    let content: String
    let subtitle: String?
    let phonetic: String?
    let pronunciationType: PronunciationType?
    let cardColor: Color
    let isHighlighted: Bool
    let onPlayAudio: (() -> Void)?
    let onCardTap: (() -> Void)? // 新增卡片点击回调
    
    init(
        content: String,
        subtitle: String? = nil,
        phonetic: String? = nil,
        pronunciationType: PronunciationType? = nil,
        cardColor: Color = .blue,
        isHighlighted: Bool = false,
        onPlayAudio: (() -> Void)? = nil,
        onCardTap: (() -> Void)? = nil // 新增参数
    ) {
        self.content = content
        self.subtitle = subtitle
        self.phonetic = phonetic
        self.pronunciationType = pronunciationType
        self.cardColor = cardColor
        self.isHighlighted = isHighlighted
        self.onPlayAudio = onPlayAudio
        self.onCardTap = onCardTap
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 主要内容
            Text(content)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // 音标和发音按钮
            if let phonetic = phonetic {
                HStack(spacing: 8) {
                    // 发音类型显示（国旗）
                    if let pronunciationType = pronunciationType {
                        Text(pronunciationType.emoji)
                            .font(.title3)
                            .scaleEffect(1.2)
                    }
                    
                    Text("[\(phonetic)]")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                    
                    if let onPlayAudio = onPlayAudio {
                        Button(action: onPlayAudio) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // 副标题
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isHighlighted ? cardColor : cardColor.opacity(0.3),
                            lineWidth: isHighlighted ? 2 : 1
                        )
                )
        )
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .shadow(
            color: cardColor.opacity(isHighlighted ? 0.2 : 0.1),
            radius: isHighlighted ? 12 : 8,
            x: 0,
            y: isHighlighted ? 6 : 4
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
        .onTapGesture {
            // 卡片点击处理
            if let onCardTap = onCardTap {
                onCardTap()
            }
        }
    }
}

/// 统一的答案按钮组
struct UnifiedAnswerButtons: View {
    let primaryText: String
    let secondaryText: String
    let primaryColor: Color
    let secondaryColor: Color
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    let isEnabled: Bool
    
    init(
        primaryText: String,
        secondaryText: String,
        primaryColor: Color = .green,
        secondaryColor: Color = .red,
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void,
        isEnabled: Bool = true
    ) {
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 次要按钮（通常是"不认识"）
            Button(action: secondaryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                    
                    Text(secondaryText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(secondaryColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(!isEnabled)
            .buttonStyle(PlainButtonStyle())
            
            // 主要按钮（通常是"认识"）
            Button(action: primaryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    
                    Text(primaryText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [primaryColor, primaryColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(!isEnabled)
            .buttonStyle(PlainButtonStyle())
        }
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

/// 统一的选择题选项
struct UnifiedOptionButton: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool?
    let showResult: Bool
    let action: () -> Void
    
    private var buttonColor: Color {
        if showResult {
            if isCorrect == true {
                return .green
            } else if isSelected && isCorrect == false {
                return .red
            } else {
                return .gray
            }
        } else if isSelected {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var textColor: Color {
        if showResult && (isCorrect == true || (isSelected && isCorrect == false)) {
            return .white
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showResult {
                    Image(systemName: isCorrect == true ? "checkmark.circle.fill" : isSelected ? "xmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(textColor)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        showResult ? buttonColor : (isSelected ? buttonColor : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                showResult ? Color.clear : (isSelected ? buttonColor : Color(.systemGray4)),
                                lineWidth: 1
                            )
                    )
            )
        }
        .disabled(showResult)
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showResult)
    }
}

/// 统一的结果反馈
struct UnifiedFeedbackView: View {
    let isCorrect: Bool
    let message: String
    let nextAction: () -> Void
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 反馈图标和消息
            VStack(spacing: 12) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(isCorrect ? .green : .red)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isVisible)
                
                Text(message)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3).delay(0.2), value: isVisible)
            }
            
            // 继续按钮
            Button(action: nextAction) {
                HStack(spacing: 8) {
                    Text("继续")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4), value: isVisible)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

/// 统一的完成视图
struct UnifiedCompletionView: View {
    let title: String
    let subtitle: String
    let totalWords: Int
    let correctCount: Int
    let accuracy: Double
    let onRestart: () -> Void
    let onBack: () -> Void
    
    private var performanceIcon: String {
        if accuracy >= 0.8 {
            return "star.fill"
        } else if accuracy >= 0.6 {
            return "checkmark.circle.fill"
        } else {
            return "arrow.clockwise.circle.fill"
        }
    }
    
    private var performanceColor: Color {
        if accuracy >= 0.8 {
            return .yellow
        } else if accuracy >= 0.6 {
            return .green
        } else {
            return .orange
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // 完成图标
            VStack(spacing: 16) {
                Image(systemName: performanceIcon)
                    .font(.system(size: 64))
                    .foregroundStyle(performanceColor)
                
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 统计信息
            VStack(spacing: 16) {
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(totalWords)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("总单词")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(correctCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        
                        Text("答对")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(Int(accuracy * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(performanceColor)
                        
                        Text("正确率")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // 主要操作按钮
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "house")
                        .font(.title3)
                    
                    Text("返回首页")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 次要操作
            Button(action: onRestart) {
                Text("继续学习")
                    .font(.body)
                    .foregroundStyle(.blue)
                    .padding(.vertical, 8)
            }
        }
        .padding(32)
    }
}

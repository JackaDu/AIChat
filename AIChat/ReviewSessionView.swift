import SwiftUI

// MARK: - 复习会话视图
struct ReviewSessionView: View {
    @ObservedObject var wrongWordManager: WrongWordManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentWordIndex = 0
    @State private var reviewWords: [WrongWord] = []
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    @State private var showingOptions = false
    @State private var selectedAnswer: String?
    @State private var isAnswerCorrect: Bool?
    @State private var showingResult = false
    @State private var currentOptions: [String] = []
    @State private var showingExitConfirmation = false
    @State private var showingCompletionView = false
    @State private var cardFlashColor: Color = .clear
    @State private var memoryProgress: Double = 0.0
    @State private var showingCelebration = false
    @State private var cardScale: CGFloat = 1.0
    @State private var cardRotation: Double = 0.0
    @State private var showingParticles = false
    @State private var progressAnimation: Bool = false
    @State private var scoreAnimation: Bool = false
    @State private var comboCount: Int = 0
    @State private var lastAnswerCorrect: Bool? = nil
    
    var currentWord: WrongWord? {
        guard currentWordIndex < reviewWords.count else { return nil }
        return reviewWords[currentWordIndex]
    }
    
    var isSessionComplete: Bool {
        currentWordIndex >= reviewWords.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if showingCompletionView {
                    ReviewCompletionView(
                        totalWords: reviewWords.count,
                        correctAnswers: correctAnswers,
                        incorrectAnswers: incorrectAnswers,
                        memoryProgress: memoryProgress,
                        onDismiss: {
                            dismiss()
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // 顶部进度条
                        ReviewProgressBar(
                            current: currentWordIndex + 1,
                            total: reviewWords.count,
                            progress: Double(currentWordIndex) / Double(max(reviewWords.count, 1))
                        )
                        .padding()
                        
                        Spacer()
                        
                        // 单词卡片区域
                        if let word = currentWord {
                            WordReviewCard(
                                word: word,
                                showingOptions: $showingOptions,
                                selectedAnswer: $selectedAnswer,
                                isAnswerCorrect: $isAnswerCorrect,
                                showingResult: $showingResult,
                                options: currentOptions,
                                flashColor: cardFlashColor,
                                cardScale: cardScale,
                                cardRotation: cardRotation,
                                onShowAnswers: {
                                    generateOptionsForCurrentWord()
                                },
                                onAnswerSelected: { answer in
                                    handleAnswerSelection(answer)
                                }
                            )
                            .padding(.horizontal)
                            // 暂时移除粒子效果，等待后续实现
                        }
                        
                        Spacer()
                        
                        // 底部操作区
                        ReviewActionButtons(
                            showingOptions: showingOptions,
                            showingResult: showingResult,
                            isAnswerCorrect: isAnswerCorrect,
                            onNext: {
                                moveToNextWord()
                            },
                            onShowAnswers: {
                                generateOptionsForCurrentWord()
                            }
                        )
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("退出") {
                        showingExitConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("单词复习")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .alert("确认退出？", isPresented: $showingExitConfirmation) {
                Button("继续复习", role: .cancel) {}
                Button("退出", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("退出后当前进度将会丢失")
            }
        }
        .onAppear {
            initializeReviewSession()
        }
        .onChange(of: isSessionComplete) { _, completed in
            if completed {
                showingCompletionView = true
                updateMemoryProgress()
            }
        }
    }
    
    // MARK: - 初始化复习会话
    private func initializeReviewSession() {
        reviewWords = wrongWordManager.todayReviewWords
        currentWordIndex = 0
        correctAnswers = 0
        incorrectAnswers = 0
        memoryProgress = calculateInitialMemoryProgress()
    }
    
    // MARK: - 生成当前单词的选项
    private func generateOptionsForCurrentWord() {
        guard let word = currentWord else { return }
        
        // 正确答案
        let correctAnswer = word.meaning
        
        // 生成3个错误选项（这里使用简单的模拟数据，实际可以调用AI接口）
        let wrongAnswers = generateWrongAnswers(for: word)
        
        // 混合并随机排列
        var allOptions = [correctAnswer] + wrongAnswers
        allOptions.shuffle()
        
        currentOptions = allOptions
        showingOptions = true
    }
    
    // MARK: - 生成错误答案（模拟）
    private func generateWrongAnswers(for word: WrongWord) -> [String] {
        let commonWrongAnswers = [
            "完成", "开始", "结束", "继续", "停止", "发现", "创造", "破坏", "建立", "删除",
            "增加", "减少", "改变", "保持", "移动", "留下", "到达", "离开", "进入", "出去",
            "上升", "下降", "飞行", "游泳", "跑步", "走路", "站立", "坐下", "躺下", "睡觉",
            "醒来", "吃饭", "喝水", "学习", "工作", "玩耍", "休息", "思考", "说话", "听取",
            "看见", "听到", "感觉", "闻到", "尝试", "成功", "失败", "赢得", "失去", "获得"
        ]
        
        // 过滤掉正确答案，随机选择3个
        let filtered = commonWrongAnswers.filter { $0 != word.meaning }
        return Array(filtered.shuffled().prefix(3))
    }
    
    // MARK: - 处理答案选择
    private func handleAnswerSelection(_ answer: String) {
        guard let word = currentWord else { return }
        
        selectedAnswer = answer
        let correct = answer == word.meaning
        isAnswerCorrect = correct
        showingResult = true
        lastAnswerCorrect = correct
        
        // 更新统计和连击
        if correct {
            correctAnswers += 1
            comboCount += 1
            cardFlashColor = .green
            wrongWordManager.recordCorrectAnswer(for: word)
        } else {
            incorrectAnswers += 1
            comboCount = 0  // 重置连击
            cardFlashColor = .red
            wrongWordManager.recordIncorrectAnswer(for: word)
        }
        
        // 记录到日进度
        // dailyProgressManager.recordReviewCompleted() // 已移除DailyProgressManager
        
        // 游戏化动画序列
        playAnswerAnimations(isCorrect: correct)
    }
    
    // MARK: - 播放答案动画
    private func playAnswerAnimations(isCorrect: Bool) {
        // 1. 立即的卡片动画
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            cardScale = isCorrect ? 1.1 : 0.95
            cardRotation = isCorrect ? 5 : -5
        }
        
        // 2. 粒子效果
        showingParticles = true
        
        // 3. 进度动画
        if isCorrect {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                progressAnimation.toggle()
            }
        }
        
        // 4. 连击庆祝
        if isCorrect && comboCount >= 3 {
            showingCelebration = true
            // 连击振动效果
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
        
        // 5. 恢复动画（1秒后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                cardFlashColor = .clear
                cardScale = 1.0
                cardRotation = 0.0
            }
        }
        
        // 6. 清理效果（2秒后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingParticles = false
            showingCelebration = false
        }
    }
    
    // MARK: - 移动到下一个单词
    private func moveToNextWord() {
        guard currentWordIndex < reviewWords.count else { return }
        
        currentWordIndex += 1
        showingOptions = false
        selectedAnswer = nil
        isAnswerCorrect = nil
        showingResult = false
        currentOptions = []
        cardFlashColor = .clear
    }
    
    // MARK: - 计算初始记忆进度
    private func calculateInitialMemoryProgress() -> Double {
        let totalWords = wrongWordManager.wrongWords.count
        let masteredWords = wrongWordManager.masteredWordsCount
        guard totalWords > 0 else { return 0 }
        return Double(masteredWords) / Double(totalWords) * 100
    }
    
    // MARK: - 更新记忆进度
    private func updateMemoryProgress() {
        let newProgress = calculateInitialMemoryProgress()
        memoryProgress = newProgress
    }
}

// MARK: - 复习进度条
struct ReviewProgressBar: View {
    let current: Int
    let total: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("进度")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(current) / \(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - 单词复习卡片
struct WordReviewCard: View {
    let word: WrongWord
    @Binding var showingOptions: Bool
    @Binding var selectedAnswer: String?
    @Binding var isAnswerCorrect: Bool?
    @Binding var showingResult: Bool
    let options: [String]
    let flashColor: Color
    let cardScale: CGFloat
    let cardRotation: Double
    let onShowAnswers: () -> Void
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 单词显示
            VStack(spacing: 16) {
                Text(word.word)
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundStyle(.primary)
                
                Text("回忆这个单词的中文意思")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 选择题选项
            if showingOptions {
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        AnswerOptionButton(
                            text: option,
                            isSelected: selectedAnswer == option,
                            isCorrect: showingResult ? option == word.meaning : nil,
                            isIncorrect: showingResult ? (selectedAnswer == option && option != word.meaning) : nil
                        ) {
                            if !showingResult {
                                onAnswerSelected(option)
                            }
                        }
                    }
                }
            }
            
            // 结果反馈
            if showingResult, let correct = isAnswerCorrect {
                ResultFeedbackView(
                    isCorrect: correct,
                    correctAnswer: word.meaning,
                    selectedAnswer: selectedAnswer
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(flashColor.opacity(0.6), lineWidth: flashColor == .clear ? 0 : 3)
                )
        )
        .overlay(
            // 闪烁效果
            RoundedRectangle(cornerRadius: 16)
                .fill(flashColor.opacity(0.2))
                .animation(.easeInOut(duration: 0.5), value: flashColor)
        )
    }
}

// MARK: - 答案选项按钮
struct AnswerOptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let isIncorrect: Bool?
    let action: () -> Void
    
    var backgroundColor: Color {
        if let isCorrect = isCorrect, isCorrect {
            return .green
        } else if let isIncorrect = isIncorrect, isIncorrect {
            return .red
        } else if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
    
    var foregroundColor: Color {
        if isCorrect == true || isIncorrect == true {
            return .white
        } else if isSelected {
            return .blue
        } else {
            return .primary
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(foregroundColor)
                
                Spacer()
                
                if isCorrect == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                } else if isIncorrect == true {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 结果反馈视图
struct ResultFeedbackView: View {
    let isCorrect: Bool
    let correctAnswer: String
    let selectedAnswer: String?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isCorrect ? .green : .red)
                
                Text(isCorrect ? "答对了！" : "答错了")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isCorrect ? .green : .red)
            }
            
            if isCorrect {
                Text("很好！记忆延长到 7 天后再复习。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 4) {
                    Text("正确答案：\(correctAnswer)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("没关系，明天会再次提醒你。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? .green.opacity(0.1) : .red.opacity(0.1))
        )
    }
}

// MARK: - 复习操作按钮
struct ReviewActionButtons: View {
    let showingOptions: Bool
    let showingResult: Bool
    let isAnswerCorrect: Bool?
    let onNext: () -> Void
    let onShowAnswers: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if !showingOptions {
                Button(action: onShowAnswers) {
                    Text("显示选项")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else if showingResult {
                Button(action: onNext) {
                    Text("下一个")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - 复习完成视图
struct ReviewCompletionView: View {
    let totalWords: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let memoryProgress: Double
    let onDismiss: () -> Void
    
    private var accuracy: Double {
        guard totalWords > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalWords) * 100
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // 庆祝图标
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce, value: Date())
            
            VStack(spacing: 16) {
                Text("复习完成！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("恭喜你完成了今日的复习任务")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 统计卡片
            VStack(spacing: 20) {
                ReviewStatCard(title: "复习单词", value: "\(totalWords)", subtitle: "个", color: .blue, icon: "book.fill")
                
                HStack(spacing: 16) {
                    ReviewStatCard(title: "答对", value: "\(correctAnswers)", subtitle: "个", color: .green, icon: "checkmark.circle.fill")
                    ReviewStatCard(title: "答错", value: "\(incorrectAnswers)", subtitle: "个", color: .red, icon: "xmark.circle.fill")
                }
                
                ReviewStatCard(title: "正确率", value: "\(Int(accuracy))", subtitle: "%", color: .purple, icon: "target")
            }
            
            // 记忆进度
            VStack(spacing: 12) {
                Text("记忆健康度")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: memoryProgress / 100)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 2), value: memoryProgress)
                    
                    Text("\(Int(memoryProgress))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
            }
            
            // 完成按钮
            Button(action: onDismiss) {
                Text("完成")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

// MARK: - 复习统计卡片
struct ReviewStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

import SwiftUI

struct WrongWordQuizView: View {
    @EnvironmentObject var manager: WrongWordManager
    @EnvironmentObject var wordDataManager: WordDataManager
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    let filterWords: [WrongWord]? // 可选的过滤单词列表
    let preloadedOptions: [String: [String]]? // 预加载的选项字典 [word: [options]]
    
    // 构造函数
    init(filterWords: [WrongWord]? = nil, preloadedOptions: [String: [String]]? = nil) {
        self.filterWords = filterWords
        self.preloadedOptions = preloadedOptions
    }
    
    @State private var currentWordIndex = 0
    @State private var showingOptions = false
    @State private var selectedOption: String = ""
    @State private var isAnswerCorrect = false
    @State private var hasAnswered = false
    @State private var quizWords: [WrongWord] = []
    @State private var userAnswers: [QuizResult] = []
    @State private var showingResult = false
    @State private var isGeneratingOptions = false
    @State private var currentOptions: [String] = []
    @State private var selectedLearningMode: LearningDirection = .recognizeMeaning
    // 每个单词缓存两套选项：英译中与中译英
    @State private var optionsCache: [String: [LearningDirection: [String]]] = [:]
    // 自评：是否会
    @State private var userKnows: Bool? = nil
    
    private let confusionGenerator = AIConfusionGenerator(apiKey: AppConfig.shared.openAIAPIKey)
    
    var currentWord: WrongWord? {
        guard currentWordIndex < quizWords.count else { return nil }
        return quizWords[currentWordIndex]
    }
    
    var isQuizComplete: Bool {
        currentWordIndex >= quizWords.count
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isQuizComplete {
                    completionView
                } else if let word = currentWord {
                    quizContentView(for: word)
                } else {
                    loadingView
                }
            }
            .navigationTitle(filterWords != nil ? "紧急复习" : "错题复习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupQuiz()
        }
    }
    
    // MARK: - View Components
    
    private var completionView: some View {
        QuizCompletionView(
            results: userAnswers,
            manager: manager,
            onRestart: restartQuiz,
            onDismiss: { dismiss() }
        )
    }
    
    private var loadingView: some View {
        ProgressView("加载中...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func quizContentView(for word: WrongWord) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // 使用统一的进度头部
                LearningProgressHeader(
                    title: filterWords != nil ? "紧急复习" : "错题复习",
                    subtitle: filterWords != nil ? "避免遗忘关键单词" : "巩固错题记忆",
                    currentIndex: currentWordIndex,
                    totalCount: quizWords.count
                )
                
                // 学习模式切换按钮
                HStack {
                    Spacer()
                    
                    Button(action: {
                        switchLearningMode()
                    }) {
                        HStack(spacing: 8) {
                            Text(selectedLearningMode.emoji)
                            Text(selectedLearningMode.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.2.circlepath")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Spacer()
                }
                
                // 使用统一的学习卡片 - 根据当前选择的学习方向显示不同内容
                UnifiedLearningCard(
                    content: selectedLearningMode == .recognizeMeaning ? word.word : word.meaning,
                    subtitle: hasAnswered ? 
                        (selectedLearningMode == .recognizeMeaning ? word.meaning : word.word) : 
                        (selectedLearningMode == .recognizeMeaning ? "选择正确的中文含义" : "选择正确的英文单词"),
                    phonetic: selectedLearningMode == .recognizeMeaning ? PhoneticService().getPhoneticSymbol(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) : nil,
                    pronunciationType: selectedLearningMode == .recognizeMeaning ? preferencesManager.userPreferences.pronunciationType : nil,
                    onPlayAudio: selectedLearningMode == .recognizeMeaning ? {
                        PhoneticService().playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                    } : nil
                )
                
                if !showingOptions && !hasAnswered {
                    // 与智能学习保持一致：先让用户自评“会/不会”
                    VStack(spacing: 16) {
                        Text("你会这个单词吗？")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        UnifiedAnswerButtons(
                            primaryText: "认识",
                            secondaryText: "不认识",
                            primaryColor: .green,
                            secondaryColor: .red,
                            primaryAction: {
                                userKnows = true
                                generateOptions(for: word)
                            },
                            secondaryAction: {
                                userKnows = false
                                // 直接判为错误并进入反馈
                                handleDontKnow(for: word)
                            }
                        )
                    }
                }
                
                if showingOptions && !hasAnswered {
                    optionsGrid
                }
                
                if showingResult {
                    feedbackView
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
    
    private func generateOptionsButton(for word: WrongWord) -> some View {
        Button {
            generateOptions(for: word)
        } label: {
            HStack {
                if isGeneratingOptions {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "list.bullet")
                }
                Text(isGeneratingOptions ? "生成选项中..." : "选择题模式")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isGeneratingOptions)
    }
    
    private var optionsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(currentOptions, id: \.self) { option in
                UnifiedOptionButton(
                    option: option,
                    isSelected: selectedOption == option,
                    isCorrect: nil,
                    showResult: false,
                    action: {
                        selectAnswer(option)
                    }
                )
            }
        }
    }
    
    private var feedbackView: some View {
        UnifiedLearningFeedback(
            isCorrect: isAnswerCorrect,
            memoryStrength: calculateMemoryStrength(),
            streakCount: calculateStreakCount(),
            onComplete: {
                nextWord()
            }
        )
        .padding(.vertical)
    }
    
    // MARK: - Helper Methods
    
    private func setupQuiz() {
        if let filterWords = filterWords {
            quizWords = filterWords
        } else {
            // 获取需要复习的错题
            let urgentWords = manager.wrongWords.filter { word in
                guard let lastReviewDate = word.reviewDates.last else { return true }
                let daysSinceReview = Calendar.current.dateComponents([.day], from: lastReviewDate, to: Date()).day ?? 0
                return daysSinceReview >= word.reviewCount + 1
            }
            quizWords = Array(urgentWords.prefix(10)) // 限制数量
        }
        
        // 初始化学习模式（使用第一个单词的学习方向，如果有的话）
        if let firstWord = quizWords.first {
            selectedLearningMode = firstWord.learningDirection
        }
        
        // 重置状态
        currentWordIndex = 0
        userAnswers.removeAll()
        resetCurrentWord()
        
        // 如果有预加载选项，且学习模式与第一个单词的原始方向一致，才立即显示选项
        if let preloadedOptions = preloadedOptions,
           let firstWord = quizWords.first,
           let options = preloadedOptions[firstWord.word],
           selectedLearningMode == firstWord.learningDirection {
            // 写入缓存
            var map = optionsCache[firstWord.word] ?? [:]
            map[firstWord.learningDirection] = options
            optionsCache[firstWord.word] = map
            // 显示
            currentOptions = options
            showingOptions = true
        }
    }
    
    private func resetCurrentWord() {
        showingOptions = false
        selectedOption = ""
        isAnswerCorrect = false
        hasAnswered = false
        showingResult = false
        currentOptions.removeAll()
    }
    
    private func generateOptions(for word: WrongWord) {
        guard !isGeneratingOptions else { return }
        
        isGeneratingOptions = true
        
        // 1) 优先使用缓存
        if let cached = optionsCache[word.word]?[selectedLearningMode] {
            self.currentOptions = cached
            self.showingOptions = true
            self.isGeneratingOptions = false
            return
        }
        
        // 如果有预加载的选项，且学习模式与单词原始方向一致，才使用它们
        if let preloadedOptions = preloadedOptions,
           let options = preloadedOptions[word.word],
           selectedLearningMode == word.learningDirection {
            // 写入缓存
            var map = optionsCache[word.word] ?? [:]
            map[word.learningDirection] = options
            optionsCache[word.word] = map
            // 使用预加载
            self.currentOptions = options
            self.showingOptions = true
            self.isGeneratingOptions = false
            return
        }
        
        // 格式化正确答案（根据学习方向决定格式）
        let formattedCorrectAnswer = formatCorrectAnswer(for: word)
        
        // 获取Excel中的预生成选项
        let preGeneratedOptions = self.getPreGeneratedOptions(for: word, learningDirection: selectedLearningMode)
        
        // 否则生成新选项
        Task {
            do {
                let options = try await confusionGenerator.generateConfusionOptions(
                    for: selectedLearningMode == .recognizeMeaning ? word.word : word.meaning,
                    correctAnswer: formattedCorrectAnswer,
                    learningDirection: selectedLearningMode,
                    textbook: word.textbookSource?.textbookVersion.rawValue,
                    coursebook: word.textbookSource?.courseBook,
                    unit: word.textbookSource?.unit.shortName,
                    phonetic: PhoneticService().getPhoneticSymbol(for: word.word),
                    partOfSpeech: word.partOfSpeech?.rawValue,
                    preGeneratedOptions: preGeneratedOptions
                )
                
                await MainActor.run {
                    // 写入当前模式缓存
                    var map = optionsCache[word.word] ?? [:]
                    map[selectedLearningMode] = options
                    optionsCache[word.word] = map
                    self.currentOptions = options
                    self.showingOptions = true
                    self.isGeneratingOptions = false
                }
                
                // 2) 在后台为另一模式预生成并缓存（不打断当前显示）
                let otherMode: LearningDirection = (selectedLearningMode == .recognizeMeaning) ? .recallWord : .recognizeMeaning
                if optionsCache[word.word]?[otherMode] == nil {
                    Task {
                        let otherCorrect = (otherMode == .recognizeMeaning)
                            ? formatAnswerWithPartOfSpeech(word.meaning, partOfSpeech: word.partOfSpeech)
                            : word.word
                        do {
                            let otherPreGeneratedOptions = self.getPreGeneratedOptions(for: word, learningDirection: otherMode)
                            let otherOptions = try await confusionGenerator.generateConfusionOptions(
                                for: otherMode == .recognizeMeaning ? word.word : word.meaning,
                                correctAnswer: otherCorrect,
                                learningDirection: otherMode,
                                textbook: word.textbookSource?.textbookVersion.rawValue,
                                coursebook: word.textbookSource?.courseBook,
                                unit: word.textbookSource?.unit.shortName,
                                phonetic: PhoneticService().getPhoneticSymbol(for: word.word),
                                partOfSpeech: word.partOfSpeech?.rawValue,
                                preGeneratedOptions: otherPreGeneratedOptions
                            )
                            await MainActor.run {
                                var inner = optionsCache[word.word] ?? [:]
                                inner[otherMode] = otherOptions
                                optionsCache[word.word] = inner
                            }
                        } catch {
                            // 忽略后台预生成错误
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    // 使用默认选项
                    let formattedAnswer = self.formatCorrectAnswer(for: word)
                    let defaultOptions = self.selectedLearningMode == .recognizeMeaning ? 
                        ["选项A", "选项B", "选项C"] : 
                        ["optionA", "optionB", "optionC"]
                    
                    self.currentOptions = [formattedAnswer] + defaultOptions
                    self.currentOptions.shuffle()
                    self.showingOptions = true
                    self.isGeneratingOptions = false
                }
            }
        }
    }
    
    private func selectAnswer(_ answer: String) {
        guard !hasAnswered else { return }
        
        selectedOption = answer
        
        // 检查答案
        let word = currentWord!
        let formattedCorrectAnswer = formatCorrectAnswer(for: word)
        isAnswerCorrect = answer == formattedCorrectAnswer
        hasAnswered = true
        
        // 记录答案
        let result = QuizResult(
            word: word,
            selectedAnswer: answer,
            isCorrect: isAnswerCorrect,
            timeTaken: 0 // 可以后续添加计时功能
        )
        userAnswers.append(result)
        
        // 更新错题数据
        if isAnswerCorrect {
            manager.recordCorrectAnswer(for: word)
        } else {
            manager.recordIncorrectAnswer(for: word)
        }
        
        // 显示反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingResult = true
        }
    }

    // 不会：直接按错误处理，复用一致的反馈流程
    private func handleDontKnow(for word: WrongWord) {
        guard !hasAnswered else { return }
        selectedOption = ""
        isAnswerCorrect = false
        hasAnswered = true
        // 记录结果
        let result = QuizResult(
            word: word,
            selectedAnswer: "不会",
            isCorrect: false,
            timeTaken: 0
        )
        userAnswers.append(result)
        // 更新错题
        manager.recordIncorrectAnswer(for: word)
        // 显示反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingResult = true
        }
    }
    
    private func nextWord() {
        currentWordIndex += 1
        resetCurrentWord()
        
        // 优先使用缓存
        if let currentWord = currentWord,
           let cached = optionsCache[currentWord.word]?[selectedLearningMode] {
            currentOptions = cached
            showingOptions = true
        } else if let preloadedOptions = preloadedOptions,
                  let currentWord = currentWord,
                  let options = preloadedOptions[currentWord.word],
                  selectedLearningMode == currentWord.learningDirection {
            // 写入缓存并显示
            var map = optionsCache[currentWord.word] ?? [:]
            map[currentWord.learningDirection] = options
            optionsCache[currentWord.word] = map
            currentOptions = options
            showingOptions = true
        }
    }
    
    private func restartQuiz() {
        currentWordIndex = 0
        userAnswers.removeAll()
        resetCurrentWord()
        
        // 优先使用缓存
        if let firstWord = quizWords.first,
           let cached = optionsCache[firstWord.word]?[selectedLearningMode] {
            currentOptions = cached
            showingOptions = true
        } else if let preloadedOptions = preloadedOptions,
                  let firstWord = quizWords.first,
                  let options = preloadedOptions[firstWord.word],
                  selectedLearningMode == firstWord.learningDirection {
            // 写入缓存并显示
            var map = optionsCache[firstWord.word] ?? [:]
            map[firstWord.learningDirection] = options
            optionsCache[firstWord.word] = map
            currentOptions = options
            showingOptions = true
        }
    }
    
    // 计算记忆强度
    private func calculateMemoryStrength() -> Double {
        guard let word = currentWord else { return 0.5 }
        
        let reviewCount = word.reviewCount
        let daysSinceLastReview = Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
        
        // 基于艾宾浩斯曲线计算
        let memoryStrengthBase = 1.0 + (Double(max(reviewCount, 1)) - 1.0) * 0.5
        let retention = exp(-Double(daysSinceLastReview) / memoryStrengthBase)
        
        return max(retention, 0.1)
    }
    
    // 计算连击数
    private func calculateStreakCount() -> Int {
        let recentResults = userAnswers.suffix(5)
        var streak = 0
        
        for result in recentResults.reversed() {
            if result.isCorrect {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    // 格式化正确答案（根据当前选择的学习方向决定格式）
    private func formatCorrectAnswer(for word: WrongWord) -> String {
        switch selectedLearningMode {
        case .recognizeMeaning:
            // 英译中：显示中文含义，可能包含词性
            return formatAnswerWithPartOfSpeech(word.meaning, partOfSpeech: word.partOfSpeech)
        case .recallWord:
            // 中译英：显示英文单词，不需要词性
            return word.word
        case .dictation:
            // 听写模式：显示英文单词
            return word.word
        }
    }
    
    // 格式化答案，如果有词性信息则添加到答案中（仅用于中文答案）
    private func formatAnswerWithPartOfSpeech(_ meaning: String, partOfSpeech: PartOfSpeech?) -> String {
        guard let partOfSpeech = partOfSpeech else {
            return meaning
        }
        
        // 如果答案已经包含词性信息，直接返回
        if meaning.contains("(") && meaning.contains(")") {
            return meaning
        }
        
        // 添加词性信息
        return "\(meaning)(\(partOfSpeech.rawValue))"
    }
    

    
    // 切换学习模式
    private func switchLearningMode() {
        // 记录是否之前有显示选项
        let wasShowingOptions = showingOptions
        
        // 切换模式
        selectedLearningMode = selectedLearningMode == .recognizeMeaning ? .recallWord : .recognizeMeaning
        
        // 重置当前题目状态
        resetCurrentWordState()
        
        // 如果之前有显示选项，重新生成选项
        if wasShowingOptions, let word = currentWord {
            generateOptions(for: word)
        }
    }
    
    // 重置当前单词的状态
    private func resetCurrentWordState() {
        showingOptions = false
        selectedOption = ""
        isAnswerCorrect = false
        hasAnswered = false
        showingResult = false
        currentOptions.removeAll()
    }
    
    // 清除选项缓存（用于调试和强制刷新选项）
    private func clearOptionsCache() {
        optionsCache.removeAll()
        currentOptions.removeAll()
        showingOptions = false
        print("✅ 选项缓存已清除")
    }
    
    private func getNextReviewInterval() -> Int {
        guard let word = currentWord else { return 1 }
        let reviewCount = word.reviewCount + 1
        
        switch reviewCount {
        case 1: return 1
        case 2: return 3
        case 3: return 7
        case 4: return 15
        default: return 30
        }
    }
    
    // MARK: - 获取Excel预生成选项
    // 直接使用WrongWord中的预生成选项
    private func getPreGeneratedOptions(for word: WrongWord, learningDirection: LearningDirection) -> [String]? {
        print("🔍 获取单词预生成选项: \(word.word) - \(word.meaning)")
        
        // 根据学习方向返回对应的预生成选项
        let misleadingOptions: [String]
        switch learningDirection {
        case .recognizeMeaning:
            misleadingOptions = word.misleadingChineseOptions
        case .recallWord:
            misleadingOptions = word.misleadingEnglishOptions
        case .dictation:
            return nil
        }
        
        // 检查选项是否为空
        guard !misleadingOptions.isEmpty else {
            print("⚠️ 单词 \(word.word) 的预生成选项为空")
            return nil
        }
        
        print("✅ 找到单词 \(word.word) 的预生成选项: \(misleadingOptions)")
        
        // 构建完整的选项列表（包含正确答案）
        let correctAnswer = learningDirection == .recognizeMeaning ? word.meaning : word.word
        var allOptions = misleadingOptions
        
        // 确保正确答案包含在选项中
        if !allOptions.contains(correctAnswer) {
            allOptions.append(correctAnswer)
        }
        
        // 打乱顺序并限制为4个选项
        return Array(allOptions.shuffled().prefix(4))
    }
}

// MARK: - Quiz Result Model
struct QuizResult {
    let word: WrongWord
    let selectedAnswer: String
    let isCorrect: Bool
    let timeTaken: TimeInterval
}

// MARK: - Quiz Completion View
struct QuizCompletionView: View {
    let results: [QuizResult]
    let manager: WrongWordManager
    let onRestart: () -> Void
    let onDismiss: () -> Void
    
    private var correctCount: Int {
        results.filter(\.isCorrect).count
    }
    
    private var accuracy: Double {
        guard !results.isEmpty else { return 0 }
        return Double(correctCount) / Double(results.count)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 完成庆祝
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                
                Text("复习完成！")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("共复习 \(results.count) 个单词")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 统计结果
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("\(correctCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    
                    Text("答对")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(results.count - correctCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                    
                    Text("答错")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(Int(accuracy * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Text("正确率")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // 操作按钮
            VStack(spacing: 12) {
                Button {
                    onRestart()
                } label: {
                    Text("再次复习")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    onDismiss()
                } label: {
                    Text("返回")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }
}

#Preview {
    WrongWordQuizView(filterWords: nil, preloadedOptions: nil)
        .environmentObject(WrongWordManager())
}
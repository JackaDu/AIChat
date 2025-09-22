import SwiftUI

struct HybridLearningView: View {
    @ObservedObject var hybridManager: HybridLearningManager
    @StateObject private var excelImporter = WordDataManager(appwriteService: AppwriteService())
    @StateObject private var phoneticService = PhoneticService()
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var appwriteService: AppwriteService
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var studyRecordService: StudyRecordDatabaseService
    
    init(hybridManager: HybridLearningManager) {
        self.hybridManager = hybridManager
        self._selectedLearningMode = State(initialValue: .recognizeMeaning)
        // 初始化学习记录服务 - 将在 onAppear 中重新初始化
        _studyRecordService = StateObject(wrappedValue: StudyRecordDatabaseService(appwriteService: AppwriteService()))
        
        print("🔄 HybridLearningView 初始化")
        print("- hybridManager.todayWords.count: \(hybridManager.todayWords.count)")
        print("- hybridManager.isFromListMode: \(hybridManager.isFromListMode)")
    }
    
    init(hybridManager: HybridLearningManager, initialMode: LearningDirection) {
        self.hybridManager = hybridManager
        self._selectedLearningMode = State(initialValue: initialMode)
        self._studyRecordService = StateObject(wrappedValue: StudyRecordDatabaseService(appwriteService: AppwriteService()))
        
        print("🔄 HybridLearningView 初始化 (带initialMode)")
        print("- hybridManager.todayWords.count: \(hybridManager.todayWords.count)")
        print("- initialMode: \(initialMode)")
    }
    
    @State private var currentWordIndex = 0
    @State private var isLoadingOptions = false
    @State private var aiError: String?
 // 不显示学习设置，直接开始学习
    @State private var targetWordCount = 10 // 将从用户偏好中获取
    
    // 学习状态变量
    @State private var showingAnswer = false
    @State private var userKnows = false
    @State private var showingOptions = false
    @State private var selectedOption: String = ""
    @State private var isAnswerCorrect = false
    @State private var hasAnswered = false
    
    // 动态反馈相关状态
    @State private var showFeedback = false
    @State private var currentMemoryStrength: Double = 0.5
    @State private var streakCount = 0
    
    // 音频播放控制
    @State private var lastPlayedWordIndex = -1
    @State private var canPlayAudio = false // 标记是否可以播放音频
    
    // 学习模式状态
    @State private var selectedLearningMode: LearningDirection
    
    // 不使用额外页面测试，保留内联选择题流程
    

    
    private let aiGenerator = AIConfusionGenerator(apiKey: AppConfig.shared.openAIAPIKey)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                // 调试信息
                let _ = print("🔍 HybridLearningView body 调试信息:")
                let _ = print("- isPreloadingWords: \(hybridManager.isPreloadingWords)")
                let _ = print("- isPreGeneratingOptions: \(hybridManager.isPreGeneratingOptions)")
                let _ = print("- todayWords.count: \(hybridManager.todayWords.count)")
                let _ = print("- isFromListMode: \(hybridManager.isFromListMode)")
                
                if hybridManager.isPreloadingWords {
                    // 预加载状态
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("正在预加载单词...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("首次启动需要一些时间来准备学习内容")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                } else if hybridManager.isPreGeneratingOptions {
                    // 预生成选项进度
                    OptionsPreGenerationView(
                        progress: hybridManager.preGenerationProgress,
                        status: hybridManager.preGenerationStatus
                    )
                } else if hybridManager.todayWords.isEmpty {
                    // 空状态
                    EmptyStateView {
                        await startLearning()
                    }
                } else {
                    // 学习界面 - 重新设计为紧凑布局
                    let _ = print("🎯 进入学习界面显示逻辑")
                    let _ = print("- currentWordIndex: \(currentWordIndex)")
                    let _ = print("- todayWords.count: \(hybridManager.todayWords.count)")
                    let _ = print("- 当前单词: \(currentWordIndex < hybridManager.todayWords.count ? hybridManager.todayWords[currentWordIndex].word : "索引超出范围")")
                    
                    VStack(spacing: 0) {
                        // 顶部退出按钮
                        HStack {
                            Button(action: {
                                // 停止所有音频播放
                                phoneticService.stopAllAudio()
                                // 退出前提交所有待处理的学习记录
                                submitPendingStudyRecords()
                                // 退出前检查是否需要记录错题
                                recordCurrentWordIfNeeded()
                                // 使用 presentationMode 退出到主页面
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                    Text("退出")
                                        .font(.headline)
                                }
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // 简化的进度显示 - 听写模式下更紧凑
                        if selectedLearningMode != .dictation {
                            HStack {
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text("\(currentWordIndex + 1) / \(hybridManager.todayWords.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                    
                                    Text("完成进度")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else {
                            // 听写模式下的简化进度显示
                            HStack {
                                Spacer()
                                Text("\(currentWordIndex + 1) / \(hybridManager.todayWords.count)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // 学习方向切换按钮（仅在卡片模式下显示）
                        if selectedLearningMode != .dictation {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                // 只在英中互译间切换，不包含听写模式
                                switch selectedLearningMode {
                                case .recognizeMeaning:
                                    selectedLearningMode = .recallWord
                                case .recallWord:
                                    selectedLearningMode = .recognizeMeaning
                                case .dictation:
                                    // 听写模式不支持切换，保持当前模式
                                    break
                                }
                                
                                // 保存用户偏好
                                preferencesManager.userPreferences.defaultLearningMode = selectedLearningMode
                                
                                // 重新生成选项以匹配新的学习模式（听写模式不需要选项）
                                if selectedLearningMode != .dictation {
                                    Task {
                                        await hybridManager.preGenerateOptionsForAllWords(learningMode: selectedLearningMode)
                                    }
                                }
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
                            .padding(.horizontal, 20)
                        }
                        
                        if currentWordIndex >= hybridManager.todayWords.count {
                            // 学习完成界面
                            CompletionView(
                                totalWords: hybridManager.todayWords.count,
                                onRestart: {
                                    // 重新开始学习，保持当前学习模式
                                    currentWordIndex = 0
                                    Task {
                                        await restartLearningWithCurrentMode()
                                    }
                                },
                                onBack: {
                                    // 返回首页
                                    presentationMode.wrappedValue.dismiss()
                                }
                            )
                            .onAppear {
                                // 学习完成时清除保存的进度
                                clearSavedProgress()
                            }
                        } else if currentWordIndex < hybridManager.todayWords.count {
                            // 卡片模式：单个单词学习
                            let currentWord = hybridManager.todayWords[currentWordIndex]
                            
                            VStack(spacing: 12) {
                                // 在卡片上方添加基本信息（答题前只显示基本信息，不显示图片和记忆技巧）
                                if selectedLearningMode != .dictation {
                                    BasicWordInfoView(
                                        currentWord: currentWord,
                                        currentWordIndex: currentWordIndex,
                                        showImageAndTips: hasAnswered || showingAnswer
                                    )
                                }
                                
                                // 根据学习模式显示不同的界面
                                if selectedLearningMode == .dictation {
                                    // 听写模式：使用专门的听写组件
                                    DictationModeView(
                                        word: currentWord,
                                        onAnswer: { isCorrect in
                                            handleDictationAnswer(isCorrect: isCorrect)
                                        },
                                        phoneticService: phoneticService
                                    )
                                    .id("dictation-\(currentWordIndex)-\(currentWord.word)")
                                    .padding(.horizontal, 20)
                                } else {
                                    // 选择模式：使用统一的学习卡片
                                    UnifiedLearningCard(
                                        content: selectedLearningMode == .recognizeMeaning ? currentWord.word : currentWord.meaning,
                                        phonetic: selectedLearningMode == .recognizeMeaning ? phoneticService.getPhoneticSymbol(for: currentWord.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) : nil,
                                        pronunciationType: selectedLearningMode == .recognizeMeaning ? preferencesManager.userPreferences.pronunciationType : nil,
                                        cardColor: .blue,
                                        isHighlighted: showFeedback || showingAnswer,
                                        onPlayAudio: selectedLearningMode == .recognizeMeaning ? {
                                            phoneticService.playPronunciation(for: currentWord.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                                        } : nil,
                                        onCardTap: {
                                            // 卡片点击逻辑：根据当前状态处理
                                            if !userKnows && !hasAnswered {
                                                // 初始状态：点击卡片表示"认识"
                                                userKnows = true
                                                generateOptions()
                                            } else if showingAnswer {
                                                // 答案显示状态：点击卡片进入下一题
                                                nextWord()
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                    .onAppear {
                                        // 只有当允许播放音频且这是一个新单词时才朗读
                                        if canPlayAudio && selectedLearningMode == .recognizeMeaning && lastPlayedWordIndex != currentWordIndex {
                                            lastPlayedWordIndex = currentWordIndex
                                            // 如果是第一个单词，稍微延迟长一点确保界面稳定
                                            let delay = (currentWordIndex == 0) ? 1.0 : 0.3
                                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                                phoneticService.playPronunciation(for: currentWord.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                                            }
                                        }
                                    }
                                }
                                
                                // 简化的状态显示逻辑
                                VStack(spacing: 8) {
                                                                    // 统一反馈系统
                                if showFeedback {
                                    UnifiedLearningFeedback(
                                        isCorrect: isAnswerCorrect,
                                        memoryStrength: currentMemoryStrength,
                                        streakCount: streakCount,
                                        onComplete: {
                                            showFeedback = false
                                            // 显示答案信息（包含记忆技巧、例句和图片）
                                            showingAnswer = true
                                            // 不再自动进入下一题，让用户手动控制
                                        }
                                    )
                                    .padding(.vertical)
                                }
                                
                                // 听写模式不需要"会/不会"判断，其他模式才需要
                                if selectedLearningMode != .dictation && !userKnows && !hasAnswered {
                                        // 初始状态：询问用户是否会这个单词
                                        VStack(spacing: 16) {
                                            Text("你会这个单词吗？")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                            
                                            // 使用统一的答案按钮
                                            UnifiedAnswerButtons(
                                                primaryText: "认识",
                                                secondaryText: "不认识",
                                                primaryColor: .green,
                                                secondaryColor: .red,
                                                primaryAction: {
                                                    userKnows = true
                                                    // 内联生成并显示选项
                                                    generateOptions()
                                                },
                                                secondaryAction: {
                                                    userKnows = false
                                                    showingAnswer = true
                                                    hasAnswered = true
                                                    isAnswerCorrect = false
                                                    
                                                    // 立即记录错题
                                                    handleIncorrectAnswer()
                                                    
                                                    // 先显示正确答案，不立即显示反馈
                                                    updateMemoryStrength()
                                                    
                                                    // 标记当前单词为已处理，避免重复显示
                                                    markCurrentWordAsProcessed()
                                                }
                                            )
                                        }
                                        .padding(.horizontal, 20)
                                    } else if userKnows && showingOptions && !hasAnswered {
                                        // 选项选择区域
                                        OptionsSelectionView(
                                            currentWord: currentWord,
                                            selectedLearningMode: selectedLearningMode,
                                            selectedOption: $selectedOption,
                                            onAnswerSelected: checkAnswer,
                                            allWords: hybridManager.todayWords
                                        )
                                    } else if (hasAnswered && !showFeedback) || showingAnswer {
                                        // 优化的答案显示区域 - 一屏内完成操作
                                        VStack(spacing: 12) {
                                            // 答案信息（紧凑显示）
                                            VStack(spacing: 10) {
                                                if selectedLearningMode == .recognizeMeaning {
                                                    Text(currentWord.meaning)
                                                        .font(.title2)
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(.blue)
                                                        .multilineTextAlignment(.center)
                                                } else {
                                                    Text(currentWord.word)
                                                        .font(.title2)
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(.blue)
                                                        .multilineTextAlignment(.center)
                                                }
                                                
                                                // 1. 优先显示记忆技巧（最重要）
                                                if let memoryTip = currentWord.memoryTip, !memoryTip.isEmpty {
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        HStack {
                                                            Image(systemName: "lightbulb.fill")
                                                                .foregroundStyle(.yellow)
                                                                .font(.system(size: 14))
                                                            Text("记忆技巧")
                                                                .font(.subheadline)
                                                                .fontWeight(.semibold)
                                                                .foregroundStyle(.primary)
                                                            Spacer()
                                                        }
                                                        
                                                        Text(memoryTip)
                                                            .font(.subheadline)
                                                            .foregroundStyle(.secondary)
                                                            .lineLimit(3) // 限制行数，保持紧凑
                                                    }
                                                    .padding(12)
                                                    .background(.yellow.opacity(0.08))
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                }
                                                
                                                // 2. 例句（第二优先级，限制长度）
                                                if !currentWord.example.isEmpty {
                                                    EnhancedExampleDisplay(exampleText: currentWord.example)
                                                }
                                                
                                                // 3. 词根词源信息（可折叠）
                                                EtymologyInfoDisplay(
                                                    etymology: currentWord.etymology,
                                                    relatedWords: currentWord.relatedWords
                                                )
                                            }
                                            
                                            // 快速操作按钮区域
                                            HStack(spacing: 12) {
                                                // 下一个单词按钮（主要操作）
                                                Button {
                                                    nextWord()
                                                } label: {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: "arrow.right.circle.fill")
                                                        Text("下一个")
                                                    }
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 14)
                                                    .background(
                                                        LinearGradient(
                                                            colors: [.blue, .blue.opacity(0.8)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                            }
                                        }
                                        .padding(16) // 减少内边距
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .padding(.horizontal, 16) // 减少外边距
                                        .onAppear {
                                            triggerMemoryInteraction()
                                            // 调试信息：确认所有字段都能正确显示
                                            print("🎯 显示答案区域 - 当前单词: \(currentWord.word)")
                                            print("   - example: \(currentWord.example)")
                                            print("   - imageURL: \(currentWord.imageURL ?? "nil")")
                                            print("   - etymology: \(currentWord.etymology ?? "nil")")
                                            print("   - memoryTip: \(currentWord.memoryTip ?? "nil")")
                                            print("   - relatedWords: \(currentWord.relatedWords ?? [])")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 底部安全区域
                        Spacer(minLength: 8)
                    }
                }
                }
            }
            .navigationTitle(selectedLearningMode == .dictation ? "听写练习" : "学习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 移除清除缓存按钮
            }
            .onDisappear {
                // 中途退出时保存进度
                saveCurrentProgress()
            }

        }
        // 统一测试：弹出复用 WrongWordQuizView
        // 移除外部测试弹窗，使用内联选项
        .onAppear {
            // 更新学习记录服务以使用正确的 appwriteService 实例
            studyRecordService.updateAppwriteService(appwriteService)
            
            // 使用用户设置的每日学习量
            targetWordCount = preferencesManager.userPreferences.dailyStudyAmount.rawValue
            
            // 总是自动开始学习，无论什么状态
            Task {
                // 检查是否是从列表模式跳转的
                if hybridManager.isFromListMode {
                    print("🔄 HybridLearningView: 从列表模式跳转，跳过预加载")
                    // 从列表模式跳转，已经有单词了，直接恢复进度
                    if !hybridManager.todayWords.isEmpty {
                        restoreProgress()
                    }
                } else {
                    // 正常模式，先预加载所有单词
                    await hybridManager.preloadAllWords(preferencesManager: preferencesManager)
                    
                    // 如果已经有学习内容，恢复进度
                    if !hybridManager.todayWords.isEmpty {
                        restoreProgress()
                    } else {
                        // 否则开始新的学习
                        await startLearning()
                    }
                }
            }
        }
    }

    // 为当前单词准备统一测试所需数据，并弹出测试
    
    // 开始学习
    private func startLearning() async {
        // 初始化学习模式和目标单词数量
        selectedLearningMode = preferencesManager.userPreferences.defaultLearningMode
        targetWordCount = preferencesManager.userPreferences.dailyStudyAmount.rawValue
        
        // 等待预加载完成（如果正在进行）
        while hybridManager.isPreloadingWords {
            try? await Task.sleep(nanoseconds: 100_000_000) // 等待0.1秒
        }
        
        await hybridManager.generateTodayWords(learningMode: selectedLearningMode, targetCount: targetWordCount)
    }
    
    // 重新开始学习，保持当前学习模式
    private func restartLearningWithCurrentMode() async {
        // 保持当前学习模式，只重置目标单词数量
        targetWordCount = preferencesManager.userPreferences.dailyStudyAmount.rawValue
        
        // 等待预加载完成（如果正在进行）
        while hybridManager.isPreloadingWords {
            try? await Task.sleep(nanoseconds: 100_000_000) // 等待0.1秒
        }
        
        print("🔄 重新开始学习，保持模式: \(selectedLearningMode)")
        await hybridManager.generateTodayWords(learningMode: selectedLearningMode, targetCount: targetWordCount)
        
        // 重置所有学习状态
        currentWordIndex = 0
        hasAnswered = false
        showingOptions = false
        showingAnswer = false
        userKnows = false
        aiError = nil
        selectedOption = ""
        isAnswerCorrect = false
        showFeedback = false
        lastPlayedWordIndex = -1 // 重置音频播放状态
        canPlayAudio = true // 开始学习后允许音频播放
    }
    
    // 下一个单词
    private func nextWord() {
        // 重置所有状态（但保持音频播放权限）
        hasAnswered = false
        showingOptions = false
        showingAnswer = false
        userKnows = false
        aiError = nil
        selectedOption = ""
        isAnswerCorrect = false
        showFeedback = false // 重置反馈状态
        // 注意：不重置 canPlayAudio，因为用户已经开始学习
        
        currentWordIndex += 1
        
        if currentWordIndex >= hybridManager.todayWords.count {
            // 学习完成
            hybridManager.markLearningComplete()
        } else {
            // 自动播放新单词的发音
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.selectedLearningMode == .recognizeMeaning {
                    self.phoneticService.playPronunciation(for: self.hybridManager.todayWords[self.currentWordIndex].word) {}
                }
            }
        }
    }
    

    
    // 生成选项
    private func generateOptions() {
        let word = hybridManager.todayWords[currentWordIndex]
        
        print("🔍 HybridLearningView generateOptions 调试信息:")
        print("- 当前单词: \(word.word)")
        print("- 预生成选项: \(word.preGeneratedOptions ?? [])")
        print("- 预生成选项是否为空: \(word.preGeneratedOptions?.isEmpty ?? true)")
        
        // 检查是否有预生成的选项
        if let preGeneratedOptions = word.preGeneratedOptions, !preGeneratedOptions.isEmpty {
            // 同步更新状态，不使用异步队列
            showingOptions = true
            print("- 使用预生成选项，showingOptions = true")
            return
        }
        
        // 无预生成选项，仍然显示选项选择界面
        // 让OptionsSelectionView自己处理选项生成
        showingOptions = true
        print("- 无预生成选项，showingOptions = true")
    }
    
    // 检查答案
    private func checkAnswer() {
        guard currentWordIndex < hybridManager.todayWords.count else { return }
        
        let word = hybridManager.todayWords[currentWordIndex]
        let correctAnswer = selectedLearningMode == .recognizeMeaning ? word.meaning : word.word
        
        isAnswerCorrect = selectedOption == correctAnswer
        hasAnswered = true
        
        // 更新记忆强度和连击数
        updateMemoryStrength()
        
        // 显示动态反馈
        showFeedback = true
        
        // 延迟处理答案逻辑，让动画先播放
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if isAnswerCorrect {
                handleCorrectAnswer()
            } else {
                handleIncorrectAnswer()
            }
        }
    }
    
    // 更新记忆强度
    private func updateMemoryStrength() {
        if isAnswerCorrect {
            // 答对了，提升记忆强度
            currentMemoryStrength = min(1.0, currentMemoryStrength + 0.2)
            streakCount += 1
        } else {
            // 答错了，降低记忆强度
            currentMemoryStrength = max(0.1, currentMemoryStrength - 0.3)
            streakCount = 0
        }
    }
    

    
    // 保存当前学习进度
    private func saveCurrentProgress() {
        // 遍历已经学习过的单词，保存结果
        for index in 0..<min(currentWordIndex, hybridManager.todayWords.count) {
            let word = hybridManager.todayWords[index]
            
            // 这里需要根据实际的学习结果来判断
            // 由于我们没有保存每题的详细结果，我们假设：
            // - 如果用户看过这个单词并做过答题，我们检查最终结果
            // - 如果答错了，加入错题本
            // - 如果答对了，标记为已掌握，不再重复测试
            
            // 简化处理：如果当前单词索引大于这个单词的索引，说明已经学习过
            if index < currentWordIndex {
                // 这里可以根据实际的答题结果来处理
                // 暂时我们假设已经学习过的单词都需要保存进度
                print("已保存单词进度: \(word.word)")
            }
        }
        
        // 保存当前学习位置
        UserDefaults.standard.set(currentWordIndex, forKey: "HybridLearning_CurrentIndex")
        UserDefaults.standard.set(Date(), forKey: "HybridLearning_LastExitTime")
    }
    
    // 恢复学习进度
    private func restoreProgress() {
        let savedIndex = UserDefaults.standard.integer(forKey: "HybridLearning_CurrentIndex")
        let lastExitTime = UserDefaults.standard.object(forKey: "HybridLearning_LastExitTime") as? Date
        
        print("🔄 restoreProgress 调试信息:")
        print("- savedIndex: \(savedIndex)")
        print("- lastExitTime: \(lastExitTime?.description ?? "nil")")
        print("- todayWords.count: \(hybridManager.todayWords.count)")
        print("- isFromListMode: \(hybridManager.isFromListMode)")
        print("- selectedLearningMode: \(selectedLearningMode)")
        
        // 如果是从列表模式跳转，不恢复进度，从头开始
        if hybridManager.isFromListMode {
            print("🔄 从列表模式跳转，重置进度从头开始")
            currentWordIndex = 0
        } else {
            // 如果最后退出时间是今天，恢复进度
            if let lastExit = lastExitTime,
               Calendar.current.isDateInToday(lastExit),
               savedIndex > 0 && savedIndex < hybridManager.todayWords.count {
                currentWordIndex = savedIndex
                print("恢复学习进度到第 \(savedIndex + 1) 个单词")
            } else {
                currentWordIndex = 0
                print("重置进度从头开始")
            }
        }
        
        print("✅ 最终 currentWordIndex: \(currentWordIndex)")
        
        // 重置音频播放状态
        // 注意：在听写模式下，我们不希望在恢复进度时自动播放发音
        if selectedLearningMode == .dictation {
            canPlayAudio = false // 听写模式下禁用自动播放
            lastPlayedWordIndex = currentWordIndex // 标记当前单词已"播放"过，避免重复
        } else {
            canPlayAudio = true // 其他模式允许播放
            lastPlayedWordIndex = -1
        }
    }
    
    // 清除保存的进度（学习完成时调用）
    private func clearSavedProgress() {
        UserDefaults.standard.removeObject(forKey: "HybridLearning_CurrentIndex")
        UserDefaults.standard.removeObject(forKey: "HybridLearning_LastExitTime")
    }
    
    // 处理正确答案
    private func handleCorrectAnswer() {
        // 用户答对了，记录正确答案
        let word = hybridManager.todayWords[currentWordIndex]
        
        // 将单词添加到已完成列表
        hybridManager.completedWords.append(word)
        
        // 创建学习记录
        let studyRecord = StudyRecord(
            userId: appwriteService.currentUser?.id ?? "",
            word: word.word,
            meaning: word.meaning,
            context: word.example,
            learningDirection: selectedLearningMode,
            isCorrect: true,
            answerTime: 0, // 可以记录实际答题时间
            memoryStrength: currentMemoryStrength,
            streakCount: streakCount
        )
        
        // 添加到批量队列（非阻塞，提升性能）
        studyRecordService.addStudyRecord(studyRecord)
        print("✅ 答对记录已加入队列: \(word.word)")
    }
    
    // 处理错误答案
    private func handleIncorrectAnswer() {
        // 用户答错了，添加到错题本
        let word = hybridManager.todayWords[currentWordIndex]
        
        // 添加到错题本
        let wrongWord = WrongWord(
            word: word.word,
            meaning: word.meaning,
            context: word.example,
            learningDirection: selectedLearningMode
        )
        
        wrongWordManager.addWrongWord(wrongWord)
        print("📝 错题已记录: \(word.word)")
        
        // 创建学习记录（答错）
        let studyRecord = StudyRecord(
            userId: appwriteService.currentUser?.id ?? "",
            word: word.word,
            meaning: word.meaning,
            context: word.example,
            learningDirection: selectedLearningMode,
            isCorrect: false,
            answerTime: 0, // 可以记录实际答题时间
            memoryStrength: currentMemoryStrength,
            streakCount: streakCount
        )
        
        // 添加到批量队列（非阻塞，提升性能）
        studyRecordService.addStudyRecord(studyRecord)
        print("✅ 答错记录已加入队列: \(word.word)")
    }
    
    // 处理听写模式答案
    private func handleDictationAnswer(isCorrect: Bool) {
        let word = hybridManager.todayWords[currentWordIndex]
        
        // 设置答题状态
        hasAnswered = true
        isAnswerCorrect = isCorrect
        
        // 更新记忆强度
        updateMemoryStrength()
        
        if isCorrect {
            handleCorrectAnswer()
        } else {
            handleIncorrectAnswer()
        }
        
        // 听写模式不显示反馈，直接进入下一题
        print("📝 听写模式答题完成:")
        print("- 单词: \(word.word)")
        print("- 结果: \(isCorrect ? "正确" : "错误")")
        
        // 直接进入下一个单词，不显示反馈界面
        nextWord()
    }
    
    // 退出前提交所有待处理的学习记录
    private func submitPendingStudyRecords() {
        studyRecordService.flushPendingRecords()
        print("📤 已提交所有待处理的学习记录")
    }
    
    // 退出前检查是否需要记录错题
    private func recordCurrentWordIfNeeded() {
        // 如果用户已经回答了当前单词，且答案是错误的，则记录到错题本
        if hasAnswered && !isAnswerCorrect && currentWordIndex < hybridManager.todayWords.count {
            let word = hybridManager.todayWords[currentWordIndex]
            
            // 检查是否已经记录过这个错题（避免重复记录）
            let existingWrongWords = wrongWordManager.wrongWords
            let alreadyRecorded = existingWrongWords.contains { wrongWord in
                wrongWord.word == word.word && wrongWord.learningDirection == selectedLearningMode
            }
            
            if !alreadyRecorded {
                let wrongWord = WrongWord(
                    word: word.word,
                    meaning: word.meaning,
                    context: word.example,
                    learningDirection: selectedLearningMode
                )
                
                wrongWordManager.addWrongWord(wrongWord)
                print("📝 退出时记录错题: \(word.word)")
            }
        }
    }
    
    // 标记当前单词为已处理，避免重复显示
    private func markCurrentWordAsProcessed() {
        guard currentWordIndex < hybridManager.todayWords.count else { return }
        
        let currentWord = hybridManager.todayWords[currentWordIndex]
        print("🏷️ 标记单词为已处理: \(currentWord.word)")
        
        // 这里可以添加逻辑来标记单词已被处理，避免在后续的学习中重复出现
        // 例如：添加到已处理列表，或者标记为已学习状态
    }
    
    // 触发记忆交互效果
    private func triggerMemoryInteraction() {
        if currentWordIndex < hybridManager.todayWords.count {
            let word = hybridManager.todayWords[currentWordIndex]
            
            let _: [String: Any] = [
                "word": word.word,
                "meaning": word.meaning,
                "isCorrect": isAnswerCorrect,
                "isNewWord": word.source == .imported, // 判断是否为新词
                "learningMode": selectedLearningMode.rawValue
            ]
            
            if word.source == .imported {
                // 新词学习
                // 移除通知发送，简化逻辑
            } else {
                // 复习单词
                // 移除通知发送，简化逻辑
            }
        }
    }
    
    // 清除预生成选项缓存
    private func clearPreGeneratedOptionsCache() {
        // 清除所有单词的预生成选项
        for i in 0..<hybridManager.todayWords.count {
            hybridManager.todayWords[i].preGeneratedOptions = nil
        }
        
        // 重置当前选项状态
        showingOptions = false
        selectedOption = ""
        hasAnswered = false
        
        print("✅ 预生成选项缓存已清除")
    }
}

// MARK: - 状态展示组件  
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 学习设置视图
struct LearningSettingsView: View {
    @Binding var targetWordCount: Int
    let availableWordCount: Int
    let onStartLearning: () -> Void
    
    private let presetCounts = [5, 10, 15, 20, 30, 50]
    @State private var customCount = ""
    @State private var isCustomInput = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            VStack(spacing: 8) {
                Text("📚 学习设置")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("选择今天要学习的单词数量")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 可用单词信息
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.blue)
                Text("可用单词: \(availableWordCount) 个")
                    .font(.headline)
            }
            .padding()
            .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 快速选择预设数量
            VStack(spacing: 16) {
                Text("快速选择")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(presetCounts.filter { $0 <= availableWordCount }, id: \.self) { count in
                        Button {
                            targetWordCount = count
                            isCustomInput = false
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("个单词")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(targetWordCount == count && !isCustomInput ? .blue : .gray.opacity(0.1))
                            .foregroundStyle(targetWordCount == count && !isCustomInput ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            
            // 自定义数量输入
            VStack(spacing: 12) {
                Text("自定义数量")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    TextField("输入单词数量", text: $customCount)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .onChange(of: customCount) { _, newValue in
                            if let count = Int(newValue), count > 0, count <= availableWordCount {
                                targetWordCount = count
                                isCustomInput = true
                            }
                        }
                    
                    Text("(最多 \(availableWordCount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 当前选择显示
            if targetWordCount > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("将学习 \(targetWordCount) 个单词")
                        .font(.headline)
                }
                .padding()
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 开始学习按钮
            Button {
                onStartLearning()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("开始学习")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(targetWordCount > 0 ? .blue : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(targetWordCount <= 0)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let onLoadWords: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("正在准备学习内容")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("请稍等，我们正在为您准备单词")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await onLoadWords()
                }
            } label: {
                Text("开始学习")
                    .font(.headline)
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

// MARK: - 答案显示视图
struct AnswerDisplayView: View {
    let word: StudyWord
    let selectedLearningMode: LearningDirection
    let userKnows: Bool
    let isAnswerCorrect: Bool
    let phoneticService: PhoneticService
    let wrongWordManager: WrongWordManager
    let preferencesManager: UserPreferencesManager
    let onNext: () -> Void
    let onAnswerIncorrect: () -> Void
    
    @State private var hasPlayedAudio = false
    @State private var showingWordLearning = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 状态显示
            if userKnows {
                Text(isAnswerCorrect ? "🎉 回答正确！" : "❌ 回答错误")
                    .font(.headline)
                    .foregroundStyle(isAnswerCorrect ? .green : .red)
            } else {
                Text("❌ 你选择了'不会'")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
            
            // 答案卡片
            VStack(spacing: 16) {
                Text("正确答案")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // 英文单词和音标
                if selectedLearningMode == .recognizeMeaning {
                    VStack(spacing: 8) {
                        Text(word.word)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            ClickablePhoneticView(word: word.word, font: .title3)
                            
                            Button {
                                phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                            } label: {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Text(word.meaning)
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text(word.meaning)
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        Text(word.word)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            ClickablePhoneticView(word: word.word, font: .title3)
                            
                            Button {
                                phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                            } label: {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // 答错或不会时显示帮助学习按钮
            if !isAnswerCorrect || !userKnows {
                Button {
                    showingWordLearning = true
                } label: {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("帮助学习这个单词")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity))
            }
            
            // 下一步按钮
            Button {
                onNext()
            } label: {
                Text("下一个单词")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            // 如果答错或不会，自动播放发音
            if (!userKnows || !isAnswerCorrect) && !hasPlayedAudio {
                phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                hasPlayedAudio = true
                
                // 如果是错误答案，自动添加到错题本
                if !isAnswerCorrect || !userKnows {
                    onAnswerIncorrect()
                }
            }
        }
        .sheet(isPresented: $showingWordLearning) {
            WordLearningPopup(word: convertToWrongWord(word))
        }

    }
    
    // 将 StudyWord 转换为 WrongWord
    private func convertToWrongWord(_ studyWord: StudyWord) -> WrongWord {
        // 创建一个默认的来源信息
        let defaultTextbookSource = TextbookSource(
            courseType: .required,
            courseBook: "必修1", 
            unit: .unit1,
            textbookVersion: .renjiao
        )
        
        return WrongWord(
            word: studyWord.word,
            meaning: studyWord.meaning,
            context: studyWord.example,
            learningDirection: selectedLearningMode,
            textbookSource: defaultTextbookSource
        )
    }
}

// MARK: - 选项预生成进度视图
struct OptionsPreGenerationView: View {
    let progress: Double
    let status: String
    
    var body: some View {
        VStack(spacing: 40) {
            // 顶部动画图标
            VStack(spacing: 20) {
                // 旋转的齿轮图标
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(progress * 360))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: progress)
                
                Text("正在准备学习内容")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            // 进度区域
            VStack(spacing: 24) {
                // 状态描述
                Text(status)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // 进度条
                VStack(spacing: 12) {
                    HStack {
                        Text("进度")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // 底部提示
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.orange)
                    Text("正在为您生成智能选项")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text("AI正在分析单词特征，生成混淆性选项，让学习更加高效")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 学习完成视图
struct CompletionView: View {
    let totalWords: Int
    let onRestart: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // 完成图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            // 完成标题
            Text("🎉 学习完成！")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // 统计信息
            VStack(spacing: 12) {
                Text("恭喜你完成了今天的学习任务")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("共学习了 \(totalWords) 个单词")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // 主要操作按钮
            Button(action: onBack) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("返回首页")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            
            // 次要操作
            Button(action: onRestart) {
                Text("继续学习")
                    .font(.body)
                    .foregroundStyle(.blue)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 选项选择视图
struct OptionsSelectionView: View {
    let currentWord: StudyWord
    let selectedLearningMode: LearningDirection
    @Binding var selectedOption: String
    let onAnswerSelected: () -> Void
    let allWords: [StudyWord] // 添加所有单词的引用
    
    // 使用 @State 来缓存选项，避免每次重新计算
    @State private var allOptions: [String] = []
    @State private var isOptionsGenerated = false
    
    var body: some View {
        let correctAnswer = selectedLearningMode == .recognizeMeaning ? currentWord.meaning : currentWord.word
        
        VStack(spacing: 20) {
            Text(selectedLearningMode == .recognizeMeaning ? "选择正确的中文意思" : "选择正确的英文单词")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .onAppear {
                    // 只在第一次生成选项
                    if !isOptionsGenerated {
                        generateOptions()
                        isOptionsGenerated = true
                        
                        // 调试信息
                        print("🔍 OptionsSelectionView 调试信息:")
                        print("- 当前学习模式: \(selectedLearningMode)")
                        print("- 单词: \(currentWord.word)")
                        print("- 意思: \(currentWord.meaning)")
                        print("- 正确答案: \(correctAnswer)")
                        print("- 中文误导选项: \(currentWord.misleadingChineseOptions)")
                        print("- 英文误导选项: \(currentWord.misleadingEnglishOptions)")
                        print("- 生成的选项: \(allOptions)")
                        print("- allOptions.isEmpty: \(allOptions.isEmpty)")
                        print("- isOptionsGenerated: \(isOptionsGenerated)")
                    }
                }
            
            VStack(spacing: 12) {
                if !allOptions.isEmpty {
                    ForEach(allOptions, id: \.self) { option in
                        UnifiedOptionButton(
                            option: option,
                            isSelected: selectedOption == option,
                            isCorrect: nil,
                            showResult: false,
                            action: {
                                selectedOption = option
                                onAnswerSelected()
                            }
                        )
                    }
                } else {
                    Text("没有预生成选项，显示正确答案")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    
                    UnifiedOptionButton(
                        option: correctAnswer,
                        isSelected: selectedOption == correctAnswer,
                        isCorrect: nil,
                        showResult: false,
                        action: {
                            selectedOption = correctAnswer
                            onAnswerSelected()
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // 生成选项
    private func generateOptions() {
        let correctAnswer = selectedLearningMode == .recognizeMeaning ? currentWord.meaning : currentWord.word
        
        // 优先使用预生成选项
        if let preGeneratedOptions = currentWord.preGeneratedOptions, !preGeneratedOptions.isEmpty {
            allOptions = preGeneratedOptions.shuffled()
            print("🎯 使用数据库预生成选项:")
            print("- 当前单词: \(currentWord.word)")
            print("- 学习模式: \(selectedLearningMode)")
            print("- 预生成选项: \(preGeneratedOptions)")
            print("- 最终选项: \(allOptions)")
            return
        }
        
        // 如果没有预生成选项，使用误导选项
        let misleadingOptions: [String]
        switch selectedLearningMode {
        case .recognizeMeaning:
            // 英译中：使用中文误导选项
            misleadingOptions = currentWord.misleadingChineseOptions
        case .recallWord:
            // 中译英：使用英文误导选项
            misleadingOptions = currentWord.misleadingEnglishOptions
        case .dictation:
            // 听写模式：不需要选项
            misleadingOptions = []
        }
        
        // 构建完整的选项列表
        var options: [String] = []
        
        // 先添加正确答案
        options.append(correctAnswer)
        
        // 添加误导选项（去重）
        for option in misleadingOptions {
            if !options.contains(option) && options.count < 4 {
                options.append(option)
            }
        }
        
        // 如果选项不足4个，从其他单词中补充
        if options.count < 4 {
            let additionalOptions = generateFallbackOptions(
                correctAnswer: correctAnswer,
                existingOptions: options,
                targetCount: 4
            )
            options.append(contentsOf: additionalOptions)
        }
        
        // 打乱顺序
        allOptions = options.shuffled()
        
        print("🎯 使用数据库误导选项:")
        print("- 当前单词: \(currentWord.word)")
        print("- 学习模式: \(selectedLearningMode)")
        print("- 误导选项: \(misleadingOptions)")
        print("- 正确答案: \(correctAnswer)")
        print("- 最终选项: \(allOptions)")
    }
    
    // 生成备用选项
    private func generateFallbackOptions(correctAnswer: String, existingOptions: [String], targetCount: Int) -> [String] {
        var fallbackOptions: [String] = []
        let needed = targetCount - existingOptions.count
        
        // 从其他单词中随机选择选项
        let otherWords = allWords.filter { $0.word != currentWord.word }
        let shuffledWords = otherWords.shuffled()
        
        for word in shuffledWords {
            if fallbackOptions.count >= needed { break }
            
            let option = selectedLearningMode == .recognizeMeaning ? word.meaning : word.word
            if !existingOptions.contains(option) && !fallbackOptions.contains(option) {
                fallbackOptions.append(option)
            }
        }
        
        return fallbackOptions
    }
    
}


// MARK: - 增强例句显示组件
struct EnhancedExampleDisplay: View {
    let exampleText: String
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和展开/收起按钮
            HStack(spacing: 8) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.green)
                
                Text("例句")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            // 例句内容（可折叠）
            if isExpanded {
                if let examples = parseExamples(from: exampleText), !examples.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                            CompactExampleCard(
                                english: example.english,
                                chinese: example.chinese,
                                index: index + 1
                            )
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // 如果解析失败，显示原始文本（紧凑格式）
                    Text(formatRawExample(exampleText))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .padding(8)
                        .background(.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            } else {
                // 收起状态：只显示第一个例句的预览
                if let examples = parseExamples(from: exampleText), !examples.isEmpty {
                    let firstExample = examples[0]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(firstExample.english)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(firstExample.chinese)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                } else {
                    Text(formatRawExample(exampleText))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.vertical, 4)
                }
            }
        }
        .padding(12)
        .background(.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // 解析JSON格式的例句
    private func parseExamples(from text: String) -> [(english: String, chinese: String)]? {
        // 首先清理文本
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果不是以 [ 开头，尝试找到JSON数组的开始
        if !cleanedText.hasPrefix("[") {
            if let startIndex = cleanedText.firstIndex(of: "[") {
                cleanedText = String(cleanedText[startIndex...])
            }
        }
        
        // 如果不是以 ] 结尾，尝试找到JSON数组的结束
        if !cleanedText.hasSuffix("]") {
            if let endIndex = cleanedText.lastIndex(of: "]") {
                cleanedText = String(cleanedText[...endIndex])
            }
        }
        
        guard let data = cleanedText.data(using: .utf8) else { return nil }
        
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            return jsonArray?.compactMap { dict in
                guard let english = dict["english"] as? String,
                      let chinese = dict["chinese"] as? String else {
                    return nil
                }
                return (english: english.trimmingCharacters(in: .whitespacesAndNewlines), 
                       chinese: chinese.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } catch {
            print("解析例句JSON失败: \(error)")
            // 尝试修复常见的JSON格式问题
            return parseExamplesWithFallback(cleanedText)
        }
    }
    
    // 备用解析方法，处理格式不完全正确的JSON
    private func parseExamplesWithFallback(_ text: String) -> [(english: String, chinese: String)]? {
        var examples: [(english: String, chinese: String)] = []
        
        // 使用正则表达式提取所有的英文和中文对
        let pattern = #"\{\s*"english"\s*:\s*"([^"]+)"\s*,\s*"chinese"\s*:\s*"([^"]+)"\s*\}"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        regex?.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match,
                  let englishRange = Range(match.range(at: 1), in: text),
                  let chineseRange = Range(match.range(at: 2), in: text) else {
                return
            }
            
            let english = String(text[englishRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let chinese = String(text[chineseRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !english.isEmpty && !chinese.isEmpty {
                examples.append((english: english, chinese: chinese))
            }
        }
        
        return examples.isEmpty ? nil : examples
    }
    
    // 格式化原始例句文本
    private func formatRawExample(_ text: String) -> String {
        // 首先尝试清理和解析JSON格式
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果包含JSON格式，尝试提取英文和中文部分
        if cleanedText.contains("\"english\"") && cleanedText.contains("\"chinese\"") {
            // 尝试解析整个JSON数组
            if let parsedExamples = parseExamples(from: cleanedText) {
                var formattedLines: [String] = []
                for (index, example) in parsedExamples.enumerated() {
                    formattedLines.append("📝 例句 \(index + 1)")
                    formattedLines.append("🇺🇸 \(example.english)")
                    formattedLines.append("🇨🇳 \(example.chinese)")
                    if index < parsedExamples.count - 1 {
                        formattedLines.append("") // 添加空行分隔
                    }
                }
                return formattedLines.joined(separator: "\n")
            }
            
            // 如果JSON解析失败，尝试逐行提取
            let lines = cleanedText.components(separatedBy: CharacterSet.newlines)
            var formattedLines: [String] = []
            var currentExample = 1
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.contains("\"english\"") {
                    let english = extractValue(from: trimmedLine, key: "english")
                    if !english.isEmpty {
                        formattedLines.append("📝 例句 \(currentExample)")
                        formattedLines.append("🇺🇸 \(english)")
                    }
                } else if trimmedLine.contains("\"chinese\"") {
                    let chinese = extractValue(from: trimmedLine, key: "chinese")
                    if !chinese.isEmpty {
                        formattedLines.append("🇨🇳 \(chinese)")
                        formattedLines.append("") // 添加空行
                        currentExample += 1
                    }
                }
            }
            
            if !formattedLines.isEmpty {
                return formattedLines.joined(separator: "\n")
            }
        }
        
        // 如果不是JSON格式，但包含明显的英文和中文，尝试智能分割
        if text.contains("英文") || text.contains("中文") || text.contains("English") || text.contains("Chinese") {
            return formatMixedLanguageText(text)
        }
        
        // 最后回退到原始文本，但至少清理一下格式
        return cleanedText.replacingOccurrences(of: "\\n", with: "\n")
                         .replacingOccurrences(of: "\\\"", with: "\"")
    }
    
    private func extractValue(from line: String, key: String) -> String {
        let pattern = "\"\(key)\":\\s*\"([^\"]+)\""
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = regex?.firstMatch(in: line, range: range),
           let valueRange = Range(match.range(at: 1), in: line) {
            return String(line[valueRange])
        }
        
        return ""
    }
    
    // 格式化混合语言文本
    private func formatMixedLanguageText(_ text: String) -> String {
        let lines = text.components(separatedBy: CharacterSet.newlines)
        var formattedLines: [String] = []
        var currentExample = 1
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            // 检测是否包含英文句子（包含英文字母和句号）
            let hasEnglish = trimmedLine.rangeOfCharacter(from: CharacterSet.letters) != nil && 
                           trimmedLine.contains(where: { $0.isASCII && $0.isLetter })
            
            // 检测是否包含中文字符
            let hasChinese = trimmedLine.rangeOfCharacter(from: CharacterSet(charactersIn: "\u{4e00}"..."\u{9fff}")) != nil
            
            if hasEnglish && !hasChinese {
                formattedLines.append("📝 例句 \(currentExample)")
                formattedLines.append("🇺🇸 \(trimmedLine)")
            } else if hasChinese && !hasEnglish {
                formattedLines.append("🇨🇳 \(trimmedLine)")
                formattedLines.append("") // 添加空行
                currentExample += 1
            } else if hasEnglish && hasChinese {
                // 混合语言，尝试分割
                formattedLines.append("📝 例句 \(currentExample)")
                formattedLines.append("📄 \(trimmedLine)")
                formattedLines.append("") // 添加空行
                currentExample += 1
            } else {
                // 其他情况，直接添加
                formattedLines.append(trimmedLine)
            }
        }
        
        return formattedLines.joined(separator: "\n")
    }
}

// MARK: - 单个例句卡片
struct ExampleCard: View {
    let english: String
    let chinese: String
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(.blue)
                    .clipShape(Circle())
                
                Text("例句 \(index)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text("🇺🇸")
                        .font(.title3)
                    
                    Text(english)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Text("🇨🇳")
                        .font(.title3)
                    
                    Text(chinese)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 紧凑例句卡片组件
struct CompactExampleCard: View {
    let english: String
    let chinese: String
    let index: Int
    @StateObject private var phoneticService = PhoneticService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 英文例句（可点击发音）
            Button(action: {
                phoneticService.playEnglishText(english) {}
            }) {
                HStack(alignment: .top, spacing: 8) {
                    // 序号标识
                    Text("\(index)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(.green)
                        .clipShape(Circle())
                    
                    // 英文内容
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("🇺🇸")
                                .font(.caption)
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        
                        Text(english)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 中文翻译（不可点击）
            HStack(alignment: .top, spacing: 8) {
                // 占位空间对齐
                Text("")
                    .frame(width: 18, height: 18)
                
                // 中文内容
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("🇨🇳")
                            .font(.caption)
                        // 移除发音图标
                    }
                    
                    Text(chinese)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 词根词源信息显示组件
struct EtymologyInfoDisplay: View {
    let etymology: String?
    let relatedWords: [String]?
    @State private var isExpanded: Bool = false
    
    var body: some View {
        // 只有当有内容时才显示
        if hasContent {
            VStack(alignment: .leading, spacing: 12) {
                // 标题和展开/收起按钮
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                    
                    Text("词根词源")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 内容区域（可折叠）
                if isExpanded {
                    VStack(spacing: 12) {
                        // 词源信息
                        if let etymology = etymology, !etymology.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "book.closed")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    Text("词源")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                
                                Text(etymology)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(4)
                            }
                            .padding(10)
                            .background(.orange.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // 相关单词
                        if let relatedWords = relatedWords, !relatedWords.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                    Text("相关单词")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                                    ForEach(Array(relatedWords.prefix(6)), id: \.self) { word in
                                        Text(word)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(.purple.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                            }
                            .padding(10)
                            .background(.purple.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // 收起状态：显示简短预览
                    HStack(spacing: 8) {
                        if let etymology = etymology, !etymology.isEmpty {
                            Text("词源: \(String(etymology.prefix(20)))...")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        if let relatedWords = relatedWords, !relatedWords.isEmpty {
                            Text("相关: \(relatedWords.prefix(2).joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(12)
            .background(.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var hasContent: Bool {
        (etymology != nil && !etymology!.isEmpty) || 
        (relatedWords != nil && !relatedWords!.isEmpty)
    }
}

// MARK: - 基本单词信息视图（可控制显示内容）
struct BasicWordInfoView: View {
    let currentWord: StudyWord
    let currentWordIndex: Int
    let showImageAndTips: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧：单词图片（只在答题后显示）
            if showImageAndTips {
                WordImageView(imageURL: currentWord.imageURL, word: currentWord.word)
            } else {
                // 答题前显示占位符
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.gray.opacity(0.5))
                    )
            }
            
            // 右侧：单词基本信息
            VStack(alignment: .leading, spacing: 8) {
                // 单词类型和进度（始终显示）
                HStack(spacing: 8) {
                    if !currentWord.category.isEmpty {
                        Text(currentWord.category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    Text("第 \(currentWordIndex + 1) 个")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Spacer()
                }
                
                // 记忆技巧预览（只在答题后显示）
                if showImageAndTips {
                    if let memoryTip = currentWord.memoryTip, !memoryTip.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            
                            Text(String(memoryTip.prefix(30)) + (memoryTip.count > 30 ? "..." : ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                } else {
                    // 答题前显示提示文本
                    HStack(spacing: 6) {
                        Image(systemName: "eye.slash")
                            .font(.caption)
                            .foregroundStyle(.gray.opacity(0.5))
                        
                        Text("答题后显示记忆技巧")
                            .font(.caption)
                            .foregroundStyle(.gray.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - 单词信息头部视图（保留用于兼容性）
struct WordInfoHeaderView: View {
    let currentWord: StudyWord
    let currentWordIndex: Int
    
    var body: some View {
        BasicWordInfoView(
            currentWord: currentWord,
            currentWordIndex: currentWordIndex,
            showImageAndTips: true
        )
    }
}

#Preview {
    HybridLearningView(hybridManager: HybridLearningManager(appwriteService: AppwriteService()))
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}
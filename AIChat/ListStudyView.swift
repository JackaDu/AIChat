import SwiftUI

// MARK: - 列表学习模式视图
struct ListStudyView: View {
    @ObservedObject var hybridManager: HybridLearningManager
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var appwriteService: AppwriteService
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @StateObject private var phoneticService = PhoneticService()
    @StateObject private var studyRecordService: StudyRecordDatabaseService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentWords: [StudyWord] = []
    @State private var userAnswers: [String: Bool] = [:] // 用户答案记录
    @State private var showingResults = false
    @State private var studyCompleted = false
    @State private var correctCount = 0
    @State private var totalCount = 0
    @State private var isSavingData = false
    
    // 卡片模式相关状态
    @State private var showingCardMode = false
    
    // PDF导出相关状态
    @State private var showPDFExport = false
    
    init(hybridManager: HybridLearningManager) {
        self.hybridManager = hybridManager
        self._studyRecordService = StateObject(wrappedValue: StudyRecordDatabaseService(appwriteService: AppwriteService()))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部进度条和模式切换
                if !studyCompleted {
                    topControlsView
                }
                
                if studyCompleted {
                    // 完成界面
                    StudyCompletionView(
                        totalWords: totalCount,
                        correctAnswers: correctCount,
                        incorrectAnswers: totalCount - correctCount,
                        onRestart: {
                            restartStudy()
                        },
                        onExit: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                } else {
                    // 学习提示
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.caption)
                                Text("左滑删除（已掌握）")
                                    .font(.caption)
                            }
                            .foregroundStyle(.green)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("右滑标记生词")
                                    .font(.caption)
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.orange)
                        }
                        
                        Text("💡 点击查看答案不会记录学习状态，滑动操作会影响学习进度")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.gray.opacity(0.05))
                    
                    // 学习列表
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(currentWords) { word in
                                ListStudyWordCard(
                                    word: word,
                                    userAnswer: userAnswers[word.id.uuidString],
                                    onAnswer: { isCorrect in
                                        handleAnswer(for: word.id, isCorrect: isCorrect)
                                    },
                                    onDelete: {
                                        handleWordDelete(word: word)
                                    },
                                    onMarkAsWrongWord: {
                                        handleMarkAsWrongWord(word: word)
                                    },
                                    phoneticService: phoneticService
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
                
                // 底部操作按钮
                if !studyCompleted && userAnswers.count == currentWords.count {
                    VStack(spacing: 12) {
                        Button(action: {
                            saveDataAndExit()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16))
                                Text("完成学习")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isSavingData)
                        
                        if isSavingData {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("正在保存学习记录...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .background(.white)
                }
            }
            .navigationTitle("列表学习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("退出") {
                        saveDataAndExit()
                    }
                    .disabled(isSavingData)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showPDFExport = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(currentWords.isEmpty)
                }
            }
            .onAppear {
                setupStudy()
            }
            .fullScreenCover(isPresented: $showingCardMode) {
                // 使用完整的HybridLearningView来提供一致的卡片模式体验
                HybridLearningView(hybridManager: createCardModeManager())
                    .environmentObject(wrongWordManager)
                    .environmentObject(appwriteService)
                    .environmentObject(preferencesManager)
                    .onDisappear {
                        // 当卡片模式关闭时，同步学习进度
                        syncCardModeProgress()
                    }
            }
            .sheet(isPresented: $showPDFExport) {
                SharedPDFExportView(
                    words: currentWords,
                    title: "列表学习导出"
                )
            }
        }
    }
    
    // 计算属性：是否有未完成的题目
    private var hasUnansweredQuestions: Bool {
        userAnswers.count < currentWords.count
    }
    
    // 设置学习
    private func setupStudy() {
        currentWords = hybridManager.todayWords
        userAnswers.removeAll()
        studyCompleted = false
        correctCount = 0
        totalCount = currentWords.count
        
        print("📚 列表学习模式启动")
        print("- 单词数量: \(currentWords.count)")
        print("- 学习模式: 列表模式")
    }
    
    // 重新开始学习
    private func restartStudy() {
        setupStudy()
    }
    
    // 处理答案
    private func handleAnswer(for wordId: UUID, isCorrect: Bool) {
        userAnswers[wordId.uuidString] = isCorrect
        updateStudyProgress()
        
        // 如果答错了，添加到错题本
        if !isCorrect {
            if let word = currentWords.first(where: { $0.id == wordId }) {
                let wrongWord = WrongWord(
                    word: word.word,
                    meaning: word.meaning,
                    context: "列表学习模式",
                    learningDirection: .recognizeMeaning,
                    textbookSource: nil,
                    partOfSpeech: nil,
                    examSource: nil,
                    difficulty: .medium
                )
                wrongWordManager.addWrongWord(wrongWord)
                print("❌ 单词 \(word.word) 已添加到错题本")
            }
        }
        
        print("📝 用户答题: \(isCorrect ? "正确" : "错误")")
        print("- 当前进度: \(userAnswers.count)/\(currentWords.count)")
    }
    
    // 保存数据并退出
    private func saveDataAndExit() {
        guard !isSavingData else { return }
        
        isSavingData = true
        
        Task {
            do {
                // 保存学习记录
                for (wordIdString, isCorrect) in userAnswers {
                    if let wordId = UUID(uuidString: wordIdString),
                       let word = currentWords.first(where: { $0.id == wordId }) {
                        
                        let record = StudyRecord(
                            userId: appwriteService.currentUser?.id ?? "",
                            word: word.word,
                            meaning: word.meaning,
                            context: "列表学习模式",
                            learningDirection: .recognizeMeaning,
                            isCorrect: isCorrect,
                            answerTime: 0, // 列表模式不计时
                            memoryStrength: isCorrect ? 0.8 : 0.2,
                            streakCount: 0
                        )
                        
                        try await studyRecordService.createStudyRecord(record)
                    }
                }
                
                await MainActor.run {
                    isSavingData = false
                    presentationMode.wrappedValue.dismiss()
                }
                
                print("✅ 列表学习记录保存成功")
            } catch {
                await MainActor.run {
                    isSavingData = false
                }
                print("❌ 保存学习记录失败: \(error)")
            }
        }
    }
    
    // 启动卡片模式测验
    private func startCardModeTest() {
        // 直接显示卡片模式，不检查是否有未完成的题目
        showingCardMode = true
        
        print("✅ 卡片模式测验已启动")
        print("- showingCardMode: \(showingCardMode)")
        print("- currentWords.count: \(currentWords.count)")
        print("- userAnswers.count: \(userAnswers.count)")
        print("- 允许在任何时候启动卡片测验")
    }
    
    // 创建卡片模式管理器
    private func createCardModeManager() -> HybridLearningManager {
        let cardManager = HybridLearningManager(appwriteService: appwriteService)
        
        // 设置为从列表模式跳转
        cardManager.isFromListMode = true
        
        // 传递当前单词列表
        cardManager.todayWords = currentWords
        
        print("🎯 创建卡片模式管理器")
        print("- 单词数量: \(currentWords.count)")
        print("- 来自列表模式: true")
        
        return cardManager
    }
    
    // 同步卡片模式进度
    private func syncCardModeProgress() {
        // 这里可以添加从卡片模式同步学习进度的逻辑
        // 目前保持现有的学习进度不变
        print("🔄 卡片模式已关闭，保持列表模式进度")
    }
    
    // 更新学习进度
    private func updateStudyProgress() {
        correctCount = userAnswers.values.filter { $0 }.count
        studyCompleted = userAnswers.count >= currentWords.count
        
        print("📊 学习进度更新:")
        print("- 已完成: \(userAnswers.count)/\(currentWords.count)")
        print("- 正确率: \(correctCount)/\(userAnswers.count)")
        print("- 学习完成: \(studyCompleted)")
    }
    
    // 处理单词删除（标记为已掌握）
    private func handleWordDelete(word: StudyWord) {
        print("🗑️ 删除单词（标记为已掌握）: \(word.word)")
        
        // 从当前单词列表中移除
        currentWords.removeAll { $0.id == word.id }
        
        // 从用户答案中移除
        userAnswers.removeValue(forKey: word.id.uuidString)
        
        // 更新总数
        totalCount = currentWords.count
        
        // 更新学习进度
        updateStudyProgress()
        
        // 创建学习记录（标记为已掌握）
        let studyRecord = StudyRecord(
            userId: appwriteService.currentUser?.id ?? "",
            word: word.word,
            meaning: word.meaning,
            context: "列表学习模式 - 标记为已掌握",
            learningDirection: .recognizeMeaning,
            isCorrect: true,
            answerTime: 0,
            memoryStrength: 1.0, // 已掌握设为最高强度
            streakCount: 1
        )
        
        Task {
            do {
                try await studyRecordService.createStudyRecord(studyRecord)
                print("✅ 已掌握记录保存成功: \(word.word)")
            } catch {
                print("❌ 保存已掌握记录失败: \(error)")
            }
        }
        
        print("📊 删除后状态:")
        print("- 剩余单词数: \(currentWords.count)")
        print("- 已答题数: \(userAnswers.count)")
    }
    
    // 处理标记为生词
    private func handleMarkAsWrongWord(word: StudyWord) {
        print("⭐ 标记为生词: \(word.word)")
        
        // 添加到错题本
        let wrongWord = WrongWord(
            word: word.word,
            meaning: word.meaning,
            context: "列表学习模式 - 手动标记",
            learningDirection: .recognizeMeaning,
            textbookSource: nil,
            partOfSpeech: nil,
            examSource: nil,
            difficulty: .medium
        )
        
        wrongWordManager.addWrongWord(wrongWord)
        
        // 记录为错误答案
        userAnswers[word.id.uuidString] = false
        
        // 更新学习进度
        updateStudyProgress()
        
        // 创建学习记录（标记为生词）
        let studyRecord = StudyRecord(
            userId: appwriteService.currentUser?.id ?? "",
            word: word.word,
            meaning: word.meaning,
            context: "列表学习模式 - 标记为生词",
            learningDirection: .recognizeMeaning,
            isCorrect: false,
            answerTime: 0,
            memoryStrength: 0.2, // 生词设为较低强度
            streakCount: 0
        )
        
        Task {
            do {
                try await studyRecordService.createStudyRecord(studyRecord)
                print("✅ 生词记录保存成功: \(word.word)")
            } catch {
                print("❌ 保存生词记录失败: \(error)")
            }
        }
        
        print("📝 标记生词完成:")
        print("- 已添加到错题本: \(word.word)")
        print("- 当前进度: \(userAnswers.count)/\(currentWords.count)")
    }
    
    // 顶部控制区域视图
    private var topControlsView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("列表学习模式")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(userAnswers.count)/\(currentWords.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 显示模式切换器 - 优化排版，分两行显示
            VStack(spacing: 8) {
                // 第一行：文字显示模式
                HStack(spacing: 8) {
                    Text("显示模式:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(ListDisplayMode.allCases, id: \.self) { mode in
                            Button(action: {
                                preferencesManager.userPreferences.listDisplayMode = mode
                            }) {
                                HStack(spacing: 4) {
                                    Text(mode.emoji)
                                        .font(.caption)
                                    Text(mode.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(preferencesManager.userPreferences.listDisplayMode == mode ? 
                                              Color.blue.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(preferencesManager.userPreferences.listDisplayMode == mode ? 
                                                Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Spacer()
                }
                
                // 第二行：图片显示控制
                HStack(spacing: 8) {
                    Text("图片显示:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        preferencesManager.userPreferences.showImagesInList.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: preferencesManager.userPreferences.showImagesInList ? "photo" : "photo.slash")
                                .font(.caption)
                            Text(preferencesManager.userPreferences.showImagesInList ? "显示图片" : "隐藏图片")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(preferencesManager.userPreferences.showImagesInList ? 
                                      Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(preferencesManager.userPreferences.showImagesInList ? 
                                        Color.green : Color.gray, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            
            // 卡片测验按钮
            Button(action: {
                startCardModeTest()
            }) {
                HStack {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 16))
                    Text("卡片测验")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(PlainButtonStyle())
            
            // 进度条
            ProgressView(value: Double(userAnswers.count), total: Double(currentWords.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.white)
    }
}

// MARK: - 列表学习单词卡片
struct ListStudyWordCard: View {
    let word: StudyWord
    let userAnswer: Bool?
    let onAnswer: (Bool) -> Void
    let onDelete: () -> Void // 新增：删除回调（标记为已掌握）
    let onMarkAsWrongWord: () -> Void // 新增：标记为生词回调
    @ObservedObject var phoneticService: PhoneticService
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var wrongWordManager: WrongWordManager
    
    @State private var phonetic: String?
    @State private var showingAnswer = false
    @State private var dragOffset: CGFloat = 0
    @State private var isSwipeActionTriggered = false
    @State private var showDeleteButton = false
    
    var body: some View {
        ZStack {
            // 背景删除按钮 - 类似"熟知"按钮的样式
            HStack {
                Spacer()
                if showDeleteButton {
                    Button(action: {
                        confirmDelete()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                            Text("已掌握")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 90, height: 90)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.teal, Color.cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .teal.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 16)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            
            // 主要内容卡片
            VStack(spacing: 16) {
                // 根据显示模式显示内容
                switch preferencesManager.userPreferences.listDisplayMode {
                case .hideChinese:
                    // 遮住中文模式：只显示英文
                    englishOnlyView
                case .hideEnglish:
                    // 遮住英文模式：只显示中文
                    chineseOnlyView
                case .showAll:
                    // 都显示模式：同时显示英文和中文
                    bothDisplayView
                }
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            .offset(x: dragOffset)
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    guard !isSwipeActionTriggered else { return }
                    
                    // 检查滑动方向，要求更严格的条件
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    let isValidHorizontalSwipe = horizontalMovement > verticalMovement * 2 && horizontalMovement > 20
                    
                    // 调试：输出滑动开始信息
                    if horizontalMovement > 10 {
                        print("🎯 滑动检测: horizontal=\(horizontalMovement), vertical=\(verticalMovement), valid=\(isValidHorizontalSwipe)")
                    }
                    
                    if isValidHorizontalSwipe {
                        // 限制左滑距离，最多滑动120px以容纳按钮
                        if value.translation.width < 0 {
                            dragOffset = max(value.translation.width, -120)
                        } else {
                            dragOffset = value.translation.width
                        }
                        
                        // 当左滑超过60px时显示删除按钮
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showDeleteButton = dragOffset < -60
                        }
                        
                        // 调试日志
                        print("🔄 滑动中: dragOffset=\(dragOffset), showDeleteButton=\(showDeleteButton), translation=\(value.translation.width)")
                    }
                }
                .onEnded { value in
                    guard !isSwipeActionTriggered else { return }
                    
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    let isValidHorizontalSwipe = horizontalMovement > verticalMovement * 2 && horizontalMovement > 50
                    
                    if isValidHorizontalSwipe {
                        let threshold: CGFloat = 80
                        
                        if value.translation.width > threshold {
                            // 右滑 - 标记为生词
                            handleRightSwipe()
                        } else if value.translation.width < -threshold {
                            // 左滑 - 保持删除按钮显示状态
                            print("✅ 左滑触发: 固定显示删除按钮")
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                dragOffset = -100 // 固定在显示删除按钮的位置
                                showDeleteButton = true
                            }
                        } else {
                            // 未达到阈值，重置
                            resetOffset()
                        }
                    } else {
                        // 不符合条件，重置偏移
                        resetOffset()
                    }
                }
        )
        .onTapGesture {
            // 如果删除按钮正在显示，点击卡片时隐藏删除按钮
            if showDeleteButton {
                resetOffset()
            } else {
                // 点击整个卡片时播放发音
                print("🎵 用户点击卡片播放发音: \(word.word)")
                phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
            }
        }
        .onAppear {
            loadPhonetic()
        }
    }
    
    // MARK: - 滑动处理方法
    
    private func handleLeftSwipe() {
        print("⬅️ 左滑触发删除按钮显示: \(word.word)")
        isSwipeActionTriggered = true
        // 删除按钮的显示已经在手势中处理了
    }
    
    private func handleRightSwipe() {
        print("➡️ 右滑标记为生词: \(word.word)")
        isSwipeActionTriggered = true
        
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 执行标记生词操作
        onMarkAsWrongWord()
        
        // 重置状态
        resetOffset()
    }
    
    private func confirmDelete() {
        print("🎯 点击删除按钮: \(word.word)")
        print("✅ 确认删除（标记为已掌握）: \(word.word)")
        
        // 添加成功的触觉反馈
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        // 执行删除操作
        onDelete()
        
        // 重置状态
        resetOffset()
    }
    
    private func resetOffset() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = 0
            showDeleteButton = false
        }
        isSwipeActionTriggered = false
    }
    
    private func loadPhonetic() {
        phonetic = phoneticService.getPhoneticSymbol(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType)
    }
    
    // MARK: - 遮住中文模式：只显示英文
    private var englishOnlyView: some View {
        VStack(spacing: 16) {
            // 英文单词信息（点击整个区域发音）
            Button(action: {
                phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.word)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        ClickablePhoneticView(word: word.word)
                    }
                    
                    Spacer()
                    
                    // 图片和发音按钮
                    HStack(spacing: 8) {
                        // 单词图片（根据设置显示或隐藏）
                        if preferencesManager.userPreferences.showImagesInList {
                            WordImageView(imageURL: word.imageURL, word: word.word)
                        }
                        
                        // 记忆辅助信息
                        MemoryAidView(
                            etymology: word.etymology,
                            memoryTip: word.memoryTip,
                            relatedWords: word.relatedWords,
                            example: word.example
                        )
                        
                        // 发音按钮图标
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                            .padding(8)
                            .background(.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 固定高度的中文意思显示区域
            HStack {
                if showingAnswer || userAnswer != nil {
                    // 只显示中文意思
                    Text(word.meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                } else {
                    // 显示提示按钮
                    Button(action: {
                        print("📖 用户点击显示中文: \(word.word)")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAnswer = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "eye")
                                .font(.caption)
                            Text("点击查看中文含义")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // 答案状态显示
                answerStatusView
            }
            .frame(height: 32) // 恢复固定高度
            .padding(.horizontal, 12)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - 遮住英文模式：只显示中文
    private var chineseOnlyView: some View {
        VStack(spacing: 16) {
            // 中文意思信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if showingAnswer || userAnswer != nil {
                        // 显示英文单词（点击整个区域发音）
                        Button(action: {
                            phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(word.word)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                    
                                    ClickablePhoneticView(word: word.word)
                                }
                                
                                Spacer()
                                
                                // 图片和发音按钮
                                HStack(spacing: 8) {
                                    // 单词图片（根据设置显示或隐藏）
                                    if preferencesManager.userPreferences.showImagesInList {
                                        WordImageView(imageURL: word.imageURL, word: word.word)
                                    }
                                    
                                    // 记忆辅助信息
                                    MemoryAidView(
                                        etymology: word.etymology,
                                        memoryTip: word.memoryTip,
                                        relatedWords: word.relatedWords,
                                        example: word.example
                                    )
                                    
                                    // 发音按钮图标
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.blue)
                                        .padding(8)
                                        .background(.blue.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // 显示提示按钮
                        Button(action: {
                            print("📖 用户点击显示英文: \(word.meaning)")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingAnswer = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "eye")
                                    .font(.caption)
                                Text("点击查看英文单词")
                                    .font(.caption)
                            }
                            .foregroundStyle(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            
            // 固定高度的中文意思显示区域
            HStack {
                // 始终显示中文意思
                Text(word.meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // 答案状态显示
                answerStatusView
            }
            .frame(height: 32) // 恢复固定高度
            .padding(.horizontal, 12)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - 都显示模式：同时显示英文和中文
    private var bothDisplayView: some View {
        VStack(spacing: 16) {
            // 英文单词信息（点击整个区域发音）
            Button(action: {
                phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.word)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        ClickablePhoneticView(word: word.word)
                    }
                    
                    Spacer()
                    
                    // 图片和发音按钮
                    HStack(spacing: 8) {
                        // 单词图片（根据设置显示或隐藏）
                        if preferencesManager.userPreferences.showImagesInList {
                            WordImageView(imageURL: word.imageURL, word: word.word)
                        }
                        
                        // 记忆辅助信息
                        MemoryAidView(
                            etymology: word.etymology,
                            memoryTip: word.memoryTip,
                            relatedWords: word.relatedWords,
                            example: word.example
                        )
                        
                        // 发音按钮图标
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                            .padding(8)
                            .background(.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 固定高度的中文意思显示区域
            HStack {
                // 始终显示中文意思
                Text(word.meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // 答案状态显示
                answerStatusView
            }
            .frame(height: 32) // 恢复固定高度
            .padding(.horizontal, 12)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - 答案状态显示视图
    private var answerStatusView: some View {
        Group {
            if let answer = userAnswer {
                if answer {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("已掌握")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("待复习")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}


// MARK: - 学习完成视图
struct StudyCompletionView: View {
    let totalWords: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let onRestart: () -> Void
    let onExit: () -> Void
    
    var accuracy: Double {
        guard totalWords > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalWords)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 完成图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            // 完成标题
            Text("学习完成！")
                .font(.title)
                .fontWeight(.bold)
            
            // 学习统计
            VStack(spacing: 16) {
                HStack {
                    VStack {
                        Text("\(totalWords)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("总单词数")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(correctAnswers)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Text("已掌握")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(incorrectAnswers)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                        Text("待复习")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 40)
                
                // 准确率
                VStack(spacing: 8) {
                    Text("掌握率")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(accuracy * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(accuracy >= 0.8 ? .green : accuracy >= 0.6 ? .orange : .red)
                }
            }
            .padding(20)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // 操作按钮
            VStack(spacing: 12) {
                Button(action: onRestart) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新学习")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onExit) {
                    HStack {
                        Image(systemName: "house")
                        Text("返回主页")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(40)
    }
}

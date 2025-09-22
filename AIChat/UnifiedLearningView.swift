import SwiftUI

// MARK: - 统一学习视图
struct UnifiedLearningView: View {
    @StateObject private var modeManager = UnifiedModeManager()
    @ObservedObject var hybridManager: HybridLearningManager
    @ObservedObject var phoneticService: PhoneticService
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    
    // 初始模式
    let initialMode: LearningModeType
    
    // 当前学习状态
    @State private var currentWordIndex: Int = 0
    @State private var currentWrongWord: StudyWord?
    @State private var showInlineSpelling: Bool = false
    @State private var inlineSpellingWord: StudyWord?
    
    init(hybridManager: HybridLearningManager, initialMode: LearningModeType = .card) {
        self.hybridManager = hybridManager
        self.phoneticService = PhoneticService()
        self.initialMode = initialMode
    }
    
    var body: some View {
        ZStack {
            // 主学习内容
            mainLearningContent
            
            // 内嵌面板容器
            EmbeddedPanelContainer(
                modeManager: modeManager,
                wrongWord: currentWrongWord
            )
            
            // 内联拼写面板
            if showInlineSpelling, let word = inlineSpellingWord {
                InlineSpellingPanel(
                    word: word,
                    onComplete: { isCorrect in
                        handleInlineSpellingComplete(isCorrect: isCorrect)
                    },
                    onCancel: {
                        hideInlineSpelling()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                modeToggleButton
            }
        }
        .onAppear {
            setupInitialMode()
        }
        .onChange(of: modeManager.currentMode) { _, newMode in
            handleModeChange(to: newMode)
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainLearningContent: some View {
        switch modeManager.currentMode {
        case .card:
            CardModeView(
                hybridManager: hybridManager,
                phoneticService: phoneticService,
                onWrongAnswer: { wrongWord in
                    handleWrongAnswer(wrongWord)
                },
                onSessionComplete: { stats in
                    handleSessionComplete(stats)
                }
            )
            
        case .list:
            ListModeView(
                hybridManager: hybridManager,
                onWrongAnswer: { wrongWord in
                    handleWrongAnswer(wrongWord)
                },
                onSessionComplete: { stats in
                    handleSessionComplete(stats)
                },
                onWordDetail: { word in
                    // 跳转到卡片详情（全页）
                    showWordDetail(word)
                }
            )
            
        case .spelling:
            SpellingModeView(
                hybridManager: hybridManager,
                phoneticService: phoneticService,
                onCorrectAnswer: {
                    handleSpellingCorrect()
                },
                onWrongAnswer: { wrongWord in
                    handleSpellingWrong(wrongWord)
                },
                onSessionComplete: { stats in
                    handleSessionComplete(stats)
                }
            )
        }
    }
    
    // MARK: - Mode Toggle Button
    private var modeToggleButton: some View {
        Menu {
            Button(action: {
                modeManager.handleUserModeSwitch(to: .card, from: modeManager.currentMode)
            }) {
                Label("卡片模式", systemImage: "rectangle.on.rectangle")
            }
            
            Button(action: {
                modeManager.handleUserModeSwitch(to: .list, from: modeManager.currentMode)
            }) {
                Label("列表模式", systemImage: "list.bullet")
            }
            
            Button(action: {
                modeManager.handleUserModeSwitch(to: .spelling, from: modeManager.currentMode)
            }) {
                Label("拼写模式", systemImage: "keyboard")
            }
        } label: {
            Image(systemName: modeManager.currentMode.icon)
                .font(.title3)
        }
    }
    
    // MARK: - Event Handlers
    
    private func setupInitialMode() {
        modeManager.startNewSession(mode: initialMode)
    }
    
    private func handleModeChange(to newMode: LearningModeType) {
        print("🔄 模式切换到: \(newMode.description)")
        // 这里可以添加模式切换时的特殊逻辑
    }
    
    private func handleWrongAnswer(_ wrongWord: StudyWord) {
        currentWrongWord = wrongWord
        modeManager.handleWrongAnswer(wrongWord: wrongWord, currentMode: modeManager.currentMode)
    }
    
    private func handleSessionComplete(_ stats: SessionStats) {
        modeManager.handleSessionEnd(stats: stats, currentMode: modeManager.currentMode)
    }
    
    private func handleSpellingCorrect() {
        // 拼写正确，返回原会话
        if showInlineSpelling {
            hideInlineSpelling()
        }
        // 继续下一题或返回原模式
    }
    
    private func handleSpellingWrong(_ wrongWord: StudyWord) {
        // 拼写错误，提示查看卡片/释义
        // 这里可以显示一个简单的提示面板
    }
    
    private func showWordDetail(_ word: StudyWord) {
        // 跳转到卡片详情（全页）
        modeManager.handleUserModeSwitch(to: .card, from: modeManager.currentMode)
    }
    
    // MARK: - Inline Spelling Methods
    
    private func showInlineSpelling(for word: StudyWord) {
        inlineSpellingWord = word
        showInlineSpelling = true
    }
    
    private func hideInlineSpelling() {
        showInlineSpelling = false
        inlineSpellingWord = nil
    }
    
    private func handleInlineSpellingComplete(isCorrect: Bool) {
        hideInlineSpelling()
        
        if isCorrect {
            // 拼写正确，继续原模式
            handleSpellingCorrect()
        } else {
            // 拼写错误，可能需要进一步处理
            if let word = inlineSpellingWord {
                handleSpellingWrong(word)
            }
        }
    }
}

// MARK: - 内联拼写面板
struct InlineSpellingPanel: View {
    let word: StudyWord
    let onComplete: (Bool) -> Void
    let onCancel: () -> Void
    
    @State private var userInput: String = ""
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("拼写练习")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 中文含义
                Text(word.meaning)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                // 输入框
                TextField("输入英文单词", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                    .keyboardType(.asciiCapable)
                    .textCase(.lowercase)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        checkAnswer()
                    }
                
                // 结果显示
                if showResult {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                        
                        Text(isCorrect ? "正确！" : "正确答案: \(word.word)")
                            .font(.subheadline)
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    .padding(.vertical, 8)
                }
                
                // 操作按钮
                if showResult {
                    Button(action: {
                        onComplete(isCorrect)
                    }) {
                        Text("继续")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: checkAnswer) {
                        Text("提交")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(userInput.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(userInput.isEmpty)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
        .background(Color.black.opacity(0.3))
        .ignoresSafeArea()
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func checkAnswer() {
        let correct = userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == word.word.lowercased()
        isCorrect = correct
        showResult = true
        isInputFocused = false
    }
}

// MARK: - 占位符视图（待实现具体的模式视图）
struct CardModeView: View {
    let hybridManager: HybridLearningManager
    let phoneticService: PhoneticService
    let onWrongAnswer: (StudyWord) -> Void
    let onSessionComplete: (SessionStats) -> Void
    
    var body: some View {
        VStack {
            Text("卡片模式")
                .font(.title)
            Text("选择题形式")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 这里将集成现有的卡片学习逻辑
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ListModeView: View {
    let hybridManager: HybridLearningManager
    let onWrongAnswer: (StudyWord) -> Void
    let onSessionComplete: (SessionStats) -> Void
    let onWordDetail: (StudyWord) -> Void
    
    var body: some View {
        VStack {
            Text("列表模式")
                .font(.title)
            Text("批量学习")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 这里将集成现有的列表学习逻辑
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SpellingModeView: View {
    let hybridManager: HybridLearningManager
    let phoneticService: PhoneticService
    let onCorrectAnswer: () -> Void
    let onWrongAnswer: (StudyWord) -> Void
    let onSessionComplete: (SessionStats) -> Void
    
    var body: some View {
        VStack {
            Text("拼写模式")
                .font(.title)
            Text("填空练习")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 这里将集成现有的拼写学习逻辑
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        UnifiedLearningView(
            hybridManager: HybridLearningManager(
                appwriteService: AppwriteService()
            ),
            initialMode: .card
        )
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
    }
}

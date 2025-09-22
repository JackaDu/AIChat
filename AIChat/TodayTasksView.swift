import SwiftUI
import UIKit

// MARK: - 震动反馈
class HapticFeedback {
    func success() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    func error() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
}

// MARK: - 遗忘曲线动画组件
struct ForgettingCurveAnimation: View {
    @State private var animationProgress: CGFloat = 0
    @State private var pointOffset: CGFloat = 0
    @State private var pointColor: Color = .orange
    @State private var showingFeedback = false
    
    let isCorrect: Bool
    let word: String
    
    var body: some View {
        ZStack {
            // 背景曲线
            ForgettingCurvePath()
                .stroke(.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 200, height: 100)
            
            // 动画点
            Circle()
                .fill(pointColor)
                .frame(width: 12, height: 12)
                .offset(x: -80 + (animationProgress * 160), y: pointOffset)
                .scaleEffect(showingFeedback ? 1.5 : 1.0)
                .shadow(color: pointColor.opacity(0.5), radius: showingFeedback ? 8 : 4)
            
            // 反馈文字
            if showingFeedback {
                VStack {
                    Text(isCorrect ? "记忆增强 ↑" : "遗忘风险 ↑")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isCorrect ? .green : .red)
                        .offset(y: -40)
                    
                    Text(word)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .offset(y: 30)
                }
                .opacity(showingFeedback ? 1 : 0)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 点移动动画
        withAnimation(.easeInOut(duration: 1.0)) {
            animationProgress = 1.0
        }
        
        // 延迟显示结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                if isCorrect {
                    pointColor = .green
                    pointOffset = -15 // 上升
                } else {
                    pointColor = .red
                    pointOffset = 15 // 下降
                }
                showingFeedback = true
            }
        }
        
        // 缩放动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showingFeedback = true
            }
        }
    }
}

// MARK: - 遗忘曲线路径
struct ForgettingCurvePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // 绘制典型的遗忘曲线
        path.move(to: CGPoint(x: 0, y: height * 0.2))
        
        // 使用贝塞尔曲线绘制遗忘曲线
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height * 0.5),
            control1: CGPoint(x: width * 0.1, y: height * 0.25),
            control2: CGPoint(x: width * 0.2, y: height * 0.35)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.7),
            control1: CGPoint(x: width * 0.4, y: height * 0.6),
            control2: CGPoint(x: width * 0.55, y: height * 0.65)
        )
        
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.8),
            control1: CGPoint(x: width * 0.8, y: height * 0.75),
            control2: CGPoint(x: width * 0.9, y: height * 0.78)
        )
        
        return path
    }
}

// MARK: - 首页今日任务板块
struct TodayTasksView: View {
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var motivationSystem = MotivationSystem()
    @StateObject private var reviewModeManager = ReviewModeManager()
    @StateObject private var hybridManager: HybridLearningManager // 共享的学习管理器
    @StateObject private var wordDataManager: WordDataManager // 添加WordDataManager
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var appwriteService: AppwriteService
    
    @State private var showingUrgentReview = false
    @State private var showingSmartLearning = false
    @State private var showingDictationMode = false // 新增：听写模式状态
    @State private var showingParentDictationMode = false // 新增：家长听写模式状态
    
    init() {
        // 注意：这里无法直接访问@EnvironmentObject，需要在onAppear中初始化
        self._hybridManager = StateObject(wrappedValue: HybridLearningManager(appwriteService: AppwriteService()))
        self._wordDataManager = StateObject(wrappedValue: WordDataManager(appwriteService: AppwriteService()))
    }
    @State private var showingListLearning = false
    @State private var showingStudyAmountSelection = false
    @State private var hasShownStudyAmountSelection = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 1. 记忆健康状态（遗忘曲线）
                if !wrongWordManager.wrongWords.isEmpty {
                    MemoryHealthCard(manager: wrongWordManager)
                }
                
                // 2. 今日任务卡片（核心功能）
                TodayTaskCards(
                    showingSmartLearning: $showingSmartLearning,
                    showingListLearning: $showingListLearning,
                    showingUrgentReview: $showingUrgentReview,
                    showingStudyAmountSelection: $showingStudyAmountSelection,
                    showingDictationMode: $showingDictationMode, // 新增：传递听写模式状态
                    showingParentDictationMode: $showingParentDictationMode, // 新增：传递家长听写模式状态
                    wrongWordManager: wrongWordManager,
                    preferencesManager: preferencesManager
                )
                
                // 2. 快速设置（精简版）
                QuickSettingsCard(preferencesManager: preferencesManager)
                
                
                // 底部留白
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            .padding(.bottom, 40)
        }
        .background(
            themeManager.isNightMode ? NightModeStyle.primaryBackground : DayModeStyle.primaryBackground
        )

        .fullScreenCover(isPresented: $showingSmartLearning) {
            HybridLearningView(hybridManager: hybridManager)
                .environmentObject(preferencesManager)
                .environmentObject(wrongWordManager)
                .environmentObject(appwriteService)
                .environmentObject(themeManager)
                .themeAware(themeManager: themeManager)
        }
        
        .fullScreenCover(isPresented: $showingListLearning) {
            ListStudyView(hybridManager: hybridManager)
                .environmentObject(wrongWordManager)
                .environmentObject(appwriteService)
                .environmentObject(themeManager)
                .themeAware(themeManager: themeManager)
        }
        
        .fullScreenCover(isPresented: $showingDictationMode) {
            // 听写模式：使用HybridLearningView并设置为听写模式
            DictationModeMainView(hybridManager: hybridManager)
                .environmentObject(preferencesManager)
                .environmentObject(wrongWordManager)
                .environmentObject(appwriteService)
                .environmentObject(themeManager)
                .themeAware(themeManager: themeManager)
        }
        .fullScreenCover(isPresented: $showingParentDictationMode) {
            // 家长听写模式
            ParentDictationView(hybridManager: hybridManager)
                .environmentObject(preferencesManager)
                .environmentObject(wrongWordManager)
                .environmentObject(appwriteService)
                .environmentObject(themeManager)
                .themeAware(themeManager: themeManager)
        }

        .sheet(isPresented: $showingStudyAmountSelection) {
            StudyAmountSelectionView()
                .environmentObject(preferencesManager)
        }
        .fullScreenCover(isPresented: $showingUrgentReview) {
            UrgentReviewQuizView()
                .environmentObject(wrongWordManager)
                .environmentObject(wordDataManager)
                .environmentObject(themeManager)
                .themeAware(themeManager: themeManager)
        }
        .onAppear {
            // 检查是否需要首次选择学习量（只在首次启动且未显示过时）
            if preferencesManager.userPreferences.isFirstLaunch && 
               preferencesManager.needsStudyAmountSelection() && 
               !hasShownStudyAmountSelection {
                hasShownStudyAmountSelection = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingStudyAmountSelection = true
                }
            }
            
            // 预加载学习单词，确保两种学习模式都有数据
            Task {
                // 预加载单词数据
                await hybridManager.preloadAllWords(preferencesManager: preferencesManager)
                
                // 生成今日学习单词
                let targetCount = preferencesManager.userPreferences.dailyStudyAmount.rawValue
                let learningMode = preferencesManager.userPreferences.defaultLearningMode
                await hybridManager.generateTodayWords(learningMode: learningMode, targetCount: targetCount)
                
                print("✅ 单词预加载完成，今日学习单词数量: \(hybridManager.todayWords.count)")
            }
        }
    }
}

// MARK: - 欢迎Hero区域
private struct WelcomeHeroSection: View {
    @StateObject private var motivationSystem = MotivationSystem()
    
    var body: some View {
        VStack(spacing: 20) {
            // 主标题
            VStack(spacing: 8) {
                Text("🧠 智能错题本")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("科学记忆，高效复习")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
            }
            
            // 连续学习天数
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                    
                    Text("连续学习")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(motivationSystem.consecutiveDays)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    
                    Text("天")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Text("坚持就是胜利！")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [.orange.opacity(0.1), .yellow.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 任务统计概览
private struct TaskOverviewSection: View {
    @StateObject private var wrongWordManager = WrongWordManager()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📊 今日概览")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                TodayTaskStatItem(
                    title: "总单词",
                    value: "\(wrongWordManager.totalWordsCount)",
                    icon: "list.bullet",
                    color: Color.blue
                )
                
                TodayTaskStatItem(
                    title: "待复习",
                    value: "\(wrongWordManager.unmasteredWordsCount)",
                    icon: "clock.fill",
                    color: Color.orange
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

// MARK: - 学习进度卡片
private struct TodayLearningProgressCard: View {
    @StateObject private var wrongWordManager = WrongWordManager()
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("学习进度")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("基于艾宾浩斯遗忘曲线")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 进度环
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("75%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }
            
            // 三个核心指标
            HStack(spacing: 16) {
                ProgressIndicator(
                    title: "总词汇",
                    value: wrongWordManager.totalWordsCount,
                    icon: "book.fill",
                    color: Color.blue
                )
                
                ProgressIndicator(
                    title: "待复习",
                    value: wrongWordManager.unmasteredWordsCount,
                    icon: "clock.arrow.circlepath",
                    color: Color.orange
                )
                
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - 进度指标
private struct ProgressIndicator: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}



// MARK: - 快速行动按钮
private struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 复习区域
private struct ReviewSection: View {
    @StateObject private var wrongWordManager = WrongWordManager()
    @StateObject private var excelImporter = WordDataManager(appwriteService: AppwriteService())
    @State private var showingUrgentReview = false
    @StateObject private var preferencesManager = UserPreferencesManager(appwriteService: AppwriteService())
    
    var body: some View {
        VStack(spacing: 16) {
            // 区域标题
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(.red)
                
                Text("今日复习")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(wrongWordManager.urgentWordsCount)词")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            // 复习内容
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("需要复习的单词")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("根据艾宾浩斯遗忘曲线安排")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showingUrgentReview = true
                    } label: {
                        Text("开始复习")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
            }
        }
        .padding(20)
        .background(.red.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            // 数据已经从数据库加载，无需额外导入
        }
        .fullScreenCover(isPresented: $showingUrgentReview) {
            UrgentReviewQuizView()
                .environmentObject(wrongWordManager)
                .environmentObject(excelImporter)
        }
    }
}

// MARK: - 新词区域
private struct NewWordSection: View {
    @StateObject private var wrongWordManager = WrongWordManager()
    @State private var showingNewWordTest = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 区域标题
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                Text("新词检测")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("5词")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            // 新词内容
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日推荐新单词")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("基于您的学习进度和难度")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showingNewWordTest = true
                    } label: {
                        Text("开始检测")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                // 新词进度
                HStack {
                    ProgressView(value: 0.0, total: 5.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    
                    Text("0/5")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingNewWordTest) {
            // 这里可以导航到新词检测界面
            Text("新词检测界面")
        }
    }
}












// MARK: - 新词检测视图
private struct NewWordDetectionView: View {
    @ObservedObject var newWordManager: NewWordManager
    let onDetectionComplete: () -> Void
    @StateObject private var wrongWordManager = WrongWordManager()
    
    // 待测试的单词列表
    @State private var testWords: [TestWord] = []
    @State private var currentWordIndex = 0
    @State private var selectedAnswer: String = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var options: [String] = []
    @State private var completedTests: [TestWordResult] = []
    @State private var showCurveAnimation = false
    
    private var currentWord: TestWord? {
        guard currentWordIndex < testWords.count else { return nil }
        return testWords[currentWordIndex]
    }
    
    private var isTestComplete: Bool {
        currentWordIndex >= testWords.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if isTestComplete {
                // 测试完成界面
                VStack(spacing: 32) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)
                    
                    VStack(spacing: 12) {
                        Text("检测完成！")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        let wrongCount = completedTests.filter { !$0.isCorrect }.count
                        if wrongCount > 0 {
                            Text("发现 \(wrongCount) 个不认识的单词，已加入错题本")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("太棒了！所有单词都认识")
                                .font(.body)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Button("返回首页") {
                        onDetectionComplete()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 40)
                }
            } else if let word = currentWord {
                // 测试界面
                VStack(spacing: 24) {
                    // 进度显示
                    VStack(spacing: 8) {
                        HStack {
                            Text("新词检测")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(currentWordIndex + 1) / \(testWords.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        ProgressView(value: Double(currentWordIndex), total: Double(testWords.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 单词卡片
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text(word.word)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            Text("[\(word.phonetic)]")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            
                            if !showResult {
                                Text("你认识这个单词吗？")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            } else {
                                VStack(spacing: 12) {
                                    Text(isCorrect ? "✅ 认识" : "❌ 不认识")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(isCorrect ? .green : .red)
                                    
                                    // 遗忘曲线动画
                                    if showCurveAnimation {
                                        ForgettingCurveAnimation(isCorrect: isCorrect, word: word.word)
                                            .transition(.opacity.combined(with: .scale))
                                    }
                                    
                                    Text("正确答案：\(word.meaning)")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        if !showResult {
                            // 选择按钮
                            VStack(spacing: 16) {
                                ForEach(options, id: \.self) { option in
                                    Button {
                                        selectedAnswer = option
                                        checkAnswer()
                                    } label: {
                                        Text(option)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        } else {
                            // 下一题按钮
                            Button("下一个") {
                                nextWord()
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            generateTestWords()
        }
    }
    
    private func generateTestWords() {
        // 生成测试单词列表
        testWords = [
            TestWord(word: "exchange", meaning: "n. 交换；交流；vt. 交换", phonetic: "ɪksˈtʃeɪndʒ"),
            TestWord(word: "lecture", meaning: "n. 讲座；演讲；vt. 演讲", phonetic: "ˈlektʃə(r)"),
            TestWord(word: "registration", meaning: "n. 登记；注册；挂号", phonetic: "ˌredʒɪˈstreɪʃn"),
            TestWord(word: "curriculum", meaning: "n. 课程", phonetic: "kəˈrɪkjələm"),
            TestWord(word: "exploration", meaning: "n. 探索；探测；探究", phonetic: "ˌeksplɔːˈreɪʃn")
        ]
        
        if let firstWord = testWords.first {
            generateOptions(for: firstWord)
        }
    }
    
    private func generateOptions(for word: TestWord) {
        // 重置状态
        showResult = false
        showCurveAnimation = false
        selectedAnswer = ""
        
        // 生成选项（包含正确答案和"不认识"选项）
        options = [
            word.meaning,
            "不认识这个单词"
        ]
        options.shuffle()
    }
    
    private func checkAnswer() {
        isCorrect = selectedAnswer == currentWord?.meaning
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showResult = true
        }
        
        // 延迟显示遗忘曲线动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCurveAnimation = true
            }
        }
        
        // 记录测试结果
        if let word = currentWord {
            let result = TestWordResult(word: word.word, selectedAnswer: selectedAnswer, isCorrect: isCorrect)
            completedTests.append(result)
            
            // 如果答错了，加入错题本
            if !isCorrect {
                addToWrongWords(word)
            }
        }
    }
    
    private func addToWrongWords(_ word: TestWord) {
        let wrongWord = WrongWord(
            word: word.word,
            meaning: word.meaning,
            context: "",
            learningDirection: .recognizeMeaning,
            textbookSource: TextbookSource(courseType: .required, courseBook: "必修1", unit: .unit1, textbookVersion: .renjiao),
            partOfSpeech: .noun,
            examSource: .gaokao,
            difficulty: .medium
        )
        wrongWordManager.addWrongWord(wrongWord)
    }
    
    private func nextWord() {
        currentWordIndex += 1
        
        if let nextWord = currentWord {
            generateOptions(for: nextWord)
        }
    }
}

// MARK: - 检测结果视图
private struct DetectionResultsView: View {
    let detectedWords: [DetectedWord]
    let onStartLearning: () -> Void
    
    @State private var showingWordDetails: DetectedWord? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // 结果标题
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                
                Text("检测完成！")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("为您找到了 \(detectedWords.count) 个新单词")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            
            // 检测统计
            HStack(spacing: 20) {
                DetectionStatCard(title: "新词总数", value: "\(detectedWords.count)", color: .blue)
                DetectionStatCard(title: "高优先级", value: "\(detectedWords.filter { $0.priority == .high }.count)", color: .red)
                DetectionStatCard(title: "预计时间", value: "15分钟", color: .green)
            }
            .padding(.horizontal, 20)
            
            // 新词列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(detectedWords, id: \.word) { word in
                        DetectedWordCard(
                            word: word,
                            onTap: { showingWordDetails = word }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // 开始学习按钮
            Button {
                onStartLearning()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    
                    Text("开始学习这些新词")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .sheet(item: $showingWordDetails) { word in
            DetectedWordDetailView(word: word)
        }
    }
}

// MARK: - 检测到的单词卡片
private struct DetectedWordCard: View {
    let word: DetectedWord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 优先级指示器
                Circle()
                    .fill(priorityColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(word.word)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text(word.phonetic)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Text("点击测试这个单词")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .italic()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(word.source)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    DifficultyBadge(difficulty: word.difficulty)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityColor: Color {
        switch word.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - 检测到的单词详情视图
private struct DetectedWordDetailView: View {
    let word: DetectedWord
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnswer: String = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var options: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 单词信息
                VStack(spacing: 16) {
                    Text(word.word)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(word.phonetic)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if !showResult {
                        Text("这个单词的中文意思是？")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 8) {
                            Text(isCorrect ? "✅ 答对了！" : "❌ 答错了")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(isCorrect ? .green : .red)
                            
                            Text("正确答案：\(word.meaning)")
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if !showResult {
                    // 选择题选项
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                selectedAnswer = option
                                checkAnswer()
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedAnswer == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(selectedAnswer == option ? .blue.opacity(0.1) : .gray.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedAnswer == option ? .blue : .clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    // 显示详细信息
                    VStack(spacing: 16) {
                        DetailRow(title: "教材", value: word.textbook)
                        DetailRow(title: "课本", value: word.coursebook)
                        DetailRow(title: "单元", value: "Unit \(word.unit)")
                        DetailRow(title: "难度", value: word.difficulty.displayName)
                        DetailRow(title: "优先级", value: word.priority.displayName)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("新词测试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateOptions()
            }
        }
    }
    
    private func generateOptions() {
        // 生成4个选项，包括正确答案
        let wrongOptions = [
            "学习", "工作", "生活", "朋友", "家庭", "时间", "空间", "知识",
            "快乐", "悲伤", "愤怒", "平静", "紧张", "放松", "专注", "分散",
            "开始", "结束", "继续", "停止", "前进", "后退", "上升", "下降"
        ].shuffled().prefix(3)
        
        options = ([word.meaning] + wrongOptions).shuffled()
    }
    
    private func checkAnswer() {
        isCorrect = selectedAnswer == word.meaning
        withAnimation(.easeInOut(duration: 0.3)) {
            showResult = true
        }
    }
}

// MARK: - 检测到的单词数据模型
struct DetectedWord: Identifiable {
    let id = UUID()
    let word: String
    let meaning: String
    let phonetic: String
    let textbook: String
    let coursebook: String
    let unit: String
    let difficulty: WordDifficulty
    let priority: WordPriority
    
    var source: String {
        return "\(textbook) \(coursebook) Unit \(unit)"
    }
}

// MARK: - 单词优先级枚举
enum WordPriority: String, CaseIterable {
    case high = "高"
    case medium = "中"
    case low = "低"
    
    var displayName: String {
        return rawValue + "优先级"
    }
}

// MARK: - 检测难度徽章
private struct DetectionDifficultyBadge: View {
    let difficulty: WordDifficulty
    
    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficultyColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - 检测统计卡片
private struct DetectionStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 新词学习视图
private struct NewWordLearningView: View {
    @ObservedObject var newWordManager: NewWordManager
    let onLearningComplete: () -> Void
    
    @State private var currentWordIndex = 0
    @State private var showingWordDetail = false
    
    private var currentWord: NewWord? {
        guard currentWordIndex < newWordManager.newWords.count else { return nil }
        return newWordManager.newWords[currentWordIndex]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 学习进度
            VStack(spacing: 8) {
                HStack {
                    Text("学习进度")
                        .font(.headline)
                    Spacer()
                    Text("\(currentWordIndex + 1) / \(newWordManager.newWords.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: Double(currentWordIndex), total: Double(newWordManager.newWords.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            if let word = currentWord {
                // 单词学习卡片
                NewWordCard(
                    word: word,
                    onNext: {
                        if currentWordIndex < newWordManager.newWords.count - 1 {
                            currentWordIndex += 1
                        } else {
                            onLearningComplete()
                        }
                    }
                )
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // 底部导航
            HStack(spacing: 16) {
                Button {
                    if currentWordIndex > 0 {
                        currentWordIndex -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("上一个")
                    }
                    .foregroundStyle(currentWordIndex > 0 ? .blue : .gray)
                }
                .disabled(currentWordIndex == 0)
                
                Spacer()
                
                Button {
                    if currentWordIndex < newWordManager.newWords.count - 1 {
                        currentWordIndex += 1
                    } else {
                        onLearningComplete()
                    }
                } label: {
                    HStack {
                        Text(currentWordIndex < newWordManager.newWords.count - 1 ? "下一个" : "完成学习")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - 新词卡片
private struct NewWordCard: View {
    let word: NewWord
    let onNext: () -> Void
    
    @State private var showingDetail = false
    @State private var showingWordLearning = false
    @State private var selectedAnswer: String = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var options: [String] = []
    @State private var showCurveAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // 单词展示
            VStack(spacing: 16) {
                Text(word.word)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if !word.phonetic.isEmpty {
                    Text("[\(word.phonetic)]")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                if !showResult {
                    Text("这个单词的中文意思是？")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 12) {
                        Text(isCorrect ? "✅ 答对了！" : "❌ 答错了")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(isCorrect ? .green : .red)
                        
                        // 遗忘曲线动画
                        if showCurveAnimation {
                            ForgettingCurveAnimation(isCorrect: isCorrect, word: word.word)
                                .transition(.opacity.combined(with: .scale))
                        }
                        
                        Text("正确答案：\(word.meaning)")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            
            if !showResult {
                // 选择题选项
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selectedAnswer = option
                            checkAnswer()
                        } label: {
                            Text(option)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
            } else {
                // 学习按钮（显示结果后）
                VStack(spacing: 12) {
                    Button {
                        showingWordLearning = true
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                            Text("深入学习")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        onNext()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("下一个单词")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        showingDetail = true
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("查看详情")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .sheet(isPresented: $showingWordLearning) {
            WordLearningPopup(word: convertToWrongWord(word))
        }
        .sheet(isPresented: $showingDetail) {
            NewWordDetailView(word: word)
        }
        .onAppear {
            generateOptions()
        }
    }
    
    private func generateOptions() {
        // 重置状态
        showResult = false
        showCurveAnimation = false
        selectedAnswer = ""
        
        // 生成4个选项，包括正确答案
        let wrongOptions = [
            "n. 机会；机遇；时机",
            "vt. 组织；安排；筹备",
            "adj. 自信的；有信心的",
            "n. 策略；战略；计谋",
            "vt. 改善；改进；提高",
            "adj. 独特的；唯一的",
            "n. 挑战；考验；难题",
            "vt. 创造；创建；产生"
        ]
        
        var allOptions = [word.meaning]
        let availableWrong = wrongOptions.filter { $0 != word.meaning }
        allOptions.append(contentsOf: Array(availableWrong.shuffled().prefix(3)))
        options = allOptions.shuffled()
    }
    
    private func checkAnswer() {
        isCorrect = selectedAnswer == word.meaning
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showResult = true
        }
        
        // 延迟显示遗忘曲线动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCurveAnimation = true
            }
        }
        
        // 触发震动反馈
        triggerForgettingCurveAnimation()
    }
    
    private func triggerForgettingCurveAnimation() {
        // 这里将触发遗忘曲线上的动画点
        // 答对时：点会上升并变绿
        // 答错时：点会下降并变红
        let feedback = HapticFeedback()
        if isCorrect {
            feedback.success()
        } else {
            feedback.error()
        }
    }
    
    private func convertToWrongWord(_ newWord: NewWord) -> WrongWord {
        return WrongWord(
            word: newWord.word,
            meaning: newWord.meaning,
            context: newWord.context,
            learningDirection: .recognizeMeaning,
            textbookSource: newWord.textbookSource,
            partOfSpeech: newWord.partOfSpeech,
            examSource: newWord.examSource,
            difficulty: newWord.difficulty
        )
    }
}

// MARK: - 新词详情视图
private struct NewWordDetailView: View {
    let word: NewWord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 基本信息
                    VStack(spacing: 16) {
                        Text(word.word)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if !word.phonetic.isEmpty {
                            Text("[\(word.phonetic)]")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(word.meaning)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // 详细信息
                    VStack(spacing: 16) {
                        DetailRow(title: "词性", value: word.partOfSpeech.displayName)
                        DetailRow(title: "难度", value: word.difficulty.displayName)
                        DetailRow(title: "教材单元", value: word.textbookSource.displayText)
                        DetailRow(title: "考试来源", value: word.examSource.displayName)
                        
                        if !word.context.isEmpty {
                            DetailRow(title: "例句", value: word.context)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding()
            }
            .navigationTitle("单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 详情行
private struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - 新词测试视图
private struct NewWordTestingView: View {
    @ObservedObject var newWordManager: NewWordManager
    let onTestingComplete: () -> Void
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String = ""
    @State private var showingResult = false
    @State private var isAnswerCorrect = false
    @State private var testResults: [TestResult] = []
    
    private var currentQuestion: TestQuestion? {
        guard currentQuestionIndex < newWordManager.testQuestions.count else { return nil }
        return newWordManager.testQuestions[currentQuestionIndex]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 测试进度
            VStack(spacing: 8) {
                HStack {
                    Text("测试进度")
                        .font(.headline)
                    Spacer()
                    Text("\(currentQuestionIndex + 1) / \(newWordManager.testQuestions.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: Double(currentQuestionIndex), total: Double(newWordManager.testQuestions.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            if let question = currentQuestion {
                // 测试问题卡片
                TestQuestionCard(
                    question: question,
                    selectedAnswer: $selectedAnswer,
                    showingResult: $showingResult,
                    isAnswerCorrect: $isAnswerCorrect,
                    onAnswerSelected: checkAnswer
                )
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // 底部按钮
            if showingResult {
                Button {
                    nextQuestion()
                } label: {
                    Text(currentQuestionIndex < newWordManager.testQuestions.count - 1 ? "下一题" : "查看结果")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func checkAnswer() {
        guard let question = currentQuestion else { return }
        
        isAnswerCorrect = selectedAnswer == question.correctAnswer
        showingResult = true
        
        // 记录结果
        let result = TestResult(
            word: question.word,
            selectedAnswer: selectedAnswer,
            isCorrect: isAnswerCorrect
        )
        testResults.append(result)
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < newWordManager.testQuestions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = ""
            showingResult = false
        } else {
            onTestingComplete()
        }
    }
}

// MARK: - 测试问题卡片
private struct TestQuestionCard: View {
    let question: TestQuestion
    @Binding var selectedAnswer: String
    @Binding var showingResult: Bool
    @Binding var isAnswerCorrect: Bool
    let onAnswerSelected: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 问题
            VStack(spacing: 16) {
                Text("请选择正确的中文意思：")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(question.word)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if !question.phonetic.isEmpty {
                    Text("[\(question.phonetic)]")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            // 选项
            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    TestOptionButton(
                        text: option,
                        isSelected: selectedAnswer == option,
                        isCorrect: showingResult ? option == question.correctAnswer : nil,
                        isIncorrect: showingResult ? (selectedAnswer == option && option != question.correctAnswer) : nil
                    ) {
                        if !showingResult {
                            selectedAnswer = option
                            onAnswerSelected()
                        }
                    }
                }
            }
            
            // 结果反馈
            if showingResult {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(isAnswerCorrect ? .green : .red)
                        
                        Text(isAnswerCorrect ? "回答正确！" : "回答错误")
                            .font(.headline)
                            .foregroundStyle(isAnswerCorrect ? .green : .red)
                    }
                    
                    if !isAnswerCorrect {
                        Text("正确答案：\(question.correctAnswer)")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isAnswerCorrect ? .green.opacity(0.1) : .red.opacity(0.1))
                )
            }
        }
    }
}

// MARK: - 测试选项按钮
private struct TestOptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let isIncorrect: Bool?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let isCorrect = isCorrect, isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if let isIncorrect = isIncorrect, isIncorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isCorrect != nil || isIncorrect != nil)
    }
    
    private var backgroundColor: Color {
        if isCorrect == true { return .green.opacity(0.1) }
        if isIncorrect == true { return .red.opacity(0.1) }
        if isSelected { return .blue.opacity(0.1) }
        return .clear
    }
    
    private var borderColor: Color {
        if isCorrect == true { return .green }
        if isIncorrect == true { return .red }
        if isSelected { return .blue }
        return .gray.opacity(0.3)
    }
    
    private var borderWidth: CGFloat {
        if isCorrect == true || isIncorrect == true || isSelected { return 2 }
        return 1
    }
    
    private var textColor: Color {
        if isCorrect == true { return .green }
        if isIncorrect == true { return .red }
        return .primary
    }
}



// MARK: - 学习统计项
private struct LearningStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 新词管理器
class NewWordManager: ObservableObject {
    @Published var newWords: [NewWord] = []
    @Published var testQuestions: [TestQuestion] = []
    @Published var correctAnswers: Int = 0
    
    var accuracy: Double {
        guard !testQuestions.isEmpty else { return 0.0 }
        return Double(correctAnswers) / Double(testQuestions.count)
    }
    
    init() {
        generateMockData()
    }
    
    private func generateMockData() {
        // 生成模拟新词数据
        newWords = [
            NewWord(word: "serendipity", meaning: "意外发现美好事物的能力", phonetic: "ˌserənˈdɪpəti", context: "Finding this book was pure serendipity.", textbookSource: TextbookSource(courseType: .required, courseBook: "必修1", unit: .unit3, textbookVersion: .renjiao), partOfSpeech: .noun, examSource: .cet4, difficulty: .medium),
            NewWord(word: "ephemeral", meaning: "短暂的，瞬息的", phonetic: "ɪˈfemərəl", context: "The beauty of cherry blossoms is ephemeral.", textbookSource: TextbookSource(courseType: .required, courseBook: "必修1", unit: .unit3, textbookVersion: .renjiao), partOfSpeech: .adjective, examSource: .cet4, difficulty: .medium),
            NewWord(word: "ubiquitous", meaning: "无处不在的", phonetic: "juːˈbɪkwɪtəs", context: "Smartphones have become ubiquitous in modern life.", textbookSource: TextbookSource(courseType: .required, courseBook: "必修1", unit: .unit4, textbookVersion: .renjiao), partOfSpeech: .adjective, examSource: .cet6, difficulty: .hard),
            NewWord(word: "eloquent", meaning: "雄辩的，有说服力的", phonetic: "ˈeləkwənt", context: "She gave an eloquent speech about climate change.", textbookSource: TextbookSource(courseType: .required, courseBook: "必修1", unit: .unit4, textbookVersion: .renjiao), partOfSpeech: .adjective, examSource: .cet6, difficulty: .medium),
            NewWord(word: "resilient", meaning: "有韧性的，适应力强的", phonetic: "rɪˈzɪliənt", context: "Children are remarkably resilient to adversity.", textbookSource: TextbookSource(courseType: .required, courseBook: "必修1", unit: .unit5, textbookVersion: .renjiao), partOfSpeech: .adjective, examSource: .cet4, difficulty: .medium)
        ]
        
        // 生成测试问题
        testQuestions = newWords.map { word in
            let options = generateOptions(for: word)
            return TestQuestion(
                word: word.word,
                phonetic: word.phonetic,
                options: options,
                correctAnswer: word.meaning
            )
        }
    }
    
    private func generateOptions(for word: NewWord) -> [String] {
        var options = [word.meaning]
        
        // 从其他单词中随机选择干扰选项
        let otherWords = newWords.filter { $0.word != word.word }
        let randomOptions = otherWords.shuffled().prefix(3).map { $0.meaning }
        options.append(contentsOf: randomOptions)
        
        return options.shuffled()
    }
}

// MARK: - 新词数据模型
struct NewWord {
    let word: String
    let meaning: String
    let phonetic: String
    let context: String
    let textbookSource: TextbookSource
    let partOfSpeech: PartOfSpeech
    let examSource: ExamSource
    let difficulty: WordDifficulty
}

// MARK: - 测试问题数据模型
struct TestQuestion {
    let word: String
    let phonetic: String
    let options: [String]
    let correctAnswer: String
}

// MARK: - 测试结果数据模型
struct TestResult {
    let word: String
    let selectedAnswer: String
    let isCorrect: Bool
}

// MARK: - 今日任务统计项组件
struct TodayTaskStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 今日统计区域
private struct TodayStatsSection: View {
    @StateObject private var wrongWordManager = WrongWordManager()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📈 今日表现")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("表现良好 👏")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            HStack(spacing: 20) {
                TodayStatItem(title: "复习次数", value: "12", trend: "+3")
                TodayStatItem(title: "正确率", value: "85%", trend: "+5%")
                TodayStatItem(title: "学习时长", value: "25min", trend: "+8min")
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 今日统计项目
private struct TodayStatItem: View {
    let title: String
    let value: String
    let trend: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(trend)
                .font(.caption)
                .foregroundStyle(.green)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 记忆曲线区域
private struct MemoryCurveSection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🧠 记忆曲线")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("基于科学记忆规律")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("查看详情") {
                    // 查看详情
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.2))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // 简化的遗忘曲线
            SimpleForgettingCurve()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 简化的遗忘曲线
private struct SimpleForgettingCurve: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // 背景网格
                ForgettingCurvePath()
                    .stroke(.gray.opacity(0.2), lineWidth: 2)
                    .frame(height: 100)
                
                // 记忆点
                HStack {
                    Spacer()
                    
                    ForEach(0..<5) { index in
                        MemoryPoint(
                            day: index + 1,
                            strength: [0.9, 0.7, 0.5, 0.8, 0.6][index],
                            isHighlighted: index == 2
                        )
                        
                        if index < 4 {
                            Spacer()
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // 时间轴标签
            HStack {
                Text("今天")
                Spacer()
                Text("明天")
                Spacer()
                Text("3天后")
                Spacer()
                Text("7天后")
                Spacer()
                Text("15天后")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - 记忆点
private struct MemoryPoint: View {
    let day: Int
    let strength: Double
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(pointColor)
                .frame(width: isHighlighted ? 12 : 8, height: isHighlighted ? 12 : 8)
                .shadow(color: pointColor.opacity(0.5), radius: isHighlighted ? 6 : 3)
                .scaleEffect(isHighlighted ? 1.2 : 1.0)
            
            if isHighlighted {
                Text("\(Int(strength * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(pointColor)
            }
        }
    }
    
    private var pointColor: Color {
        if strength > 0.7 { return .green }
        if strength > 0.4 { return .orange }
        return .red
    }
}

// MARK: - 测试单词模型
private struct TestWord {
    let word: String
    let meaning: String
    let phonetic: String
}

// MARK: - 测试结果模型
private struct TestWordResult {
    let word: String
    let selectedAnswer: String
    let isCorrect: Bool
}

// MARK: - 简化的新词检测视图
private struct SimpleNewWordDetectionView: View {
    @StateObject private var wrongWordManager = WrongWordManager()
    @StateObject private var phoneticService = PhoneticService()
    @StateObject private var preferencesManager = UserPreferencesManager(appwriteService: AppwriteService())
    @Environment(\.dismiss) private var dismiss
    
    // 待测试的单词列表
    @State private var testWords: [TestWord] = []
    @State private var currentWordIndex = 0
    @State private var selectedAnswer: String = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var options: [String] = []
    @State private var completedTests: [TestWordResult] = []
    @State private var showCurveAnimation = false
    @State private var showingFirstQuestion = false // 先问会不会
    @State private var showFeedback = false
    
    private var currentWord: TestWord? {
        guard currentWordIndex < testWords.count else { return nil }
        return testWords[currentWordIndex]
    }
    
    private var isTestComplete: Bool {
        currentWordIndex >= testWords.count
    }
    
    private var correctCount: Int {
        completedTests.filter { $0.isCorrect }.count
    }
    
    private var accuracy: Double {
        guard !completedTests.isEmpty else { return 0.0 }
        return Double(correctCount) / Double(completedTests.count)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isTestComplete {
                    // 使用统一的完成视图
                    UnifiedCompletionView(
                        title: "检测完成！",
                        subtitle: "已完成新词检测，发现了你的学习薄弱点",
                        totalWords: testWords.count,
                        correctCount: correctCount,
                        accuracy: accuracy,
                        onRestart: restartDetection,
                        onBack: { dismiss() }
                    )
                } else if let word = currentWord {
                    // 测试界面
                    VStack(spacing: 24) {
                        // 使用统一的进度头部
                        LearningProgressHeader(
                            title: "新词检测",
                            subtitle: "发现学习薄弱点",
                            currentIndex: currentWordIndex,
                            totalCount: testWords.count,
                            progressColor: .green
                        )
                        
                        Spacer()
                        
                        // 使用统一的学习卡片
                        UnifiedLearningCard(
                            content: word.word,
                            phonetic: word.phonetic,
                            pronunciationType: preferencesManager.userPreferences.pronunciationType,
                            cardColor: .green,
                            isHighlighted: showingFirstQuestion || showResult,
                            onPlayAudio: {
                                // 播放单词发音
                                let phoneticService = PhoneticService()
                                phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                            }
                        )
                        .padding(.horizontal, 20)
                            
                        if showFeedback {
                            // 使用统一的学习反馈系统
                            UnifiedLearningFeedback(
                                isCorrect: isCorrect,
                                memoryStrength: calculateNewWordMemoryStrength(),
                                streakCount: calculateNewWordStreakCount(),
                                onComplete: {
                                    showFeedback = false
                                    nextWord()
                                }
                            )
                                            .padding(.horizontal, 20)
                        } else if !showingFirstQuestion {
                            // 使用统一的答案按钮
                            VStack(spacing: 20) {
                                Text("你认识这个单词吗？")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                UnifiedAnswerButtons(
                                    primaryText: "认识",
                                    secondaryText: "不认识",
                                    primaryColor: .green,
                                    secondaryColor: .red,
                                    primaryAction: {
                                        showingFirstQuestion = true
                                        generateOptions(for: word)
                                    },
                                    secondaryAction: {
                                        selectedAnswer = "不认识这个单词"
                                        checkAnswer()
                                    }
                                )
                            }
                            .padding(.horizontal, 20)
                        } else if !showResult {
                            // 使用统一的选项按钮
                            VStack(spacing: 20) {
                                Text("选择正确的中文意思")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                VStack(spacing: 12) {
                                    ForEach(options, id: \.self) { option in
                                        UnifiedOptionButton(
                                            option: option,
                                            isSelected: selectedAnswer == option,
                                            isCorrect: showResult ? (option == word.meaning) : nil,
                                            showResult: showResult,
                                            action: {
                                                selectedAnswer = option
                                                checkAnswer()
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("新词检测")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            generateTestWords()
        }
    }
    
    private func generateTestWords() {
        // 生成测试单词列表
        testWords = [
            TestWord(word: "exchange", meaning: "n. 交换；交流；vt. 交换", phonetic: "ɪksˈtʃeɪndʒ"),
            TestWord(word: "lecture", meaning: "n. 讲座；演讲；vt. 演讲", phonetic: "ˈlektʃə(r)"),
            TestWord(word: "registration", meaning: "n. 登记；注册；挂号", phonetic: "ˌredʒɪˈstreɪʃn"),
            TestWord(word: "curriculum", meaning: "n. 课程", phonetic: "kəˈrɪkjələm"),
            TestWord(word: "exploration", meaning: "n. 探索；探测；探究", phonetic: "ˌeksplɔːˈreɪʃn")
        ]
    }
    
    private func generateOptions(for word: TestWord) {
        // 生成混淆选项
        let wrongOptions = [
            "n. 练习；锻炼",
            "v. 讨论；谈论",
            "adj. 重要的；主要的",
            "n. 方法；途径"
        ]
        
        options = [word.meaning] + wrongOptions.prefix(3)
        options.shuffle()
    }
    
    private func checkAnswer() {
        isCorrect = selectedAnswer == currentWord?.meaning
        
        // 音频反馈
        if let word = currentWord {
            if isCorrect {
                // 答对了：播放成功音效
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
            } else {
                // 答错了或不认识：自动朗读单词
                phoneticService.playPronunciation(for: word.word) {}
                
                // 播放错误音效
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
        
        // 记录测试结果
        if let word = currentWord {
            let result = TestWordResult(word: word.word, selectedAnswer: selectedAnswer, isCorrect: isCorrect)
            completedTests.append(result)
            
            // 如果答错了，加入错题本
            if !isCorrect {
                addToWrongWords(word)
            }
        }
        
        // 显示反馈界面
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showFeedback = true
        }
    }
    
    private func addToWrongWords(_ word: TestWord) {
        let wrongWord = WrongWord(
            word: word.word,
            meaning: word.meaning,
            context: "",
            learningDirection: .recognizeMeaning,
            textbookSource: TextbookSource(courseType: .required, courseBook: "必修1", unit: .unit1, textbookVersion: .renjiao),
            partOfSpeech: .noun,
            examSource: .gaokao,
            difficulty: .medium
        )
        wrongWordManager.addWrongWord(wrongWord)
    }
    
    private func nextWord() {
        currentWordIndex += 1
        showingFirstQuestion = false
        showResult = false
        showCurveAnimation = false
        showFeedback = false
        selectedAnswer = ""
        options = []
    }
    
    private func restartDetection() {
        currentWordIndex = 0
        showingFirstQuestion = false
        showResult = false
        showCurveAnimation = false
        showFeedback = false
        selectedAnswer = ""
        options = []
        completedTests.removeAll()
        generateTestWords()
    }
    
    // 计算新词检测的记忆强度
    private func calculateNewWordMemoryStrength() -> Double {
        // 基于答题正确率计算记忆强度
        if completedTests.isEmpty {
            return 0.5 // 默认中等强度
        }
        
        let recentTests = completedTests.suffix(3) // 最近3题
        let recentCorrectCount = recentTests.filter { $0.isCorrect }.count
        let recentAccuracy = Double(recentCorrectCount) / Double(recentTests.count)
        
        return max(0.1, min(1.0, recentAccuracy))
    }
    
    // 计算新词检测的连击数
    private func calculateNewWordStreakCount() -> Int {
        var streak = 0
        // 从最近的结果开始往前数连续正确的个数
        for result in completedTests.reversed() {
            if result.isCorrect {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    

}

// MARK: - 紧急复习按钮
private struct UrgentReviewButton: View {
    let count: Int
    let action: () -> Void
    @State private var breathingScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // 呼吸光效背景
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red.opacity(glowOpacity))
                        .blur(radius: 4)
                        .scaleEffect(breathingScale)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                            
                            Spacer()
                            
                            // 数量badge
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 20, minHeight: 20)
                                    .background(.red)
                                    .clipShape(Circle())
                                    .scaleEffect(breathingScale)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("紧急复习")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("\(count)个待复习")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            startBreathingAnimation()
        }
    }
    
    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            breathingScale = 1.05
            glowOpacity = 0.6
        }
    }
}

// MARK: - 新词检测按钮
private struct NewWordDetectionButton: View {
    let todayCount: Int
    let action: () -> Void
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                            
                            Spacer()
                            
                            // 今日任务badge
                            Text("今日")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("新词检测")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("今日 \(todayCount)个")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    )
                    
                    // 闪光效果
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .green.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 100)
                        .offset(x: shimmerOffset)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 200
        }
    }
}

// MARK: - 1. 记忆健康度区域
private struct MemoryHealthSection: View {
    @ObservedObject var wrongWordManager: WrongWordManager
    
    private var memoryHealthPercentage: Int {
        let totalWords = wrongWordManager.wrongWords.count
        guard totalWords > 0 else { return 72 } // 默认显示72%
        let masteredWords = wrongWordManager.wrongWords.filter { $0.isMastered }.count
        return Int((Double(masteredWords) / Double(totalWords)) * 100)
    }
    
    private var urgentWordsCount: Int {
        wrongWordManager.urgentWordsCount
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 1. 简洁的圆环/百分比
            HStack(spacing: 16) {
                // 圆环图 - 更大更醒目
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(memoryHealthPercentage) / 100)
                        .stroke(
                            LinearGradient(
                                colors: memoryHealthPercentage >= 70 ? 
                                    [Color.green, Color.blue] : 
                                    [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: memoryHealthPercentage)
                    
                    VStack(spacing: 2) {
                        Text("\(memoryHealthPercentage)%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("健康度")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 健康度描述
                VStack(alignment: .leading, spacing: 8) {
                    Text("整体记忆健康度")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(healthStatusDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // 科学感提示
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        Text("基于遗忘曲线科学计算")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
            }
            
            // 2. 简化的健康度趋势线
            SimpleTrendCurve(
                healthPercentage: Double(memoryHealthPercentage),
                animationProgress: 1.0
            )
            .frame(height: 100)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    
    private var healthStatusDescription: String {
        switch memoryHealthPercentage {
        case 80...100:
            return "记忆状态优秀，保持节奏 💪"
        case 60...79:
            return "坚持复习，健康度每天都会提升 📈"
        case 40...59:
            return "开始复习，快速提升记忆健康度 🚀"
        default:
            return "急需重点复习，现在就开始！⚡"
        }
    }
}

// MARK: - 简化趋势线（首页专用）
private struct SimpleTrendCurve: View {
    let healthPercentage: Double
    let animationProgress: Double
    
    var body: some View {
        ZStack {
            // 背景网格（简化）
            TrendBackground()
            
            // 健康度趋势线
            Path { path in
                let width: CGFloat = 280
                let height: CGFloat = 80
                
                // 起始点（过去）
                path.move(to: CGPoint(x: 20, y: height - 20))
                
                // 模拟的健康度趋势（简单的上升趋势）
                let controlPoint1 = CGPoint(x: width * 0.3, y: height - (healthPercentage / 100 * height * 0.4))
                let controlPoint2 = CGPoint(x: width * 0.7, y: height - (healthPercentage / 100 * height * 0.6))
                let endPoint = CGPoint(x: width - 20, y: height - (healthPercentage / 100 * height * 0.8))
                
                path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
            }
            .trim(from: 0, to: animationProgress)
            .stroke(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            
            // 当前状态点（仅显示最终点）
            if animationProgress > 0.8 {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                    .position(x: 280 - 20, y: 80 - (healthPercentage / 100 * 80 * 0.8))
            }
        }
    }
}

// MARK: - 趋势线背景（首页专用）
private struct TrendBackground: View {
    var body: some View {
        ZStack {
            // 简化的背景网格
            Path { path in
                let width: CGFloat = 300
                let height: CGFloat = 100
                
                // 水平辅助线（少量）
                for i in 1...2 {
                    let y = height * CGFloat(i) / 3
                    path.move(to: CGPoint(x: 10, y: y))
                    path.addLine(to: CGPoint(x: width - 10, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            
            // 时间轴标签（简化）
            HStack {
                Text("过去")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("现在")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .offset(y: 40)
        }
    }
}

// MARK: - 2. 使用外部艾宾浩斯曲线组件

// MARK: - 旧的艾宾浩斯曲线可视化（待删除）
private struct ForgettingCurveVisualization: View {
    let urgentWordsCount: Int
    @State private var animatePoints = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("记忆衰减曲线")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            GeometryReader { geometry in
                ZStack {
                    // 背景网格
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        // 水平线
                        for i in 0...3 {
                            let y = height * CGFloat(i) / 3
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        
                        // 垂直线
                        for i in 0...4 {
                            let x = width * CGFloat(i) / 4
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    
                    // 遗忘曲线
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        let points = [
                            CGPoint(x: 0, y: height * 0.1),
                            CGPoint(x: width * 0.2, y: height * 0.4),
                            CGPoint(x: width * 0.4, y: height * 0.6),
                            CGPoint(x: width * 0.6, y: height * 0.7),
                            CGPoint(x: width * 0.8, y: height * 0.8),
                            CGPoint(x: width, y: height * 0.85)
                        ]
                        
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            path.addLine(to: points[i])
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 3
                    )
                    
                    // 危险区域标记
                    if urgentWordsCount > 0 {
                        ForEach(0..<min(urgentWordsCount, 5), id: \.self) { index in
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .position(
                                    x: geometry.size.width * (0.6 + CGFloat(index) * 0.1),
                                    y: geometry.size.height * (0.7 + CGFloat(index) * 0.03)
                                )
                                .scaleEffect(animatePoints ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: animatePoints
                                )
                        }
                    }
                }
            }
            .frame(height: 60)
            .onAppear {
                animatePoints = true
            }
            
            // 时间轴标签
            HStack {
                Text("刚学")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("3天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("7天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1月")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - 2. 今日任务卡片区域
private struct TodayTaskCards: View {
    @Binding var showingSmartLearning: Bool
    @Binding var showingListLearning: Bool
    @Binding var showingUrgentReview: Bool
    @Binding var showingStudyAmountSelection: Bool
    @Binding var showingDictationMode: Bool // 新增：听写模式状态
    @Binding var showingParentDictationMode: Bool // 新增：家长听写模式状态
    @ObservedObject var wrongWordManager: WrongWordManager
    @ObservedObject var preferencesManager: UserPreferencesManager
    
    @State private var smartLearningPressed = false
    @State private var urgentPulse = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 学习模式选择
            LearningModeSelectionCard(
                dailyStudyAmount: preferencesManager.userPreferences.dailyStudyAmount,
                onCardModeSelected: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        smartLearningPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingSmartLearning = true
                        smartLearningPressed = false
                    }
                },
                onListModeSelected: {
                    // 直接进入列表学习模式
                    showingListLearning = true
                },
                onDictationModeSelected: {
                    // 进入听写模式
                    showingDictationMode = true
                },
                onParentDictationModeSelected: {
                    // 进入家长听写模式
                    showingParentDictationMode = true
                },
                onEditStudyAmount: {
                    showingStudyAmountSelection = true
                }
            )
            
            
            
            // 紧急复习（仅在有紧急任务时显示）
            if wrongWordManager.todayReviewWords.count > 0 {
                UrgentReviewCard(
                    count: wrongWordManager.todayReviewWords.count,
                    isPulsing: urgentPulse,
                    action: {
                        showingUrgentReview = true
                    }
                )
            }
            

        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                urgentPulse = true
            }
        }
    }
}

// MARK: - 全新智能学习大卡片
private struct NewSmartLearningCard: View {
    let isPressed: Bool
    let dailyStudyAmount: DailyStudyAmount
    let action: () -> Void
    let onEditStudyAmount: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        // 推荐标签
                        HStack(spacing: 6) {
                            Text("推荐")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.yellow.opacity(0.9))
                                )
                            
                            Spacer()
                        }
                        
                        // 主标题
                        Text("开始智能学习")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        // 副标题
                        Text("AI推荐，今日任务 = 复习 + 新词")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // 智能图标
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                }
                
                // 学习量显示
                HStack {
                    Button(action: onEditStudyAmount) {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text("今日学习 \(dailyStudyAmount.displayName)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text("(点击调整)")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                        .rotationEffect(.degrees(isPressed ? 180 : 0))
                        .animation(.spring(response: 0.3), value: isPressed)
                }
            }
            .padding(24)
            .background(
                // 立体渐变效果
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.4, blue: 1.0),
                                Color(red: 0.6, green: 0.2, blue: 0.9),
                                Color(red: 0.8, green: 0.1, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // 光泽效果
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .clear,
                                        .black.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: Color.blue.opacity(0.3),
                radius: isPressed ? 8 : 15,
                x: 0,
                y: isPressed ? 4 : 8
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 全新紧急复习卡片
private struct NewUrgentReviewCard: View {
    let urgentCount: Int
    let isPulsing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 图标和Badge
                ZStack {
                    // 背景圆圈
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    // 警告图标
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                    
                    // 数量Badge
                    if urgentCount > 0 {
                        Text("\(urgentCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(.red))
                            .offset(x: 18, y: -18)
                    }
                }
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
                
                VStack(spacing: 4) {
                    Text("紧急复习")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(urgentCount > 0 ? "\(urgentCount)个待复习" : "暂无紧急")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 全新新词检测卡片
private struct NewWordDetectionCard: View {
    let todayWordCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 图标和Badge
                ZStack {
                    // 背景圆圈
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    // 检测图标
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    // 数量Badge
                    if todayWordCount > 0 {
                        Text("\(todayWordCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(.green))
                            .offset(x: 18, y: -18)
                    }
                }
                
                VStack(spacing: 4) {
                    Text("新词检测")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(todayWordCount > 0 ? "今日 \(todayWordCount)个" : "暂无新词")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 旧版智能学习大卡片（待删除）
private struct SmartLearningCard: View {
    let isPressed: Bool
    let dailyStudyAmount: DailyStudyAmount
    let action: () -> Void
    let onEditStudyAmount: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // 图标
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    
                    // 文案
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("开始智能学习")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            // 推荐标签
                            Text("推荐")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                        }
                        
                        Text("一键完成今日任务（复习+新词）")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // 箭头图标
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.8))
                        .rotationEffect(.degrees(isPressed ? 180 : 0))
                }
                
                // 学习量显示和修改入口
                Button(action: onEditStudyAmount) {
                    HStack {
                        Text("今日学习 \(dailyStudyAmount.displayName)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text("(点击修改)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.6, blue: 1.0),
                        Color(red: 0.4, green: 0.2, blue: 0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: Color.blue.opacity(isPressed ? 0.4 : 0.2),
                radius: isPressed ? 20 : 12,
                x: 0,
                y: isPressed ? 8 : 6
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 紧急复习小卡片
private struct UrgentReviewCard: View {
    let count: Int
    let isPulsing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                    
                    Spacer()
                    
                    // 数量badge
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(.red)
                        .clipShape(Circle())
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("紧急复习")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("\(count)个待复习")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.red.opacity(isPulsing ? 0.4 : 0.2), lineWidth: 1)
            )
            .shadow(color: .red.opacity(isPulsing ? 0.2 : 0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// MARK: - 3. 进度反馈区域
private struct ProgressFeedbackSection: View {
    @ObservedObject var wrongWordManager: WrongWordManager
    @ObservedObject var motivationSystem: MotivationSystem
    
    private var todayProgress: (completed: Int, total: Int) {
        // 模拟今日学习进度
        let completed = 3 // 默认显示已完成3个
        let total = 15   // 总共15个
        return (completed, total)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 今日学习进度条
            NewTodayProgressBar(
                completed: todayProgress.completed,
                total: todayProgress.total
            )
            
            // 连续学习天数
            NewContinuousLearningCard(
                consecutiveDays: motivationSystem.consecutiveDays
            )
        }
    }
}

// MARK: - 全新今日进度条
private struct NewTodayProgressBar: View {
    let completed: Int
    let total: Int
    
    private var progressPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("今日学习进度")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("今日完成 \(completed) / \(total)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            // 轻量化进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)
                    
                    // 进度
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(progressPercentage),
                            height: 8
                        )
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 全新连续学习卡片
private struct NewContinuousLearningCard: View {
    let consecutiveDays: Int
    @State private var flameScale: CGFloat = 1.0
    @State private var flameRotation: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // 火苗图标
            Text("🔥")
                .font(.title)
                .scaleEffect(flameScale)
                .rotationEffect(.degrees(flameRotation))
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: flameScale
                )
                .onAppear {
                    if consecutiveDays > 0 {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            flameScale = 1.2
                        }
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            flameRotation = 5
                        }
                    }
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("连续复习 \(consecutiveDays) 天")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(motivationText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 成就徽章
            if consecutiveDays >= 7 {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.3), radius: 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var motivationText: String {
        switch consecutiveDays {
        case 0:
            return "开始你的学习之旅"
        case 1...3:
            return "很好的开始！"
        case 4...6:
            return "习惯正在养成"
        case 7...13:
            return "坚持就是胜利"
        case 14...29:
            return "习惯已经养成"
        default:
            return "你是学习达人！"
        }
    }
}

// MARK: - 旧版今日进度条（待删除）
private struct TodayProgressBar: View {
    let completed: Int
    let total: Int
    
    private var progressPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日学习进度")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(completed) / \(total)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            // 增强的进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    
                    // 彩色渐变进度条
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: progressPercentage >= 1.0 ? 
                                    [.green, .yellow, .orange] : // 完成时的庆祝色彩
                                    [.purple, .blue, .cyan, .green], // 进行中的活力色彩
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(progressPercentage),
                            height: 12
                        )
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.3),
                            value: progressPercentage
                        )
                        .overlay(
                            // 光泽效果
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * CGFloat(progressPercentage),
                                    height: 12
                                )
                        )
                        .shadow(
                            color: progressPercentage >= 1.0 ? .green.opacity(0.5) : .blue.opacity(0.3),
                            radius: progressPercentage >= 1.0 ? 8 : 4,
                            x: 0,
                            y: 2
                        )
                }
            }
            .frame(height: 12)
        }
    }
}

// MARK: - 连续学习激励
private struct ContinuousLearningMotivation: View {
    let consecutiveDays: Int
    @State private var flameScale: CGFloat = 1.0
    @State private var flameRotation: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // 动态火苗图标
            Text("🔥")
                .font(.title2)
                .scaleEffect(flameScale)
                .rotationEffect(.degrees(flameRotation))
                .animation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                    value: flameScale
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        flameScale = consecutiveDays > 0 ? 1.2 : 1.0
                    }
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        flameRotation = consecutiveDays > 0 ? 5 : 0
                    }
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("连续复习 \(consecutiveDays) 天")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(motivationText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 成就徽章
            if consecutiveDays >= 7 {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
            }
        }
    }
    
    private var motivationText: String {
        if consecutiveDays >= 30 {
            return "学霸级坚持！"
        } else if consecutiveDays >= 14 {
            return "习惯已养成"
        } else if consecutiveDays >= 7 {
            return "坚持就是胜利"
        } else {
            return "加油，形成习惯"
        }
    }
}



// MARK: - 快速设置卡片
private struct QuickSettingsCard: View {
    @ObservedObject var preferencesManager: UserPreferencesManager
    @State private var showingTextbookSelection = false
    
    private var currentInfo: String {
        let courseType = preferencesManager.userPreferences.selectedCourseType
        let courseBook: String
        if courseType == .required {
            courseBook = preferencesManager.userPreferences.selectedRequiredCourse.rawValue
        } else {
            courseBook = preferencesManager.userPreferences.selectedElectiveCourse.rawValue
        }
        
        let selectedUnits = preferencesManager.userPreferences.selectedUnits
        let unitsText: String
        if selectedUnits.count == 1 {
            unitsText = selectedUnits.first?.displayName ?? "第1单元"
        } else if selectedUnits.count <= 3 {
            let unitNames = selectedUnits.sorted { $0.rawValue < $1.rawValue }.map { "U\($0.rawValue)" }
            unitsText = unitNames.joined(separator: ", ")
        } else {
            unitsText = "共\(selectedUnits.count)个单元"
        }
        
        return "\(courseBook) · \(unitsText)"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("当前学习")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text(currentInfo)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Button("切换") {
                showingTextbookSelection = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
        .sheet(isPresented: $showingTextbookSelection) {
            TextbookSelectionView(userPreferences: .constant(preferencesManager.userPreferences))
                .environmentObject(preferencesManager)
        }
    }
}

// MARK: - 当前教材信息卡片
private struct CurrentTextbookInfoCard: View {
    @ObservedObject var preferencesManager: UserPreferencesManager
    @State private var showingTextbookSelection = false
    
    private var currentTextbookInfo: String {
        let courseType = preferencesManager.userPreferences.selectedCourseType
        let courseBook: String
        if courseType == .required {
            courseBook = preferencesManager.userPreferences.selectedRequiredCourse.rawValue
        } else {
            courseBook = preferencesManager.userPreferences.selectedElectiveCourse.rawValue
        }
        
        let selectedUnits = preferencesManager.userPreferences.selectedUnits
        let unitsText: String
        if selectedUnits.count == 1 {
            unitsText = selectedUnits.first?.displayName ?? "第1单元"
        } else if selectedUnits.count <= 3 {
            let unitNames = selectedUnits.sorted { $0.rawValue < $1.rawValue }.map { "U\($0.rawValue)" }
            unitsText = unitNames.joined(separator: ", ")
        } else {
            unitsText = "共\(selectedUnits.count)个单元"
        }
        
        return "\(courseBook) · \(unitsText)"
    }
    
    private var textbookVersionInfo: String {
        let version = preferencesManager.userPreferences.selectedTextbookVersion
        return "\(version.rawValue)版"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题和切换按钮
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    
                    Text("当前学习")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button("切换") {
                    showingTextbookSelection = true
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // 教材信息展示
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentTextbookInfo)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text(textbookVersionInfo)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // 教材图标
                    VStack {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)
                        
                        Text("高中英语")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                
                // 学习进度提示
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Text("学习这些单元的单词，退出后可快速切换")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
        .sheet(isPresented: $showingTextbookSelection) {
            TextbookSelectionView(userPreferences: .constant(preferencesManager.userPreferences))
                .environmentObject(preferencesManager)
        }
    }
}

// MARK: - 记忆健康状态卡片
private struct MemoryHealthCard: View {
    @ObservedObject var manager: WrongWordManager
    @State private var animatePoints = false
    
    var urgentWordsCount: Int {
        manager.todayReviewWords.count
    }
    
    var totalWordsCount: Int {
        manager.wrongWords.count
    }
    
    var masteredWordsCount: Int {
        manager.wrongWords.filter { $0.isMastered }.count
    }
    
    var memoryHealthPercentage: Int {
        guard totalWordsCount > 0 else { return 100 }
        return Int((Double(masteredWordsCount) / Double(totalWordsCount)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("记忆健康状态")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                
                // 健康度百分比
                HStack(spacing: 4) {
                    Image(systemName: healthIcon)
                        .font(.caption)
                        .foregroundStyle(healthColor)
                    Text("\(memoryHealthPercentage)%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(healthColor)
                }
            }
            
            // 简化的遗忘曲线
            SimplifiedForgettingCurve(
                totalWords: totalWordsCount,
                urgentWords: urgentWordsCount,
                masteredWords: masteredWordsCount,
                animatePoints: animatePoints
            )
            
            // 底部统计信息
            HStack(spacing: 20) {
                StatInfo(
                    icon: "checkmark.circle.fill",
                    title: "已掌握",
                    value: "\(masteredWordsCount)",
                    color: .green
                )
                
                StatInfo(
                    icon: "clock.fill",
                    title: "待复习",
                    value: "\(urgentWordsCount)",
                    color: urgentWordsCount > 0 ? .red : .orange
                )
                
                StatInfo(
                    icon: "book.closed.fill",
                    title: "总词汇",
                    value: "\(totalWordsCount)",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary.opacity(0.5), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                animatePoints = true
            }
        }
    }
    
    private var healthIcon: String {
        switch memoryHealthPercentage {
        case 80...100: return "heart.fill"
        case 60..<80: return "heart"
        case 40..<60: return "heart.slash"
        default: return "heart.slash.fill"
        }
    }
    
    private var healthColor: Color {
        switch memoryHealthPercentage {
        case 80...100: return .green
        case 60..<80: return .orange
        case 40..<60: return .red
        default: return .red
        }
    }
}

// MARK: - 简化的遗忘曲线
private struct SimplifiedForgettingCurve: View {
    let totalWords: Int
    let urgentWords: Int
    let masteredWords: Int
    let animatePoints: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景曲线
                ForgettingCurvePath()
                    .stroke(.tertiary.opacity(0.3), lineWidth: 2)
                
                // 记忆强度区域填充
                ForgettingCurvePath()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.1), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // 已掌握的点（绿色）
                if masteredWords > 0 {
                    ForEach(0..<min(masteredWords, 8), id: \.self) { index in
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                            .position(
                                x: geometry.size.width * (0.1 + CGFloat(index) * 0.1),
                                y: geometry.size.height * 0.3
                            )
                            .scaleEffect(animatePoints ? 1.0 : 0.5)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                                value: animatePoints
                            )
                    }
                }
                
                // 紧急复习的点（红色）
                if urgentWords > 0 {
                    ForEach(0..<min(urgentWords, 5), id: \.self) { index in
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .position(
                                x: geometry.size.width * (0.7 + CGFloat(index) * 0.05),
                                y: geometry.size.height * (0.8 + CGFloat(index) * 0.02)
                            )
                            .scaleEffect(animatePoints ? 1.2 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: animatePoints
                            )
                    }
                }
                
                // 时间轴标签
                VStack {
                    Spacer()
                    HStack {
                        Text("今日")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("3天")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("1周")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("1月")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)
                }
            }
        }
        .frame(height: 80)
    }
}

// MARK: - 统计信息组件
private struct StatInfo: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - 学习模式选择卡片
private struct LearningModeSelectionCard: View {
    let dailyStudyAmount: DailyStudyAmount
    let onCardModeSelected: () -> Void
    let onListModeSelected: () -> Void
    let onDictationModeSelected: () -> Void // 新增：听写模式回调
    let onParentDictationModeSelected: () -> Void // 新增：家长听写模式回调
    let onEditStudyAmount: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部标题区域
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // 推荐标签
                    HStack(spacing: 6) {
                        Text("推荐")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.9))
                            )
                        
                        Spacer()
                    }
                    
                    // 主标题
                    Text("选择学习模式")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    // 副标题
                    Text("卡片模式深度记忆，列表模式快速检测")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 智能图标
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
            
            // 学习模式按钮组
            VStack(spacing: 12) {
                // 第一行：卡片模式和列表模式
                HStack(spacing: 12) {
                    // 卡片模式按钮
                    Button(action: onCardModeSelected) {
                        VStack(spacing: 8) {
                            Image(systemName: "rectangle.stack")
                                .font(.title3)
                                .foregroundStyle(.white)
                            
                            Text("卡片模式")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("逐个学习")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // 列表模式按钮
                    Button(action: onListModeSelected) {
                        VStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.title3)
                                .foregroundStyle(.white)
                            
                            Text("列表模式")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("批量检测")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // 第二行：听写模式（独占一行，突出显示）
                Button(action: onDictationModeSelected) {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.and.outline")
                            .font(.title2)
                            .foregroundStyle(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("听写模式")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("听中文含义，直接拼写英文单词")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // 新功能标签
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.yellow.opacity(0.9))
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.4), lineWidth: 1.5)
                            )
                    )
                }
                
                // 第三行：家长听写模式（独占一行，突出显示）
                Button(action: onParentDictationModeSelected) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.write")
                            .font(.title2)
                            .foregroundStyle(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("家长听写模式")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("纸上手写单词，拍照智能识别检测")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // 热门标签
                        Text("HOT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.9))
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.5), lineWidth: 2)
                            )
                    )
                }
            }
            
            // 学习量设置
            Button(action: onEditStudyAmount) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("今日学习 \(dailyStudyAmount.displayName)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("(点击调整)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .background(
            // 立体渐变效果
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.4, blue: 1.0),
                            Color(red: 0.6, green: 0.2, blue: 0.9),
                            Color(red: 0.8, green: 0.1, blue: 0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // 光泽效果
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.1),
                                    .clear,
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}

// MARK: - 听写模式主视图
struct DictationModeMainView: View {
    @ObservedObject var hybridManager: HybridLearningManager
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var appwriteService: AppwriteService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            HybridLearningView(hybridManager: hybridManager, initialMode: .dictation)
                .environmentObject(preferencesManager)
                .environmentObject(wrongWordManager)
                .environmentObject(appwriteService)
                .onAppear {
                    // 设置为听写模式
                    Task {
                        // 确保有学习单词
                        if hybridManager.todayWords.isEmpty {
                            await hybridManager.preloadAllWords(preferencesManager: preferencesManager)
                            let targetCount = preferencesManager.userPreferences.dailyStudyAmount.rawValue
                            await hybridManager.generateTodayWords(learningMode: .dictation, targetCount: targetCount)
                        }
                        
                        print("🎯 听写模式已启动，单词数量: \(hybridManager.todayWords.count)")
                    }
                }
        }
    }
}


// MARK: - Preview
#Preview {
    TodayTasksView()
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}

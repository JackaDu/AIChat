import Foundation
import UIKit

// MARK: - 学习模式枚举
enum LearningMode: String, CaseIterable {
    case review = "复习模式"
    case hybrid = "混合模式"
    case challenge = "挑战模式"
    
    var description: String {
        switch self {
        case .review:
            return "重点复习错题，巩固薄弱环节"
        case .hybrid:
            return "错题复习 + 新单词学习，平衡发展"
        case .challenge:
            return "以新单词为主，拓展词汇量"
        }
    }
    
    var emoji: String {
        switch self {
        case .review: return "🔄"
        case .hybrid: return "⚖️"
        case .challenge: return "🚀"
        }
    }
}

// MARK: - 智能混合学习管理器
class HybridLearningManager: ObservableObject {
    @Published var todayWords: [StudyWord] = []
    @Published var learningProgress: Double = 0.0
    @Published var completedWords: [StudyWord] = []
    @Published var allAvailableWords: [StudyWord] = [] // 所有可用的单词
    @Published var isPreloadingWords: Bool = false // 预加载状态
    
    // 预生成进度追踪
    @Published var isPreGeneratingOptions: Bool = false
    @Published var preGenerationProgress: Double = 0.0
    @Published var preGenerationStatus: String = ""
    @Published var studyMode: StudyMode = .card // 学习显示模式
    @Published var isFromListMode: Bool = false // 是否从列表模式跳转
    
    private let wrongWordManager = WrongWordManager()
    private let wordDataManager: WordDataManager
    
    private let appwriteService: AppwriteService
    
    init(appwriteService: AppwriteService) {
        self.appwriteService = appwriteService
        self.wordDataManager = WordDataManager(appwriteService: appwriteService)
    }
    private var currentMode: LearningMode = .hybrid
    
    
    // 预加载所有可用的单词
    func preloadAllWords(preferencesManager: UserPreferencesManager) async {
        await MainActor.run {
            isPreloadingWords = true
        }
        
        print("开始预加载所有单词...")
        NSLog("🚀 HybridLearningManager: 开始预加载所有单词...")
        
        do {
            // 直接从数据库加载单词
            let preferences = await preferencesManager.userPreferences
            
            let databaseWords = try await wordDataManager.loadWordsFromDatabase(
                grade: preferences.selectedGrade,
                textbook: preferences.selectedTextbookVersion.rawValue,
                unit: "unit\(preferences.selectedUnits.first?.rawValue ?? 1)"
            )
            
            // 获取错题
            let wrongWords = wrongWordManager.wrongWords
            
            await MainActor.run {
                // 合并所有单词
                var allWords: [StudyWord] = []
                
                // 添加错题
                for wrongWord in wrongWords {
                    allWords.append(StudyWord.fromWrongWord(wrongWord))
                }
                
                // 添加数据库单词
                allWords.append(contentsOf: databaseWords)
                
                print("📊 数据加载统计:")
                print("- 错题数量: \(wrongWords.count)")
                print("- 数据库单词数量: \(databaseWords.count)")
                
                // 去重（基于单词内容）
                let uniqueWords = Array(Set(allWords.map { $0.word }))
                self.allAvailableWords = allWords.filter { word in
                    uniqueWords.contains(word.word)
                }
                
                self.isPreloadingWords = false
                print("📊 预加载完成，共有 \(self.allAvailableWords.count) 个可用单词")
            }
            
        } catch {
            await MainActor.run {
                self.isPreloadingWords = false
                print("预加载失败: \(error)")
            }
        }
    }
    
    // 根据用户设定的数量生成学习单词
    func generateTodayWords(learningMode: LearningDirection, targetCount: Int) async {
        print("生成今日学习内容:")
        print("- 可用单词数量: \(allAvailableWords.count)")
        print("- 目标学习数量: \(targetCount)")
        print("- 当前学习模式: \(currentMode.rawValue)")
        print("- 学习方向: \(learningMode.displayName)")
        
        // 过滤掉已经完成的单词
        let completedWordIds = Set(completedWords.map { $0.word })
        var availableWords = allAvailableWords.filter { !completedWordIds.contains($0.word) }
        
        // 过滤掉已掌握的单词
        let masteredWordsCount = availableWords.count
        availableWords = availableWords.filter { word in
            !wrongWordManager.isWordMastered(word.word)
        }
        let filteredMasteredCount = masteredWordsCount - availableWords.count
        
        print("- 未完成单词数量: \(availableWords.count)")
        print("- 已掌握单词数量: \(filteredMasteredCount)")
        
        // 使用当前时间戳和学习方向生成动态随机种子，避免重复显示相同单词
        let baseTime = Int(Date().timeIntervalSince1970)
        let seed: Int
        switch learningMode {
        case .recognizeMeaning:
            seed = baseTime + 1
        case .recallWord:
            seed = baseTime + 2
        case .dictation:
            seed = baseTime + 3
        }
        
        // 创建基于动态种子的随机数生成器
        var generator = SeededRandomNumberGenerator(seed: UInt64(seed))
        
        // 随机选择指定数量的单词
        let actualCount = min(targetCount, availableWords.count)
        let selectedWords = Array(availableWords.shuffled(using: &generator).prefix(actualCount))
        
        await MainActor.run {
            todayWords = selectedWords
            learningProgress = 0.0
            
            print("- 最终生成学习单词数量: \(todayWords.count)")
            print("- 使用随机种子: \(seed)")
            
            // 预生成所有单词的选项
            Task {
                await preGenerateOptionsForAllWords(learningMode: learningMode)
            }
        }
    }
    
    // 预生成所有单词的选项
    func preGenerateOptionsForAllWords(learningMode: LearningDirection) async {
        print("开始预生成所有单词的选项...")
        
        guard !todayWords.isEmpty else {
            print("没有单词需要预生成选项")
            return
        }
        
        await MainActor.run {
            isPreGeneratingOptions = true
            preGenerationProgress = 0.0
            preGenerationStatus = "准备生成选项..."
        }
        
        // 构建批量请求的提示词
        // No longer need batch prompt since we're using direct Excel/local generation
        
        do {
            await MainActor.run {
                preGenerationStatus = "正在请求AI生成选项..."
                preGenerationProgress = 0.2
            }
            
            // 优先使用Excel预生成选项，只为没有预生成选项的单词生成新选项
            print("开始混合选项生成（Excel优先）")
            let allOptions = generateMixedOptions(for: todayWords, learningMode: learningMode)
            
            await MainActor.run {
                preGenerationStatus = "正在应用选项..."
                preGenerationProgress = 0.7
                
                // 创建todayWords的可变副本
                var updatedWords = todayWords
                
                // 将生成的选项分配给对应的单词
                for (index, studyWord) in updatedWords.enumerated() {
                    if index < allOptions.count {
                        updatedWords[index].preGeneratedOptions = allOptions[index]
                        print("设置选项 [\(index + 1)/\(todayWords.count)]: \(studyWord.word) - 选项: \(allOptions[index])")
                    } else {
                        // 没有预生成选项，设置为空数组
                        updatedWords[index].preGeneratedOptions = []
                        print("⚠️ 未找到预生成选项 [\(index + 1)/\(todayWords.count)]: \(studyWord.word)")
                    }
                    
                    // 更新进度
                    let progress = 0.7 + (Double(index + 1) / Double(todayWords.count)) * 0.3
                    preGenerationProgress = progress
                    preGenerationStatus = "应用选项 \(index + 1)/\(todayWords.count)"
                }
                
                // 重新分配整个数组以触发@Published更新
                self.todayWords = updatedWords
                preGenerationProgress = 1.0
                preGenerationStatus = "选项生成完成！"
                print("所有单词的选项预生成完成，更新了 \(todayWords.count) 个单词")
                
                // 短暂延迟后隐藏进度
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isPreGeneratingOptions = false
                }
            }
            
        } catch {
            print("混合选项生成失败: \(error.localizedDescription)")
            print("使用纯本地生成...")
            
            await MainActor.run {
                preGenerationStatus = "使用数据库选项..."
                preGenerationProgress = 0.5
                
                // 创建todayWords的可变副本
                var updatedWords = todayWords
                
                // 生成失败时，为所有单词使用数据库选项
                for (index, studyWord) in updatedWords.enumerated() {
                    // 直接使用数据库中的预生成选项
                    if let databaseOptions = self.getDatabasePreGeneratedOptions(for: studyWord, learningMode: learningMode) {
                        updatedWords[index].preGeneratedOptions = databaseOptions
                        print("使用数据库选项 [\(index + 1)/\(todayWords.count)]: \(studyWord.word) - 选项: \(databaseOptions)")
                    } else {
                        updatedWords[index].preGeneratedOptions = []
                        print("⚠️ 未找到数据库预生成选项 [\(index + 1)/\(todayWords.count)]: \(studyWord.word)")
                    }
                    
                    // 更新进度
                    let progress = 0.5 + (Double(index + 1) / Double(todayWords.count)) * 0.5
                    preGenerationProgress = progress
                    preGenerationStatus = "生成选项 \(index + 1)/\(todayWords.count)"
                }
                
                self.todayWords = updatedWords
                preGenerationProgress = 1.0
                preGenerationStatus = "选项生成完成！"
                print("所有单词的选项生成完成")
                
                // 短暂延迟后隐藏进度
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isPreGeneratingOptions = false
                }
            }
        }
    }
    
    
    // 选项生成：直接使用数据库中的预生成选项
    private func generateMixedOptions(for words: [StudyWord], learningMode: LearningDirection) -> [[String]] {
        // 听写模式不需要选项，直接返回空数组
        if learningMode == .dictation {
            print("🎯 听写模式不需要生成选项，跳过选项生成")
            return Array(repeating: [], count: words.count)
        }
        
        var allOptions: [[String]] = []
        
        for studyWord in words {
            // 直接从StudyWord对象获取数据库中的预生成选项
            if let databaseOptions = getDatabasePreGeneratedOptions(for: studyWord, learningMode: learningMode) {
                allOptions.append(databaseOptions)
                print("✅ 使用数据库选项: \(studyWord.word) - \(databaseOptions)")
            } else {
                // 如果没有预生成选项，使用空数组
                allOptions.append([])
                print("⚠️ 单词 \(studyWord.word) 没有预生成选项，跳过")
            }
        }
        
        return allOptions
    }
    
    // 从数据库StudyWord对象获取预生成选项
    private func getDatabasePreGeneratedOptions(for studyWord: StudyWord, learningMode: LearningDirection) -> [String]? {
        print("🔍 检查单词 \(studyWord.word) 的数据库选项:")
        print("   - misleadingChineseOptions: \(studyWord.misleadingChineseOptions)")
        print("   - misleadingEnglishOptions: \(studyWord.misleadingEnglishOptions)")
        print("   - 学习模式: \(learningMode)")
        
        // 根据学习模式获取对应的预生成选项
        let misleadingOptions: [String]
        switch learningMode {
        case .recognizeMeaning:
            // 英译中：使用中文误导选项
            misleadingOptions = studyWord.misleadingChineseOptions
        case .recallWord:
            // 中译英：使用英文误导选项
            misleadingOptions = studyWord.misleadingEnglishOptions
        case .dictation:
            // 听写模式：不需要选项
            return nil
        }
        
        // 检查选项是否为空
        print("🔍 检查选项是否为空:")
        print("   - misleadingOptions: \(misleadingOptions)")
        print("   - misleadingOptions.isEmpty: \(misleadingOptions.isEmpty)")
        print("   - misleadingOptions.count: \(misleadingOptions.count)")
        
        guard !misleadingOptions.isEmpty else {
            print("⚠️ 单词 \(studyWord.word) 的预生成选项为空")
            return nil
        }
        
        print("✅ 找到单词 \(studyWord.word) 的数据库预生成选项: \(misleadingOptions)")
        
        // 构建完整的选项列表（包含正确答案）
        let correctAnswer = learningMode == .recognizeMeaning ? studyWord.meaning : studyWord.word
        var allOptions = misleadingOptions
        
        // 确保正确答案包含在选项中
        if !allOptions.contains(correctAnswer) {
            allOptions.append(correctAnswer)
        }
        
        // 打乱顺序并限制为4个选项
        return Array(allOptions.shuffled().prefix(4))
    }
    
    // 更新学习进度
    func updateProgress(completedCount: Int) {
        learningProgress = Double(completedCount) / Double(todayWords.count)
    }
    
    // 获取学习统计
    func getLearningStats() -> LearningStats {
        let totalWords = todayWords.count
        let wrongWords = todayWords.filter { $0.source == .wrongWord }.count
        let newWords = todayWords.filter { $0.source == .imported }.count
        
        return LearningStats(
            totalWords: totalWords,
            wrongWords: wrongWords,
            newWords: newWords,
            mode: currentMode
        )
    }
    
    // 标记学习完成
    func markLearningComplete() {
        completedWords = todayWords
        learningProgress = 1.0
    }
    
    
    
    // MARK: - 从列表模式跳转到卡片模式
    /// 从外部单词列表设置学习单词
    func loadWordsFromList(_ words: [StudyWord]) {
        print("🔄 HybridLearningManager: 从列表模式加载单词到卡片模式")
        print("- 单词数量: \(words.count)")
        print("- 单词列表: \(words.map { $0.word })")
        
        Task { @MainActor in
            print("🔄 开始设置单词到 todayWords")
            self.todayWords = words
            self.learningProgress = 0.0
            self.completedWords = []
            self.isFromListMode = true // 标记是从列表模式跳转
            self.isPreloadingWords = false // 确保不是预加载状态
            self.isPreGeneratingOptions = false // 确保不是预生成状态
            
            print("✅ 卡片模式单词设置完成")
            print("- todayWords.count: \(self.todayWords.count)")
            print("- todayWords内容: \(self.todayWords.map { $0.word })")
            print("- isFromListMode: \(self.isFromListMode)")
            print("- isPreloadingWords: \(self.isPreloadingWords)")
            print("- isPreGeneratingOptions: \(self.isPreGeneratingOptions)")
        }
    }
}

// MARK: - 基于种子的随机数生成器
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private let multiplier: UInt64 = 6364136223846793005
    private let increment: UInt64 = 1442695040888963407
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = multiplier &* state &+ increment
        return state
    }
}

// MARK: - 学习单词模型
struct StudyWord: Identifiable {
    let id = UUID()
    let word: String
    let meaning: String
    let example: String
    let difficulty: String
    let category: String
    let grade: Grade
    let source: WordSource
    var isCorrect: Bool?
    var answerTime: TimeInterval?
    
    // 预生成的选项（用于提升用户体验）
    var preGeneratedOptions: [String]?
    
    // 数据库中的预生成误导选项
    var misleadingChineseOptions: [String] = []
    var misleadingEnglishOptions: [String] = []
    
    // 新增图片和记忆辅助字段
    var imageURL: String? // 单词相关图片URL
    var etymology: String? // 词源信息
    var memoryTip: String? // 记忆技巧
    var relatedWords: [String]? // 相关单词
    
    // 错题本相关字段
    var errorCount: Int? // 错误次数（仅用于错词本导出）
    
    // 从错题创建
    static func fromWrongWord(_ wrongWord: WrongWord) -> StudyWord {
        var studyWord = StudyWord(
            word: wrongWord.word,
            meaning: wrongWord.meaning,
            example: wrongWord.context,
            difficulty: "unknown",
            category: "unknown",
            grade: .high1,
            source: .wrongWord,
            preGeneratedOptions: nil
        )
        studyWord.imageURL = wrongWord.imageURL
        studyWord.etymology = wrongWord.etymology
        studyWord.memoryTip = wrongWord.memoryTip
        studyWord.relatedWords = wrongWord.relatedWords
        studyWord.errorCount = wrongWord.errorCount // 保存错误次数
        return studyWord
    }
    
}

// MARK: - 学习记录模型
struct StudyRecord: Identifiable, Codable {
    let id = UUID()
    let userId: String
    let word: String
    let meaning: String
    let context: String
    let learningDirection: LearningDirection
    let isCorrect: Bool
    let answerTime: TimeInterval
    let memoryStrength: Double
    let streakCount: Int
    let studyDate: Date
    let deviceId: String
    
    init(userId: String, word: String, meaning: String, context: String, 
         learningDirection: LearningDirection, isCorrect: Bool, 
         answerTime: TimeInterval, memoryStrength: Double, streakCount: Int) {
        self.userId = userId
        self.word = word
        self.meaning = meaning
        self.context = context
        self.learningDirection = learningDirection
        self.isCorrect = isCorrect
        self.answerTime = answerTime
        self.memoryStrength = memoryStrength
        self.streakCount = streakCount
        self.studyDate = Date()
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    
}

// MARK: - 单词来源
enum WordSource: String, CaseIterable {
    case wrongWord = "错题本"
    case imported = "新单词"
    
    var emoji: String {
        switch self {
        case .wrongWord: return "❌"
        case .imported: return "🆕"
        }
    }
}

// MARK: - 学习统计
struct LearningStats {
    let totalWords: Int
    let wrongWords: Int
    let newWords: Int
    let mode: LearningMode
    
    var wrongWordPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(wrongWords) / Double(totalWords) * 100
    }
    
    var newWordPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(newWords) / Double(totalWords) * 100
    }
}


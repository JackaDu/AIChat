import Foundation
import SwiftUI

// MARK: - 按教材管理的错词数据结构
struct TextbookWrongWords: Codable {
    var words: [WrongWord] = []
    let courseType: CourseType
    let courseBook: String
    
    init(courseType: CourseType, courseBook: String) {
        self.courseType = courseType
        self.courseBook = courseBook
    }
}

// MARK: - 错题本管理器
class WrongWordManager: ObservableObject {
    // 按教材存储错词
    @Published var textbookWrongWords: [String: TextbookWrongWords] = [:]
    @Published var todayReviewWords: [WrongWord] = []
    
    // 多选状态管理
    @Published var isSelectionMode: Bool = false
    @Published var selectedWords: Set<UUID> = []
    
    // 数据库服务
    var databaseService: WrongWordDatabaseService?
    private let userDefaults = UserDefaults.standard
    private let wrongWordsKey = "TextbookWrongWords"
    
    // 当前显示的错词（基于当前选择的教材）
    var wrongWords: [WrongWord] {
        get {
            let currentKey = getCurrentTextbookKey()
            return textbookWrongWords[currentKey]?.words ?? []
        }
        set {
            let currentKey = getCurrentTextbookKey()
            if textbookWrongWords[currentKey] == nil {
                // 从UserDefaults直接读取用户偏好设置
                let userDefaults = UserDefaults.standard
                let preferencesKey = "UserPreferences"
                
                if let data = userDefaults.data(forKey: preferencesKey),
                   let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
                    let courseType = preferences.selectedCourseType
                    let courseBook = courseType == .required ? 
                        preferences.selectedRequiredCourse.rawValue :
                        preferences.selectedElectiveCourse.rawValue
                    textbookWrongWords[currentKey] = TextbookWrongWords(courseType: courseType, courseBook: courseBook)
                } else {
                    // 默认创建必修1
                    textbookWrongWords[currentKey] = TextbookWrongWords(courseType: .required, courseBook: "必修1")
                }
            }
            textbookWrongWords[currentKey]?.words = newValue
        }
    }
    
    // 初始化方法
    init(appwriteService: AppwriteService? = nil) {
        if let appwriteService = appwriteService {
            self.databaseService = WrongWordDatabaseService(appwriteService: appwriteService)
        }
        loadWrongWords()
        
        // 如果用户已登录，同步数据
        Task { @MainActor in
            if appwriteService?.isAuthenticated == true {
                await syncWithDatabase()
            }
        }
    }
    
    // 获取当前教材的唯一标识符
    private func getCurrentTextbookKey() -> String {
        // 从UserDefaults直接读取用户偏好设置
        let userDefaults = UserDefaults.standard
        let preferencesKey = "UserPreferences"
        
        if let data = userDefaults.data(forKey: preferencesKey),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            let courseType = preferences.selectedCourseType
            let courseBook = courseType == .required ? 
                preferences.selectedRequiredCourse.rawValue :
                preferences.selectedElectiveCourse.rawValue
            return "\(courseType.rawValue)_\(courseBook)"
        }
        
        // 默认返回必修1
        return "required_必修1"
    }
    
    // 新增状态变量
    @Published var selectedGroupOption: WrongWordGroupOption = .all
    @Published var selectedSortOption: WrongWordSortOption = .byDate
    @Published var searchText: String = ""
    @Published var showingAdvancedFilters = false
    
    // 新增筛选器
    @Published var selectedTextbookSources: Set<TextbookSource> = []
    @Published var selectedPartOfSpeech: Set<PartOfSpeech> = []
    @Published var selectedExamSources: Set<ExamSource> = []
    @Published var selectedDifficulties: Set<WordDifficulty> = []
    @Published var selectedLearningDirections: Set<LearningDirection> = []
    @Published var selectedMasteryLevels: Set<String> = []
    @Published var viewMode: WordViewMode = .list
    
    // MARK: - 计算属性
    var masteredWordsCount: Int {
        wrongWords.filter { $0.isMastered }.count
    }
    
    // MARK: - 单元统计
    
    // 获取当前单元的进度统计
    var currentUnitProgress: UnitProgress {
        // 从UserDefaults直接读取用户偏好设置
        let userDefaults = UserDefaults.standard
        let preferencesKey = "UserPreferences"
        
        var userPreferences: UserPreferences
        if let data = userDefaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            userPreferences = decoded
        } else {
            userPreferences = UserPreferences() // 使用默认值
        }
        
        // 获取当前选择的单元
        let selectedUnits = userPreferences.selectedUnits
        guard let currentUnit = selectedUnits.first else {
            // 如果没有选择单元，返回第一个单元的进度
            return getUnitProgress(for: .unit1)
        }
        
        return getUnitProgress(for: currentUnit)
    }
    
    // 获取指定单元的进度统计
    private func getUnitProgress(for unit: Unit) -> UnitProgress {
        // 从UserDefaults直接读取用户偏好设置
        let userDefaults = UserDefaults.standard
        let preferencesKey = "UserPreferences"
        
        var userPreferences: UserPreferences
        if let data = userDefaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            userPreferences = decoded
        } else {
            userPreferences = UserPreferences() // 使用默认值
        }
        
        // 获取当前教材的错词
        let currentKey = getCurrentTextbookKey()
        let currentTextbookWords = textbookWrongWords[currentKey]?.words ?? []
        
        // 过滤出指定单元的单词
        let unitWords = currentTextbookWords.filter { word in
            word.textbookSource?.unit == unit
        }
        
        // 计算各类词汇数量
        let masteredWords = unitWords.filter { $0.isMastered }.count
        let wrongWordsCount = unitWords.filter { !$0.isMastered }.count
        
        // 获取该单元的总词数（从数据库统计）
        let unitTotalWords = getUnitTotalWords(for: unit, userPreferences: userPreferences)
        
        // 剩余单词 = 单元总词数 - 已掌握的单词
        let remainingWords = max(0, unitTotalWords - masteredWords)
        
        return UnitProgress(
            unit: unit,
            totalWords: unitTotalWords,
            masteredWords: masteredWords,
            wrongWords: wrongWordsCount,
            remainingWords: remainingWords
        )
    }
    
    // 获取单元的总词数
    private func getUnitTotalWords(for unit: Unit, userPreferences: UserPreferences) -> Int {
        // 这里需要从数据库中统计该单元的词数
        // 暂时返回一个估算值，实际应该从数据源统计
        let courseType = userPreferences.selectedCourseType
        let _ = courseType == .required ? 
            userPreferences.selectedRequiredCourse.rawValue :
            userPreferences.selectedElectiveCourse.rawValue
        
        // 根据单元估算词数（实际应该从数据源统计）
        switch unit {
        case .unit1: return 50
        case .unit2: return 50
        case .unit3: return 50
        case .unit4: return 50
        case .unit5: return 50
        case .unit6: return 50
        }
    }
    
    // 获取整本教材的进度统计
    var textbookProgress: UnitProgress {
        // 从UserDefaults直接读取用户偏好设置，避免循环依赖
        let userDefaults = UserDefaults.standard
        let preferencesKey = "UserPreferences"
        
        var userPreferences: UserPreferences
        if let data = userDefaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            userPreferences = decoded
        } else {
            userPreferences = UserPreferences() // 使用默认值
        }
        
        // 获取当前教材的所有错词
        let currentTextbookWords = wrongWords.filter { word in
            guard let textbookSource = word.textbookSource else { return false }
            
            // 检查是否是当前选中的教材
            let currentCourseType = userPreferences.selectedCourseType
            let currentCourse = currentCourseType == .required ? 
                userPreferences.selectedRequiredCourse.rawValue :
                userPreferences.selectedElectiveCourse.rawValue
            
            return textbookSource.courseType == currentCourseType &&
                   textbookSource.courseBook == currentCourse
        }
        
        // 获取教材总词数（从数据库统计）
        let textbookTotalWords = getTextbookTotalWords(for: userPreferences)
        
        // 计算各类词汇数量
        let masteredWords = currentTextbookWords.filter { $0.isMastered }.count
        let wrongWordsCount = currentTextbookWords.filter { !$0.isMastered }.count
        // 剩余单词 = 教材总词数 - 已掌握的单词
        let remainingWords = max(0, textbookTotalWords - masteredWords)
        
        return UnitProgress(
            unit: .unit1, // 使用第一个单元作为占位符，实际表示整本教材
            totalWords: textbookTotalWords, // 使用教材总词数
            masteredWords: masteredWords,
            wrongWords: wrongWordsCount,
            remainingWords: remainingWords
        )
    }
    
    // 获取教材总词数（从数据库获取）
    private func getTextbookTotalWords(for preferences: UserPreferences) -> Int {
        // 由于我们现在完全依赖数据库，这里返回一个合理的估算值
        // 实际的总词数应该从数据库异步获取，但为了保持同步方法的兼容性，
        // 我们使用错词数量作为基础来估算
        let estimatedTotalWords = max(wrongWords.count * 10, 1000) // 假设错词占总词数的10%
        
        print("📚 估算教材总词数: \(estimatedTotalWords) (基于 \(wrongWords.count) 个错词)")
        return estimatedTotalWords
    }
    
    // 获取总体进度统计（现在就是整本教材的进度）
    var overallProgress: UnitProgress {
        return textbookProgress
    }
    
    // 新增计算属性
    var filteredAndSortedWords: [WrongWord] {
        let filtered = getFilteredWords()
        return getSortedWords(filtered)
    }
    
    var groupedWords: [String: [WrongWord]] {
        switch selectedGroupOption {
        case .all:
            return ["全部": filteredAndSortedWords]
        case .textbookSource:
            return Dictionary(grouping: filteredAndSortedWords) { word in
                word.textbookSource?.displayText ?? "未分组"
            }
        case .partOfSpeech:
            return Dictionary(grouping: filteredAndSortedWords) { word in
                word.partOfSpeech?.displayName ?? "未分组"
            }
        case .examSource:
            return Dictionary(grouping: filteredAndSortedWords) { word in
                word.examSource?.displayName ?? "未分组"
            }
        case .difficulty:
            return Dictionary(grouping: filteredAndSortedWords) { word in
                word.difficulty.displayName
            }
        case .learningDirection:
            return Dictionary(grouping: filteredAndSortedWords) { word in
                word.learningDirection.displayName
            }
        case .mastery:
            return Dictionary(grouping: filteredAndSortedWords) { word in
                word.masteryLevel
            }
        }
    }
    
    var availableTextbookSources: [TextbookSource] {
        Array(Set(wrongWords.compactMap { $0.textbookSource })).sorted { 
            $0.displayText < $1.displayText 
        }
    }
    
    var availablePartOfSpeech: [PartOfSpeech] {
        Array(Set(wrongWords.compactMap { $0.partOfSpeech })).sorted { $0.displayName < $1.displayName }
    }
    
    var availableExamSources: [ExamSource] {
        Array(Set(wrongWords.compactMap { $0.examSource })).sorted { $0.displayName < $1.displayName }
    }
    
    var availableDifficulties: [WordDifficulty] {
        Array(Set(wrongWords.map { $0.difficulty })).sorted { $0.rawValue < $1.rawValue }
    }
    
    var availableLearningDirections: [LearningDirection] {
        Array(Set(wrongWords.map { $0.learningDirection })).sorted { $0.displayName < $1.displayName }
    }
    
    var availableMasteryLevels: [String] {
        Array(Set(wrongWords.map { $0.masteryLevel })).sorted()
    }
    
    // 统计信息
    var totalWordsCount: Int { wrongWords.count }
    var unmasteredWordsCount: Int { wrongWords.filter { !$0.isMastered }.count }
    var urgentWordsCount: Int { todayReviewWords.count }
    var totalReviewCount: Int { wrongWords.reduce(0) { $0 + $1.reviewCount } }
    var averageErrorRate: Double {
        guard !wrongWords.isEmpty else { return 0.0 }
        let totalRate = wrongWords.reduce(0.0) { $0 + $1.errorRate }
        return totalRate / Double(wrongWords.count)
    }
    
    init() {
        loadWrongWords()
        
        // 如果没有数据，添加模拟数据用于演示
        if wrongWords.isEmpty {
            addSimulatedData()
        }
        
        updateTodayReviewWords()
    }
    
    // MARK: - 数据持久化
    private func loadWrongWords() {
        // 首先尝试加载新的数据结构
        if let data = userDefaults.data(forKey: wrongWordsKey),
           let textbookWords = try? JSONDecoder().decode([String: TextbookWrongWords].self, from: data) {
            self.textbookWrongWords = textbookWords
        } else {
            // 兼容旧数据格式
            if let data = userDefaults.data(forKey: "WrongWords"),
               let words = try? JSONDecoder().decode([WrongWord].self, from: data) {
                // 将旧数据迁移到新结构
                migrateOldWrongWords(words)
            }
        }
        // 加载错词后，更新今日复习单词列表
        updateTodayReviewWords()
    }
    
    private func saveWrongWords() {
        if let data = try? JSONEncoder().encode(textbookWrongWords) {
            userDefaults.set(data, forKey: wrongWordsKey)
        }
    }
    
    // 迁移旧数据到新结构
    private func migrateOldWrongWords(_ words: [WrongWord]) {
        for word in words {
            if let textbookSource = word.textbookSource {
                let key = "\(textbookSource.courseType.rawValue)_\(textbookSource.courseBook)"
                if textbookWrongWords[key] == nil {
                    textbookWrongWords[key] = TextbookWrongWords(
                        courseType: textbookSource.courseType,
                        courseBook: textbookSource.courseBook
                    )
                }
                textbookWrongWords[key]?.words.append(word)
            }
        }
        saveWrongWords()
        // 删除旧数据
        userDefaults.removeObject(forKey: "WrongWords")
    }
    
    // MARK: - 错题管理
    
    // 获取当前的教材来源信息
    func getCurrentTextbookSource() -> TextbookSource? {
        // 从UserDefaults直接读取用户偏好设置，避免循环依赖
        let userDefaults = UserDefaults.standard
        let preferencesKey = "UserPreferences"
        
        guard let data = userDefaults.data(forKey: preferencesKey),
              let userPreferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return nil
        }
        
        return TextbookSource.current(from: userPreferences)
    }
    
    func addWrongWord(_ word: WrongWord) {
        print("🔍 WrongWordManager.addWrongWord 被调用: \(word.word)")
        print("🔍 数据库服务是否存在: \(databaseService != nil)")
        
        // 确保错词有单元信息
        var wordWithSource = word
        if wordWithSource.textbookSource == nil {
            wordWithSource.textbookSource = getCurrentTextbookSource()
            print("📚 为错词设置单元信息: \(word.word) -> \(wordWithSource.textbookSource?.displayText ?? "无单元信息")")
        }
        
        // 获取当前教材的错词列表
        let currentKey = getCurrentTextbookKey()
        if textbookWrongWords[currentKey] == nil {
            // 从UserDefaults直接读取用户偏好设置
            let userDefaults = UserDefaults.standard
            let preferencesKey = "UserPreferences"
            
            if let data = userDefaults.data(forKey: preferencesKey),
               let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
                let courseType = preferences.selectedCourseType
                let courseBook = courseType == .required ? 
                    preferences.selectedRequiredCourse.rawValue :
                    preferences.selectedElectiveCourse.rawValue
                textbookWrongWords[currentKey] = TextbookWrongWords(courseType: courseType, courseBook: courseBook)
            } else {
                // 默认创建必修1
                textbookWrongWords[currentKey] = TextbookWrongWords(courseType: .required, courseBook: "必修1")
            }
        }
        
        // 检查是否已存在
        if let index = textbookWrongWords[currentKey]?.words.firstIndex(where: { $0.word.lowercased() == wordWithSource.word.lowercased() }) {
            // 更新现有记录 - 只增加错误次数，不增加复习次数
            textbookWrongWords[currentKey]?.words[index].errorCount += 1
            textbookWrongWords[currentKey]?.words[index].totalAttempts += 1
            textbookWrongWords[currentKey]?.words[index].consecutiveWrong += 1
            textbookWrongWords[currentKey]?.words[index].consecutiveCorrect = 0
            textbookWrongWords[currentKey]?.words[index].lastReviewDate = Date()
            
            // 更新单元信息（如果原来没有的话）
            if textbookWrongWords[currentKey]?.words[index].textbookSource == nil {
                textbookWrongWords[currentKey]?.words[index].textbookSource = wordWithSource.textbookSource
                print("📚 更新现有错题的单元信息: \(wordWithSource.word) -> \(wordWithSource.textbookSource?.displayText ?? "无单元信息")")
            }
            
            // 重新计算下次复习日期（基于当前复习次数）
            let reviewCount = textbookWrongWords[currentKey]?.words[index].reviewCount ?? 0
            textbookWrongWords[currentKey]?.words[index].nextReviewDate = EbbinghausCurve.getNextReviewDate(from: Date(), reviewCount: reviewCount)
            print("🔍 更新现有错题记录: \(wordWithSource.word)")
        } else {
            // 添加新记录
            wordWithSource.nextReviewDate = EbbinghausCurve.getNextReviewDate(from: Date(), reviewCount: 0)
            textbookWrongWords[currentKey]?.words.append(wordWithSource)
            print("🔍 添加新错题记录: \(wordWithSource.word)")
        }
        saveWrongWords()
        updateTodayReviewWords()
        
        // 同步到数据库
        Task {
            print("🔍 开始同步错题到数据库: \(wordWithSource.word)")
            await syncWrongWordToDatabase(wordWithSource)
        }
    }
    
    func removeWrongWord(_ word: WrongWord) {
        let currentKey = getCurrentTextbookKey()
        textbookWrongWords[currentKey]?.words.removeAll { $0.id == word.id }
        saveWrongWords()
        updateTodayReviewWords()
        
        // 从数据库删除
        Task {
            await deleteWrongWordFromDatabase(word)
        }
    }
    
    // MARK: - 数据库同步方法
    private func syncWrongWordToDatabase(_ word: WrongWord) async {
        print("🔍 syncWrongWordToDatabase 开始: \(word.word)")
        print("🔍 databaseService 是否存在: \(databaseService != nil)")
        
        guard let databaseService = databaseService else { 
            print("❌ databaseService 为 nil，无法同步到数据库")
            return 
        }
        
        do {
            // 对于新添加的错词，总是尝试创建新记录
            // 如果记录已存在，数据库会返回409错误，我们忽略即可
            print("🔍 尝试创建新记录: \(word.word)")
            _ = try await databaseService.createWrongWord(word)
            print("✅ 错题记录同步到数据库成功: \(word.word)")
        } catch AppwriteError.apiError(let message) {
            if message.contains("already exists") || message.contains("409") {
                print("⚠️ 错题记录已存在，跳过创建: \(word.word)")
            } else {
                print("❌ 错题记录同步到数据库失败: \(word.word) - \(message)")
            }
        } catch {
            print("❌ 错题记录同步到数据库失败: \(word.word) - \(error.localizedDescription)")
            print("❌ 错误详情: \(error)")
        }
    }
    
    private func syncMarkedWordToDatabase(_ word: WrongWord) async {
        print("🔍 syncMarkedWordToDatabase 开始: \(word.word)")
        print("🔍 databaseService 是否存在: \(databaseService != nil)")
        
        guard let databaseService = databaseService else { 
            print("❌ databaseService 为 nil，无法同步到数据库")
            return 
        }
        
        do {
            // 更新已标记为掌握的错题记录
            print("🔍 尝试更新记录: \(word.word)")
            try await databaseService.updateWrongWord(word)
            print("✅ 错题掌握状态同步到数据库成功: \(word.word)")
        } catch {
            print("❌ 错题掌握状态同步到数据库失败: \(word.word) - \(error.localizedDescription)")
            print("❌ 错误详情: \(error)")
        }
    }
    
    private func deleteWrongWordFromDatabase(_ word: WrongWord) async {
        guard let databaseService = databaseService else { return }
        
        do {
            try await databaseService.deleteWrongWord(word)
            print("✅ 错题记录从数据库删除成功: \(word.word)")
        } catch {
            print("❌ 错题记录从数据库删除失败: \(word.word) - \(error.localizedDescription)")
        }
    }
    
    private func syncWithDatabase() async {
        guard let databaseService = databaseService else { return }
        
        do {
            // 从数据库获取错题记录
            let databaseWords = try await databaseService.fetchUserWrongWords()
            
            // 合并本地和数据库数据
            await MainActor.run {
                // 以数据库数据为准，更新本地数据
                self.wrongWords = databaseWords
                self.updateTodayReviewWords()
                self.saveWrongWords()
            }
            
            print("✅ 错题记录从数据库同步成功: \(databaseWords.count) 个记录")
        } catch {
            print("❌ 错题记录从数据库同步失败: \(error.localizedDescription)")
            
            // 如果同步失败，尝试将本地数据上传到数据库
            do {
                try await databaseService.syncWrongWords(wrongWords)
                print("✅ 本地错题记录上传到数据库成功")
            } catch {
                print("❌ 本地错题记录上传到数据库失败: \(error.localizedDescription)")
            }
        }
    }
    
    
    func markAsMastered(_ word: WrongWord, syncToDatabase: Bool = true) {
        if let index = wrongWords.firstIndex(where: { $0.id == word.id }) {
            wrongWords[index].isMastered = true
            saveWrongWords()
            updateTodayReviewWords()
            
            // 可选同步到数据库
            if syncToDatabase {
                Task {
                    await syncMarkedWordToDatabase(wrongWords[index])
                }
            }
        }
    }
    
    func unmarkAsMastered(_ word: WrongWord, syncToDatabase: Bool = true) {
        if let index = wrongWords.firstIndex(where: { $0.id == word.id }) {
            wrongWords[index].isMastered = false
            // 重置复习状态，让用户可以重新学习
            wrongWords[index].reviewCount = 0
            wrongWords[index].consecutiveCorrect = 0
            wrongWords[index].lastReviewDate = Date()
            wrongWords[index].nextReviewDate = Date()
            saveWrongWords()
            updateTodayReviewWords()
            
            // 可选同步到数据库
            if syncToDatabase {
                Task {
                    await syncMarkedWordToDatabase(wrongWords[index])
                }
            }
        }
    }
    
    // MARK: - 复习管理
    func updateTodayReviewWords() {
        // 从所有教材中收集需要复习的单词
        var allWords: [WrongWord] = []
        for textbookWords in textbookWrongWords.values {
            allWords.append(contentsOf: textbookWords.words)
        }
        
        todayReviewWords = allWords.filter { word in
            !word.isMastered && EbbinghausCurve.shouldReviewToday(word: word)
        }.sorted { $0.nextReviewDate < $1.nextReviewDate }
    }
    
    func markAsReviewed(_ word: WrongWord) {
        // 在所有教材中查找该单词
        for (key, textbookWords) in textbookWrongWords {
            if let index = textbookWords.words.firstIndex(where: { $0.id == word.id }) {
                textbookWrongWords[key]?.words[index].reviewCount += 1
                textbookWrongWords[key]?.words[index].reviewDates.append(Date())
                textbookWrongWords[key]?.words[index].totalAttempts += 1
                textbookWrongWords[key]?.words[index].lastReviewDate = Date()
                let reviewCount = textbookWrongWords[key]?.words[index].reviewCount ?? 0
                textbookWrongWords[key]?.words[index].nextReviewDate = EbbinghausCurve.getNextReviewDate(from: Date(), reviewCount: reviewCount)
                
                // 如果复习次数达到7次，标记为已掌握
                if (textbookWrongWords[key]?.words[index].reviewCount ?? 0) >= 7 {
                    textbookWrongWords[key]?.words[index].isMastered = true
                }
                
                saveWrongWords()
                updateTodayReviewWords()
                break // 找到单词后退出循环
            }
        }
    }
    
    // 新增：记录复习结果（答对/答错）
    func recordReviewResult(for word: WrongWord, isCorrect: Bool) {
        // 在所有教材中查找该单词
        for (key, textbookWords) in textbookWrongWords {
            if let index = textbookWords.words.firstIndex(where: { $0.id == word.id }) {
                if isCorrect {
                    // 答对了：增加复习次数，更新复习日期
                    textbookWrongWords[key]?.words[index].reviewCount += 1
                    textbookWrongWords[key]?.words[index].reviewDates.append(Date())
                    textbookWrongWords[key]?.words[index].totalAttempts += 1
                    textbookWrongWords[key]?.words[index].consecutiveCorrect += 1
                    textbookWrongWords[key]?.words[index].consecutiveWrong = 0
                    textbookWrongWords[key]?.words[index].lastReviewDate = Date()
                    let reviewCount = textbookWrongWords[key]?.words[index].reviewCount ?? 0
                    textbookWrongWords[key]?.words[index].nextReviewDate = EbbinghausCurve.getNextReviewDate(from: Date(), reviewCount: reviewCount)
                    
                    // 如果复习次数达到7次，标记为已掌握
                    if (textbookWrongWords[key]?.words[index].reviewCount ?? 0) >= 7 {
                        textbookWrongWords[key]?.words[index].isMastered = true
                    }
                } else {
                    // 答错了：只记录错误，不增加复习次数
                    textbookWrongWords[key]?.words[index].errorCount += 1
                    textbookWrongWords[key]?.words[index].totalAttempts += 1
                    textbookWrongWords[key]?.words[index].consecutiveWrong += 1
                    textbookWrongWords[key]?.words[index].consecutiveCorrect = 0
                    textbookWrongWords[key]?.words[index].lastReviewDate = Date()
                    
                    // 答错后需要更频繁复习
                    let reviewCount = max(0, (textbookWrongWords[key]?.words[index].reviewCount ?? 0) - 1)
                    textbookWrongWords[key]?.words[index].nextReviewDate = EbbinghausCurve.getNextReviewDate(from: Date(), reviewCount: reviewCount)
                }
                
                saveWrongWords()
                updateTodayReviewWords()
                break // 找到单词后退出循环
            }
        }
    }
    
    // 记录正确答案
    func recordCorrectAnswer(for word: WrongWord) {
        // 在所有教材中查找该单词
        for (key, textbookWords) in textbookWrongWords {
            if let index = textbookWords.words.firstIndex(where: { $0.id == word.id }) {
                // 增加复习次数和统计
                textbookWrongWords[key]?.words[index].reviewCount += 1
                textbookWrongWords[key]?.words[index].reviewDates.append(Date())
                textbookWrongWords[key]?.words[index].totalAttempts += 1
                textbookWrongWords[key]?.words[index].consecutiveCorrect += 1
                textbookWrongWords[key]?.words[index].consecutiveWrong = 0
                textbookWrongWords[key]?.words[index].lastReviewDate = Date()
                let reviewCount = textbookWrongWords[key]?.words[index].reviewCount ?? 0
                textbookWrongWords[key]?.words[index].nextReviewDate = EbbinghausCurve.getNextReviewDate(from: Date(), reviewCount: reviewCount)
                
                // 如果连续答对3次，减少错误次数
                if (textbookWrongWords[key]?.words[index].consecutiveCorrect ?? 0) >= 3 {
                    let currentErrorCount = textbookWrongWords[key]?.words[index].errorCount ?? 0
                    textbookWrongWords[key]?.words[index].errorCount = max(0, currentErrorCount - 1)
                }
                
                // 如果复习次数达到7次，标记为已掌握
                if (textbookWrongWords[key]?.words[index].reviewCount ?? 0) >= 7 {
                    textbookWrongWords[key]?.words[index].isMastered = true
                }
                
                saveWrongWords()
                updateTodayReviewWords()
                break // 找到单词后退出循环
            }
        }
    }
    
    // 记录错误答案
    func recordIncorrectAnswer(for word: WrongWord) {
        // 在所有教材中查找该单词
        for (key, textbookWords) in textbookWrongWords {
            if let index = textbookWords.words.firstIndex(where: { $0.id == word.id }) {
                textbookWrongWords[key]?.words[index].errorCount += 1
                textbookWrongWords[key]?.words[index].totalAttempts += 1
                textbookWrongWords[key]?.words[index].consecutiveWrong += 1
                textbookWrongWords[key]?.words[index].consecutiveCorrect = 0
                textbookWrongWords[key]?.words[index].lastReviewDate = Date()
                
                // 答错后需要更频繁复习，重新计算下次复习日期
                let reviewCount = max(0, (textbookWrongWords[key]?.words[index].reviewCount ?? 0) - 1)
                textbookWrongWords[key]?.words[index].nextReviewDate = EbbinghausCurve.getNextReviewDate(from: Date(), reviewCount: reviewCount)
                
                saveWrongWords()
                updateTodayReviewWords()
                break // 找到单词后退出循环
            }
        }
    }
    
    // MARK: - 新增功能：筛选和搜索
    private func getFilteredWords() -> [WrongWord] {
        var filtered = wrongWords
        
        // 文本搜索
        if !searchText.isEmpty {
            filtered = filtered.filter { word in
                word.word.localizedCaseInsensitiveContains(searchText) ||
                word.meaning.localizedCaseInsensitiveContains(searchText) ||
                word.context.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 高级筛选
        if !selectedTextbookSources.isEmpty {
            filtered = filtered.filter { word in
                word.textbookSource != nil && selectedTextbookSources.contains(word.textbookSource!)
            }
        }
        
        if !selectedPartOfSpeech.isEmpty {
            filtered = filtered.filter { word in
                word.partOfSpeech != nil && selectedPartOfSpeech.contains(word.partOfSpeech!)
            }
        }
        
        if !selectedExamSources.isEmpty {
            filtered = filtered.filter { word in
                word.examSource != nil && selectedExamSources.contains(word.examSource!)
            }
        }
        
        if !selectedDifficulties.isEmpty {
            filtered = filtered.filter { word in
                selectedDifficulties.contains(word.difficulty)
            }
        }
        
        if !selectedLearningDirections.isEmpty {
            filtered = filtered.filter { word in
                selectedLearningDirections.contains(word.learningDirection)
            }
        }
        
        if !selectedMasteryLevels.isEmpty {
            filtered = filtered.filter { word in
                selectedMasteryLevels.contains(word.masteryLevel)
            }
        }
        
        return filtered
    }
    
    private func getSortedWords(_ words: [WrongWord]) -> [WrongWord] {
        switch selectedSortOption {
        case .byDate:
            return words.sorted { $0.id.uuidString > $1.id.uuidString } // 使用 ID 排序替代 dateAdded
        case .byErrorCount:
            return words.sorted { $0.errorCount > $1.errorCount }
        case .byReviewCount:
            return words.sorted { $0.reviewCount > $1.reviewCount }
        case .byLastReview:
            return words.sorted { ($0.lastReviewDate ?? Date.distantPast) > ($1.lastReviewDate ?? Date.distantPast) }
        case .byDifficulty:
            return words.sorted { $0.difficulty.rawValue > $1.difficulty.rawValue }
        case .alphabetical:
            return words.sorted { $0.word.lowercased() < $1.word.lowercased() }
        case .byUrgency:
            return words.sorted { $0.nextReviewDate < $1.nextReviewDate }
        }
    }
    
    // 重置所有筛选器
    func resetAllFilters() {
        selectedTextbookSources.removeAll()
        selectedPartOfSpeech.removeAll()
        selectedExamSources.removeAll()
        selectedDifficulties.removeAll()
        selectedLearningDirections.removeAll()
        selectedMasteryLevels.removeAll()
        searchText = ""
    }
    
    // 获取分组统计信息
    func getGroupStats() -> [String: Int] {
        var stats: [String: Int] = [:]
        
        for (groupName, words) in groupedWords {
            stats[groupName] = words.count
        }
        
        return stats
    }
    
    // 获取紧急复习单词
    func getUrgentWords() -> [WrongWord] {
        return wrongWords.filter { word in
            !word.isMastered && word.nextReviewDate < Date()
        }.sorted { $0.nextReviewDate < $1.nextReviewDate }
    }
    
    // 获取已掌握的单词列表
    func getMasteredWords() -> [WrongWord] {
        return wrongWords.filter { $0.isMastered }.sorted { $0.word < $1.word }
    }
    
    // 检查单词是否已掌握
    func isWordMastered(_ word: String) -> Bool {
        return wrongWords.contains { $0.word.lowercased() == word.lowercased() && $0.isMastered }
    }
    
    // 获取按难度分组的单词
    func getWordsByDifficulty(_ difficulty: WordDifficulty) -> [WrongWord] {
        return wrongWords.filter { $0.difficulty == difficulty }
    }
    
    // 获取按词性分组的单词
    func getWordsByPartOfSpeech(_ partOfSpeech: PartOfSpeech) -> [WrongWord] {
        return wrongWords.filter { $0.partOfSpeech == partOfSpeech }
    }
    
    // 获取按考试来源分组的单词
    func getWordsByExamSource(_ examSource: ExamSource) -> [WrongWord] {
        return wrongWords.filter { $0.examSource == examSource }
    }
    
    // 获取按教材来源分组的单词
    func getWordsByTextbookSource(_ source: TextbookSource) -> [WrongWord] {
        return wrongWords.filter { $0.textbookSource == source }
    }
    
    // MARK: - 统计信息
    var totalWords: Int {
        wrongWords.count
    }
    
    var masteredWords: Int {
        wrongWords.filter { $0.isMastered }.count
    }
    
    var pendingReviewWords: Int {
        todayReviewWords.count
    }
    
    var masteryRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(masteredWords) / Double(totalWords)
    }
    
    // MARK: - 分类统计
    func getWordsByLearningDirection(_ direction: LearningDirection) -> [WrongWord] {
        return wrongWords.filter { $0.learningDirection == direction }
    }
    
    func getWordsByGrade(_ grade: Grade) -> [WrongWord] {
        // 这里可以根据年级筛选，暂时返回所有
        return wrongWords
    }
    
    // MARK: - 搜索功能
    func searchWords(_ query: String) -> [WrongWord] {
        guard !query.isEmpty else { return wrongWords }
        return wrongWords.filter { word in
            word.word.localizedCaseInsensitiveContains(query) ||
            word.meaning.localizedCaseInsensitiveContains(query) ||
            word.context.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - 导入导出
    func exportWrongWords() -> String {
        let csv = wrongWords.map { word in
            "\(word.word),\(word.meaning),\(word.learningDirection.rawValue),\(word.id.uuidString),\(word.reviewCount),\(word.isMastered)"
        }.joined(separator: "\n")
        return "Word,Meaning,LearningDirection,DateAdded,ReviewCount,IsMastered\n" + csv
    }
    
    func importWrongWords(from csv: String) {
        let lines = csv.components(separatedBy: "\n")
        guard lines.count > 1 else { return }
        
        for line in lines.dropFirst() {
            let components = line.components(separatedBy: ",")
            guard components.count >= 4 else { continue }
            
                        let word = components[0]
            let meaning = components[1]
            let learningDirectionString = components[2]
            let context = components.count > 3 ? components[3] : ""
            
            let learningDirection = LearningDirection(rawValue: learningDirectionString) ?? .recognizeMeaning
            
            let wrongWord = WrongWord(
                word: word,
                meaning: meaning, 
                context: context, 
                learningDirection: learningDirection
            )
            addWrongWord(wrongWord)
        }
    }
    
    // MARK: - 清除模拟数据，使用真实Excel数据
    private func addSimulatedData() {
        // 不再生成模拟数据，所有数据都来自Excel文件或用户实际学习
        print("模拟数据已清除，系统将使用Excel文件中的真实数据")
    }
    
    // 清除模拟数据的方法（用于重置）
    func clearAllData() {
        wrongWords.removeAll()
        saveWrongWords()
        updateTodayReviewWords()
    }
    
    // 重新生成模拟数据
    func regenerateSimulatedData() {
        clearAllData()
        addSimulatedData()
        updateTodayReviewWords()
    }
    
    // MARK: - 多选功能
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedWords.removeAll()
        }
    }
    
    func toggleWordSelection(_ wordId: UUID) {
        if selectedWords.contains(wordId) {
            selectedWords.remove(wordId)
        } else {
            selectedWords.insert(wordId)
        }
    }
    
    func selectAllWords() {
        selectedWords = Set(wrongWords.map { $0.id })
    }
    
    func deselectAllWords() {
        selectedWords.removeAll()
    }
    
    func deleteSelectedWords() {
        let wordsToDelete = wrongWords.filter { selectedWords.contains($0.id) }
        for word in wordsToDelete {
            removeWrongWord(word)
        }
        selectedWords.removeAll()
    }
    
    func markSelectedWordsAsMastered() {
        let wordsToMark = wrongWords.filter { selectedWords.contains($0.id) }
        for word in wordsToMark {
            markAsMastered(word)
        }
        selectedWords.removeAll()
    }
    
    var hasSelectedWords: Bool {
        !selectedWords.isEmpty
    }
    
    var selectedWordsCount: Int {
        selectedWords.count
    }
}

// MARK: - 错题本视图模型
class WrongWordViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var showingAddWord = false
    @Published var showingReview = false
    
    private let manager: WrongWordManager
    
    init(manager: WrongWordManager) {
        self.manager = manager
    }
    
    var filteredWords: [WrongWord] {
        var words = manager.wrongWords
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            words = words.filter { word in
                word.word.localizedCaseInsensitiveContains(searchText) ||
                word.meaning.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return words.sorted { $0.id.uuidString > $1.id.uuidString } // 使用 ID 排序替代 dateAdded
    }
    
    var todayReviewWords: [WrongWord] {
        manager.todayReviewWords
    }
    
    func addWrongWord(_ word: WrongWord) {
        manager.addWrongWord(word)
    }
    
    func markAsReviewed(_ word: WrongWord) {
        manager.markAsReviewed(word)
    }
    
    func markAsMastered(_ word: WrongWord) {
        manager.markAsMastered(word)
    }
    
    func removeWrongWord(_ word: WrongWord) {
        manager.removeWrongWord(word)
    }
}

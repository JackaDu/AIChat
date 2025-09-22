//
//  Models.swift
//  AIChat
//
//  Created by Hao Du on 8/31/25.
//
import Foundation
import SwiftUI

enum Role: String, Codable { case user, assistant, system }

// MARK: - 单元进度统计
struct UnitProgress {
    let unit: Unit
    let totalWords: Int      // 该单元总单词数
    let masteredWords: Int   // 已掌握单词数
    let wrongWords: Int      // 错词数
    let remainingWords: Int  // 剩余单词数
    
    var completionRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(masteredWords) / Double(totalWords)
    }
    
    var displayName: String {
        return unit.displayName
    }
    
    var emoji: String {
        return unit.emoji
    }
}

// MARK: - 导入的单词数据结构
struct ImportedWord: Identifiable, Codable {
    let id = UUID()
    let english: String
    let chinese: String
    let example: String?
    let grade: Grade
    let difficulty: String
    let category: VocabularyType
    let textbookVersion: TextbookVersion
    let courseType: CourseType
    let course: String
    let imageURL: String?
    let etymology: String?
    let memoryTip: String?
    let relatedWords: [String]?
    let misleadingEnglishOptions: [String]
    let misleadingChineseOptions: [String]
}

// MARK: - 教材版本枚举
enum TextbookVersion: String, CaseIterable, Codable {
    case renjiao = "人教版"
    case beishida = "北师大版"
    case waiyan = "外研版"
    
    var englishName: String {
        switch self {
        case .renjiao: return "People's Education Press"
        case .beishida: return "Beijing Normal University Press"
        case .waiyan: return "Foreign Language Teaching and Research Press"
        }
    }
    
    var emoji: String {
        switch self {
        case .renjiao: return "📚"
        case .beishida: return "🎓"
        case .waiyan: return "🌍"
        }
    }
}

// MARK: - 必修选修枚举
enum CourseType: String, CaseIterable, Codable {
    case required = "必修"
    case elective = "选修"
    
    var englishName: String {
        switch self {
        case .required: return "Required"
        case .elective: return "Elective"
        }
    }
    
    var emoji: String {
        switch self {
        case .required: return "📖"
        case .elective: return "📚"
        }
    }
}

// MARK: - 必修课程枚举
enum RequiredCourse: String, CaseIterable, Codable {
    case book1 = "必修1"
    case book2 = "必修2"
    case book3 = "必修3"
    
    var englishName: String {
        switch self {
        case .book1: return "Required Book 1"
        case .book2: return "Required Book 2"
        case .book3: return "Required Book 3"
        }
    }
    
    var emoji: String {
        switch self {
        case .book1: return "1️⃣"
        case .book2: return "2️⃣"
        case .book3: return "3️⃣"
        }
    }
}

// MARK: - 选修课程枚举
enum ElectiveCourse: String, CaseIterable, Codable {
    case book1 = "选修1"
    case book2 = "选修2"
    case book3 = "选修3"
    case book4 = "选修4"
    
    var englishName: String {
        switch self {
        case .book1: return "Elective Book 1"
        case .book2: return "Elective Book 2"
        case .book3: return "Elective Book 3"
        case .book4: return "Elective Book 4"
        }
    }
    
    var emoji: String {
        switch self {
        case .book1: return "1️⃣"
        case .book2: return "2️⃣"
        case .book3: return "3️⃣"
        case .book4: return "4️⃣"
        }
    }
}

// MARK: - 年级枚举
enum Grade: String, CaseIterable, Codable {
    case high1 = "高一"
    case high2 = "高二"
    case high3 = "高三"
    
    var displayName: String { rawValue }
    
    var englishName: String {
        switch self {
        case .high1: return "Grade 10"
        case .high2: return "Grade 11"
        case .high3: return "Grade 12"
        }
    }
    
    var level: String {
        switch self {
        case .high1: return "intermediate"
        case .high2: return "advanced"
        case .high3: return "expert"
        }
    }
}

// MARK: - 词汇类型枚举
enum VocabularyType: String, CaseIterable, Codable {
    case daily = "日常生活"
    case academic = "学术学习"
    case travel = "旅游出行"
    case business = "商务职场"
    case entertainment = "娱乐休闲"
    case sports = "体育运动"
    case food = "美食餐饮"
    case technology = "科技数码"
    
    var englishName: String {
        switch self {
        case .daily: return "Daily Life"
        case .academic: return "Academic Study"
        case .travel: return "Travel"
        case .business: return "Business"
        case .entertainment: return "Entertainment"
        case .sports: return "Sports"
        case .food: return "Food & Dining"
        case .technology: return "Technology"
        }
    }
    
    var emoji: String {
        switch self {
        case .daily: return "🏠"
        case .academic: return "📚"
        case .travel: return "✈️"
        case .business: return "💼"
        case .entertainment: return "🎬"
        case .sports: return "⚽"
        case .food: return "🍕"
        case .technology: return "💻"
        }
    }
}

// MARK: - 单元枚举
enum Unit: Int, CaseIterable, Codable {
    case unit1 = 1, unit2 = 2, unit3 = 3, unit4 = 4, unit5 = 5, unit6 = 6
    
    var displayName: String {
        return "第\(rawValue)单元"
    }
    
    var shortName: String {
        return "Unit \(rawValue)"
    }
    
    var emoji: String {
        switch rawValue {
        case 1: return "1️⃣"
        case 2: return "2️⃣"
        case 3: return "3️⃣"
        case 4: return "4️⃣"
        case 5: return "5️⃣"
        case 6: return "6️⃣"
        default: return "📖"
        }
    }
    
    // 根据教材和课程获取可用单元
    static func availableUnits(for courseType: CourseType, course: String) -> [Unit] {
        switch (courseType, course) {
        case (.required, "必修1"):
            return [.unit1, .unit2, .unit3, .unit4, .unit5, .unit6] // 6个单元
        case (.required, "必修2"), (.required, "必修3"):
            return [.unit1, .unit2, .unit3, .unit4, .unit5] // 5个单元
        case (.elective, _):
            return [.unit1, .unit2, .unit3, .unit4, .unit5] // 选修课程都是5个单元
        default:
            return [.unit1, .unit2, .unit3, .unit4, .unit5] // 默认5个单元
        }
    }
}

// MARK: - 每日学习量选项
enum DailyStudyAmount: Int, CaseIterable, Codable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case twenty = 20
    
    var displayName: String {
        switch self {
        case .five: return "5个单词"
        case .ten: return "10个单词"
        case .fifteen: return "15个单词"
        case .twenty: return "20个单词"
        }
    }
    
    var description: String {
        switch self {
        case .five: return "轻松入门，适合初学者"
        case .ten: return "推荐选择，科学有效"
        case .fifteen: return "进阶提升，稳步前进"
        case .twenty: return "挑战自我，快速成长"
        }
    }
    
    var emoji: String {
        switch self {
        case .five: return "🌱"
        case .ten: return "⭐"
        case .fifteen: return "🚀"
        case .twenty: return "💪"
        }
    }
    
    var color: Color {
        switch self {
        case .five: return .green
        case .ten: return .blue
        case .fifteen: return .orange
        case .twenty: return .purple
        }
    }
}

// MARK: - 发音类型选项
enum PronunciationType: String, CaseIterable, Codable {
    case american = "american"
    case british = "british"
    
    var displayName: String {
        switch self {
        case .american: return "美式发音"
        case .british: return "英式发音"
        }
    }
    
    var englishName: String {
        switch self {
        case .american: return "American"
        case .british: return "British"
        }
    }
    
    var emoji: String {
        switch self {
        case .american: return "🇺🇸"
        case .british: return "🇬🇧"
        }
    }
    
    var description: String {
        switch self {
        case .american: return "标准美式英语发音"
        case .british: return "标准英式英语发音"
        }
    }
    
    var color: Color {
        switch self {
        case .american: return .red
        case .british: return .blue
        }
    }
}

// MARK: - 听写模式语音播报模式
enum DictationVoiceMode: String, CaseIterable, Codable {
    case english = "播报英文"
    case chinese = "播报中文"
    case none = "无声音"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .english:
            return "speaker.wave.2.fill"
        case .chinese:
            return "speaker.wave.1.fill"
        case .none:
            return "speaker.slash.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .english:
            return .blue
        case .chinese:
            return .green
        case .none:
            return .gray
        }
    }
}

// MARK: - 家长听写语言模式
enum ParentDictationLanguage: String, CaseIterable, Codable {
    case english = "english"           // 只播放英文
    case chinese = "chinese"           // 只播放中文
    case both = "both"                 // 英文和中文都播放
    
    var displayName: String {
        switch self {
        case .english:
            return "只播放英文"
        case .chinese:
            return "只播放中文"
        case .both:
            return "英文+中文"
        }
    }
    
    var description: String {
        switch self {
        case .english:
            return "只播放英文单词发音"
        case .chinese:
            return "只播放中文意思"
        case .both:
            return "先播放英文，再播放中文"
        }
    }
    
    var icon: String {
        switch self {
        case .english:
            return "speaker.wave.2.fill"
        case .chinese:
            return "speaker.wave.1.fill"
        case .both:
            return "speaker.wave.3.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .english:
            return .blue
        case .chinese:
            return .green
        case .both:
            return .purple
        }
    }
}

// MARK: - 列表显示模式枚举
enum ListDisplayMode: String, CaseIterable, Codable {
    case hideChinese = "hideChinese"
    case hideEnglish = "hideEnglish"
    case showAll = "showAll"
    
    var displayName: String {
        switch self {
        case .hideChinese: return "遮住中文"
        case .hideEnglish: return "遮住英文"
        case .showAll: return "都显示"
        }
    }
    
    var emoji: String {
        switch self {
        case .hideChinese: return "🇨🇳"
        case .hideEnglish: return "🇺🇸"
        case .showAll: return "👁️"
        }
    }
    
    var description: String {
        switch self {
        case .hideChinese: return "只显示英文，隐藏中文含义"
        case .hideEnglish: return "只显示中文，隐藏英文单词"
        case .showAll: return "同时显示英文和中文"
        }
    }
}

// MARK: - 用户偏好
struct UserPreferences: Codable {
    var selectedGrade: Grade = .high1
    var selectedVocabularyType: VocabularyType = .daily
    var selectedTextbookVersion: TextbookVersion = .renjiao
    var selectedCourseType: CourseType = .required
    var selectedRequiredCourse: RequiredCourse = .book1
    var selectedElectiveCourse: ElectiveCourse = .book1
    var selectedUnits: Set<Unit> = [.unit1] // 默认选择第1单元，支持多选
    var isFirstLaunch: Bool = true
    var dailyStudyAmount: DailyStudyAmount = .ten // 默认10个单词
    var hasSelectedStudyAmount: Bool = false // 是否已选择过学习量
    var defaultLearningMode: LearningDirection = .recognizeMeaning // 默认学习模式：识记单词
    var isNightMode: Bool = false // 夜间模式开关
    var pronunciationType: PronunciationType = .american // 发音类型：默认美式发音
    var listDisplayMode: ListDisplayMode = .hideChinese // 列表显示模式：默认遮住中文
    var showImagesInList: Bool = true // 列表模式中是否显示图片：默认显示
    var dictationShowFeedback: Bool = false // 听写模式是否显示答对/答错反馈：默认不显示（快速模式）
    var dictationVoiceMode: DictationVoiceMode = .english // 听写模式语音播报：默认播报英文
    var dictationShowUnderlines: Bool = true // 听写模式是否显示下划线：默认显示
    
    // 家长听写模式设置
    var parentDictationLanguage: ParentDictationLanguage = .english // 家长听写语言模式：默认只播放英文
    
    // 用户个人资料信息
    var userNickname: String = "" // 用户昵称
    var userAvatar: String = "person.circle.fill" // 用户头像系统名称
    var userAvatarColor: String = "blue" // 用户头像颜色
    
    // 获取选中单元的显示文本
    var selectedUnitsDisplayText: String {
        if selectedUnits.isEmpty {
            return "未选择"
        } else if selectedUnits.count == 1 {
            return selectedUnits.first?.displayName ?? "未选择"
        } else {
            return "已选择\(selectedUnits.count)个单元"
        }
    }
}

// MARK: - 单词来源信息
struct TextbookSource: Codable, Hashable {
    let courseType: CourseType // 必修/选修
    let courseBook: String // 课本名称（如"必修1"、"选修2"）
    let unit: Unit // 单元
    let textbookVersion: TextbookVersion // 教材版本
    
    var displayText: String {
        return "\(courseBook) \(unit.displayName)"
    }
    
    var shortDisplayText: String {
        return "\(courseBook) U\(unit.rawValue)"
    }
    
    // 从用户偏好创建当前来源
    static func current(from preferences: UserPreferences) -> TextbookSource {
        let courseBook: String
        if preferences.selectedCourseType == .required {
            courseBook = preferences.selectedRequiredCourse.rawValue
        } else {
            courseBook = preferences.selectedElectiveCourse.rawValue
        }
        
        // 如果有多个选中的单元，取第一个作为默认
        let selectedUnit = preferences.selectedUnits.first ?? .unit1
        
        return TextbookSource(
            courseType: preferences.selectedCourseType,
            courseBook: courseBook,
            unit: selectedUnit,
            textbookVersion: preferences.selectedTextbookVersion
        )
    }
}

// MARK: - 错题本模型
struct WrongWord: Codable, Identifiable {
    var id = UUID()
    let word: String
    let meaning: String
    let context: String
    let learningDirection: LearningDirection // 学习方向字段
    // 移除 dateAdded，使用 Appwrite 的 $createdAt
    var reviewDates: [Date]
    var nextReviewDate: Date
    var reviewCount: Int
    var isMastered: Bool
    var errorCount: Int // 记录错误次数
    var totalAttempts: Int // 记录总尝试次数
    
    // 新增分组字段
    var textbookSource: TextbookSource? // 单词来源（教材课本和单元）
    var partOfSpeech: PartOfSpeech? // 词性
    var examSource: ExamSource? // 考试来源
    var difficulty: WordDifficulty // 难度等级
    
    // 新增统计字段
    var lastReviewDate: Date? // 最近复习日期
    var consecutiveCorrect: Int // 连续答对次数
    var consecutiveWrong: Int // 连续答错次数
    
    // 新增图片和记忆辅助字段
    var imageURL: String? // 单词相关图片URL
    var etymology: String? // 词源信息
    var memoryTip: String? // 记忆技巧
    var relatedWords: [String]? // 相关单词
    
    // 数据库中的预生成误导选项
    var misleadingChineseOptions: [String] = []
    var misleadingEnglishOptions: [String] = []
    
    init(word: String, meaning: String, context: String = "", learningDirection: LearningDirection, 
         textbookSource: TextbookSource? = nil, partOfSpeech: PartOfSpeech? = nil, examSource: ExamSource? = nil, 
         difficulty: WordDifficulty = .medium) {
        self.word = word
        self.meaning = meaning
        self.context = context
        self.learningDirection = learningDirection
        // 移除 dateAdded 初始化，使用 Appwrite 的 $createdAt
        self.reviewDates = []
        self.nextReviewDate = Date()
        self.reviewCount = 0
        self.isMastered = false
        self.errorCount = 1 // 初始错误次数为1（因为被加入错题本）
        self.totalAttempts = 1 // 初始尝试次数为1
        
        // 新增字段初始化
        self.textbookSource = textbookSource
        self.partOfSpeech = partOfSpeech
        self.examSource = examSource
        self.difficulty = difficulty
        self.lastReviewDate = nil
        self.consecutiveCorrect = 0
        self.consecutiveWrong = 1 // 初始连续答错次数为1
        
        // 新增字段初始化
        self.imageURL = nil
        self.etymology = nil
        self.memoryTip = nil
        self.relatedWords = nil
    }
    
    // 计算错误率
    var errorRate: Double {
        guard totalAttempts > 0 else { return 0.0 }
        return Double(errorCount) / Double(totalAttempts) * 100
    }
    
    // 计算正确率
    var correctRate: Double {
        guard totalAttempts > 0 else { return 0.0 }
        let correctCount = totalAttempts - errorCount
        return Double(correctCount) / Double(totalAttempts) * 100
    }
    
    // 计算掌握程度显示
    var masteryLevel: String {
        if isMastered {
            return "已掌握"
        }
        
        return "\(Int(correctRate))%"
    }
    
    // 正确率颜色
    var masteryColor: Color {
        if isMastered {
            return .green
        }
        
        let rate = correctRate
        if rate >= 80 {
            return .green
        } else if rate >= 60 {
            return .yellow
        } else if rate >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    // 获取最近复习日期字符串
    var lastReviewDateString: String {
        guard let lastReview = lastReviewDate else { return "未复习" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: lastReview)
    }
    
    // 获取错误统计信息
    var errorStatsString: String {
        return "\(errorCount)/\(totalAttempts)"
    }
    
    // 获取分组显示名称
    var groupDisplayName: String {
        var groups: [String] = []
        
        if let source = textbookSource {
            groups.append("📚 \(source.displayText)")
        }
        
        if let pos = partOfSpeech {
            groups.append("\(pos.emoji) \(pos.displayName)")
        }
        
        if let source = examSource {
            groups.append("📝 \(source.displayName)")
        }
        
        return groups.isEmpty ? "未分组" : groups.joined(separator: " • ")
    }
}

// MARK: - 错误类型
enum ErrorType: String, CaseIterable, Codable {
    case spelling = "拼写错误"
    case meaning = "词义错误"
    case usage = "用法错误"
    case pronunciation = "发音错误"
    case grammar = "语法错误"
    
    var displayName: String { rawValue }
    
    var emoji: String {
        switch self {
        case .spelling: return "✏️"
        case .meaning: return "📖"
        case .usage: return "💬"
        case .pronunciation: return "🔊"
        case .grammar: return "📝"
        }
    }
}

// MARK: - 艾宾浩斯记忆曲线
struct EbbinghausCurve {
    static let reviewIntervals: [Int] = [1, 2, 4, 7, 15, 30, 60] // 天数
    
    static func getNextReviewDate(from date: Date, reviewCount: Int) -> Date {
        let calendar = Calendar.current
        let interval = reviewCount < reviewIntervals.count ? reviewIntervals[reviewCount] : 60
        return calendar.date(byAdding: .day, value: interval, to: date) ?? date
    }
    
    static func shouldReviewToday(word: WrongWord) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(word.nextReviewDate) || word.nextReviewDate < Date()
    }
}

// MARK - 学习方向枚举（记忆模式）
enum LearningDirection: String, CaseIterable, Codable {
    case recognizeMeaning = "看英文回忆中文"      // 看到英文单词，回忆中文意思
    case recallWord = "看中文回忆英文"          // 看到中文意思，回忆英文单词
    case dictation = "听写模式"                // 听中文意思，拼写英文单词
    
    var displayName: String {
        switch self {
        case .recognizeMeaning: return "看英文回忆中文"
        case .recallWord: return "看中文回忆英文"
        case .dictation: return "听写模式"
        }
    }
    
    var englishName: String {
        switch self {
        case .recognizeMeaning: return "English to Chinese"
        case .recallWord: return "Chinese to English"
        case .dictation: return "Dictation Mode"
        }
    }
    
    var emoji: String {
        switch self {
        case .recognizeMeaning: return "👀"
        case .recallWord: return "💭"
        case .dictation: return "✍️"
        }
    }
    
    var description: String {
        switch self {
        case .recognizeMeaning: return "看到英文单词，选择中文含义"
        case .recallWord: return "看到中文含义，回忆英文单词"
        case .dictation: return "听中文含义，拼写英文单词"
        }
    }
    
    var detailedDescription: String {
        switch self {
        case .recognizeMeaning: return "测试你是否认识这个英文单词，从选项中选择正确的中文意思"
        case .recallWord: return "测试你是否能回忆起这个英文单词，从选项中选择正确的英文单词"
        case .dictation: return "听到中文含义和英文发音，拼写出正确的英文单词"
        }
    }
    
    // 为了兼容旧代码，保留原来的映射
    var legacyValue: String {
        switch self {
        case .recognizeMeaning: return "英译中"
        case .recallWord: return "中译英"
        case .dictation: return "听写"
        }
    }
    
    // 从旧值创建新枚举
    static func fromLegacyValue(_ value: String) -> LearningDirection {
        switch value {
        case "英译中": return .recognizeMeaning
        case "中译英": return .recallWord
        case "听写": return .dictation
        default: return .recognizeMeaning
        }
    }
}

// MARK: - 复习排序选项
enum ReviewSortOption: CaseIterable {
    case byUrgency      // 按紧急程度
    case alphabetical   // 按字母顺序
    case byDifficulty   // 按难度（复习次数）
    case byDate         // 按添加时间
}

// MARK: - 词性枚举
enum PartOfSpeech: String, CaseIterable, Codable {
    case noun = "名词"
    case verb = "动词"
    case adjective = "形容词"
    case adverb = "副词"
    case pronoun = "代词"
    case preposition = "介词"
    case conjunction = "连词"
    case interjection = "感叹词"
    
    var displayName: String { rawValue }
    
    var emoji: String {
        switch self {
        case .noun: return "📝"
        case .verb: return "🏃"
        case .adjective: return "🎨"
        case .adverb: return "⚡"
        case .pronoun: return "👤"
        case .preposition: return "🔗"
        case .conjunction: return "🔀"
        case .interjection: return "💭"
        }
    }
    
    var color: Color {
        switch self {
        case .noun: return .blue
        case .verb: return .green
        case .adjective: return .orange
        case .adverb: return .purple
        case .pronoun: return .pink
        case .preposition: return .brown
        case .conjunction: return .cyan
        case .interjection: return .yellow
        }
    }
    
    var englishName: String {
        switch self {
        case .noun: return "Noun"
        case .verb: return "Verb"
        case .adjective: return "Adjective"
        case .adverb: return "Adverb"
        case .pronoun: return "Pronoun"
        case .preposition: return "Preposition"
        case .conjunction: return "Conjunction"
        case .interjection: return "Interjection"
        }
    }
}

// MARK: - 考试来源枚举
enum ExamSource: String, CaseIterable, Codable {
    case gaokao = "高考"
    case cet4 = "四级"
    case cet6 = "六级"
    case ielts = "雅思"
    case toefl = "托福"
    case sat = "SAT"
    case gre = "GRE"
    case daily = "日常学习"
    case textbook = "教材"
    case other = "其他"
    
    var displayName: String { rawValue }
    
    var emoji: String {
        switch self {
        case .gaokao: return "🎯"
        case .cet4: return "4️⃣"
        case .cet6: return "6️⃣"
        case .ielts: return "🇬🇧"
        case .toefl: return "🇺🇸"
        case .sat: return "🎓"
        case .gre: return "📚"
        case .daily: return "📖"
        case .textbook: return "📗"
        case .other: return "📌"
        }
    }
    
    var englishName: String {
        switch self {
        case .gaokao: return "Gaokao"
        case .cet4: return "CET-4"
        case .cet6: return "CET-6"
        case .ielts: return "IELTS"
        case .toefl: return "TOEFL"
        case .sat: return "SAT"
        case .gre: return "GRE"
        case .daily: return "Daily Learning"
        case .textbook: return "Textbook"
        case .other: return "Other"
        }
    }
}

// MARK: - 单词难度枚举
enum WordDifficulty: String, CaseIterable, Codable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var displayName: String { rawValue }
    
    var emoji: String {
        switch self {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - 错题分组选项
enum WrongWordGroupOption: String, CaseIterable {
    case all = "全部"
    case textbookSource = "教材来源"
    case partOfSpeech = "词性"
    case examSource = "考试来源"
    case difficulty = "难度"
    case learningDirection = "学习方向"
    case mastery = "掌握程度"
}

// MARK: - 错题排序选项
enum WrongWordSortOption: String, CaseIterable {
    case byDate = "添加时间"
    case byErrorCount = "错误次数"
    case byReviewCount = "复习次数"
    case byLastReview = "最近复习"
    case byDifficulty = "难度等级"
    case alphabetical = "字母顺序"
    case byUrgency = "紧急程度"
    
    var displayName: String { rawValue }
    
    var emoji: String {
        switch self {
        case .byDate: return "📅"
        case .byErrorCount: return "❌"
        case .byReviewCount: return "🔄"
        case .byLastReview: return "⏰"
        case .byDifficulty: return "📊"
        case .alphabetical: return "🔤"
        case .byUrgency: return "🚨"
        }
    }
}

// MARK: - 单词视图模式
enum WordViewMode: String, CaseIterable, Codable {
    case list = "列表"
    case card = "卡片"
    
    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .card: return "rectangle.grid.2x2"
        }
    }
}

// MARK: - 学习模式
enum StudyMode: String, CaseIterable, Codable {
    case card = "卡片模式"
    case list = "列表模式"
    
    var icon: String {
        switch self {
        case .card: return "rectangle.stack"
        case .list: return "list.bullet.rectangle"
        }
    }
    
    var description: String {
        switch self {
        case .card: return "逐个学习单词"
        case .list: return "批量检测单词"
        }
    }
}




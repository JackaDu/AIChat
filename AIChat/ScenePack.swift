import SwiftUI

// MARK: - 基础类型
struct TargetWord: Codable, Hashable {
    let en: String
    let zh: String
}

enum SceneTheme: String, Codable, CaseIterable, Hashable {
    case sunset, ocean, forest

    var gradient: LinearGradient {
        switch self {
        case .sunset:
            return LinearGradient(colors: [Color.orange.opacity(0.6), Color.pink.opacity(0.6)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ocean:
            return LinearGradient(colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.6)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:
            return LinearGradient(colors: [Color.green.opacity(0.6), Color.mint.opacity(0.6)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - 场景包（已加入角色字段）
struct ScenePack: Identifiable, Codable, Hashable {
    var id: String { sceneId }

    let sceneId: String
    let title: String
    let emoji: String
    let level: String
    let goal: String
    let targetWords: [TargetWord]
    let targetGrammar: String
    let openingLine: String
    let openingZh: String?
    let hints: [String]
    let theme: SceneTheme

    // ✅ 角色扮演
    let userRole: String   // 学生扮演的角色（如 "Customer"）
    let aiRole: String     // AI 扮演的角色（如 "Cashier"）
}

// MARK: - 年级词汇库
struct GradeVocabulary {
    static func getWords(for grade: Grade, type: VocabularyType) -> [TargetWord] {
        switch grade {
        case .high1:
            return getHigh1Words(for: type)
        case .high2:
            return getHigh2Words(for: type)
        case .high3:
            return getHigh3Words(for: type)
        }
    }
    
    // 高一词汇
    private static func getHigh1Words(for type: VocabularyType) -> [TargetWord] {
        switch type {
        case .daily:
            return [
                .init(en: "accomplish", zh: "完成"),
                .init(en: "achieve", zh: "达到"),
                .init(en: "acquire", zh: "获得"),
                .init(en: "adapt", zh: "适应")
            ]
        case .academic:
            return [
                .init(en: "analyze", zh: "分析"),
                .init(en: "evaluate", zh: "评估"),
                .init(en: "synthesize", zh: "综合"),
                .init(en: "interpret", zh: "解释")
            ]
        default:
            return [
                .init(en: "accomplish", zh: "完成"),
                .init(en: "achieve", zh: "达到"),
                .init(en: "acquire", zh: "获得"),
                .init(en: "adapt", zh: "适应")
            ]
        }
    }
    
    // 高二词汇
    private static func getHigh2Words(for type: VocabularyType) -> [TargetWord] {
        switch type {
        case .daily:
            return [
                .init(en: "endeavor", zh: "努力"),
                .init(en: "persevere", zh: "坚持"),
                .init(en: "resilient", zh: "有韧性的"),
                .init(en: "determined", zh: "坚定的")
            ]
        case .academic:
            return [
                .init(en: "hypothesis", zh: "假设"),
                .init(en: "methodology", zh: "方法论"),
                .init(en: "paradigm", zh: "范式"),
                .init(en: "theoretical", zh: "理论的")
            ]
        default:
            return [
                .init(en: "endeavor", zh: "努力"),
                .init(en: "persevere", zh: "坚持"),
                .init(en: "resilient", zh: "有韧性的"),
                .init(en: "determined", zh: "坚定的")
            ]
        }
    }
    
    // 高三词汇
    private static func getHigh3Words(for type: VocabularyType) -> [TargetWord] {
        switch type {
        case .daily:
            return [
                .init(en: "sophisticated", zh: "复杂的"),
                .init(en: "profound", zh: "深刻的"),
                .init(en: "elaborate", zh: "精心制作的"),
                .init(en: "comprehensive", zh: "全面的")
            ]
        case .academic:
            return [
                .init(en: "empirical", zh: "经验的"),
                .init(en: "analytical", zh: "分析的"),
                .init(en: "critical", zh: "批判的"),
                .init(en: "innovative", zh: "创新的")
            ]
        default:
            return [
                .init(en: "sophisticated", zh: "复杂的"),
                .init(en: "profound", zh: "深刻的"),
                .init(en: "elaborate", zh: "精心制作的"),
                .init(en: "comprehensive", zh: "全面的")
            ]
        }
    }

    // 旅行词汇
    private static func getTravelWords(for grade: Grade) -> [TargetWord] {
        switch grade {
        case .high1:
            return [
                .init(en: "sophisticated", zh: "复杂的"),
                .init(en: "profound", zh: "深刻的"),
                .init(en: "elaborate", zh: "精心制作的"),
                .init(en: "comprehensive", zh: "全面的")
            ]
        case .high2:
            return [
                .init(en: "travel", zh: "旅行"),
                .init(en: "tour", zh: "旅游"),
                .init(en: "journey", zh: "旅程"),
                .init(en: "destination", zh: "目的地")
            ]
        case .high3:
            return [
                .init(en: "trip", zh: "旅行"),
                .init(en: "vacation", zh: "假期"),
                .init(en: "tour", zh: "旅游"),
                .init(en: "destination", zh: "目的地")
            ]
        }
    }
}

// MARK: - 动态场景包生成器
struct DynamicScenePackGenerator {
    static func generateScenes(for grade: Grade, vocabularyType: VocabularyType) -> [ScenePack] {
        let words = GradeVocabulary.getWords(for: grade, type: vocabularyType)
        
        switch vocabularyType {
        case .travel:
            return generateTravelScenes(grade: grade, level: grade.level, words: words)
        default:
            return generateDefaultScenes(grade: grade, level: grade.level, words: words)
        }
    }
    
    private static func generateDailyScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "daily_conversation_\(level)",
                title: "日常对话练习",
                emoji: "🏠",
                level: level,
                goal: "练习日常生活中的基本对话",
                targetWords: words,
                targetGrammar: "Present Simple",
                openingLine: "Hello! How are you today?",
                openingZh: "你好！今天怎么样？",
                hints: ["尝试使用学过的词汇进行对话"],
                theme: .sunset,
                userRole: "Student",
                aiRole: "Friend"
            )
        ]
    }
    
    private static func generateFoodScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "food_ordering_\(level)",
                title: "点餐对话练习",
                emoji: "🍕",
                level: level,
                goal: "练习在餐厅点餐的对话",
                targetWords: words,
                targetGrammar: "Would you like...",
                openingLine: "Welcome! What would you like to order today?",
                openingZh: "欢迎！今天想点什么呢？",
                hints: ["使用学过的食物相关词汇"],
                theme: .ocean,
                userRole: "Customer",
                aiRole: "Waiter"
            )
        ]
    }
    
    private static func generateAcademicScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "academic_discussion_\(level)",
                title: "学术讨论练习",
                emoji: "📚",
                level: level,
                goal: "练习学术讨论和表达观点",
                targetWords: words,
                targetGrammar: "I think that...",
                openingLine: "Let's discuss today's topic. What's your opinion?",
                openingZh: "让我们讨论今天的话题。你的观点是什么？",
                hints: ["使用学过的学术词汇表达观点"],
                theme: .forest,
                userRole: "Student",
                aiRole: "Teacher"
            )
        ]
    }
    
    private static func generateTravelScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "travel_planning_\(level)",
                title: "旅行规划练习",
                emoji: "✈️",
                level: level,
                goal: "练习旅行规划和询问信息",
                targetWords: words,
                targetGrammar: "Could you tell me...",
                openingLine: "Hello! I'm planning a trip. Can you help me?",
                openingZh: "你好！我在计划旅行。能帮帮我吗？",
                hints: ["使用学过的旅行相关词汇"],
                theme: .sunset,
                userRole: "Traveler",
                aiRole: "Travel Agent"
            )
        ]
    }
    
    private static func generateBusinessScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "business_meeting_\(level)",
                title: "商务会议练习",
                emoji: "💼",
                level: level,
                goal: "练习商务会议中的表达",
                targetWords: words,
                targetGrammar: "I suggest that...",
                openingLine: "Good morning everyone. Let's begin our meeting.",
                openingZh: "大家早上好。让我们开始会议。",
                hints: ["使用学过的商务词汇"],
                theme: .ocean,
                userRole: "Team Member",
                aiRole: "Manager"
            )
        ]
    }
    
    private static func generateEntertainmentScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "entertainment_discussion_\(level)",
                title: "娱乐话题讨论",
                emoji: "🎬",
                level: level,
                goal: "练习讨论娱乐话题",
                targetWords: words,
                targetGrammar: "What do you think about...",
                openingLine: "Have you seen any good movies lately?",
                openingZh: "最近看过什么好电影吗？",
                hints: ["使用学过的娱乐相关词汇"],
                theme: .forest,
                userRole: "Movie Fan",
                aiRole: "Friend"
            )
        ]
    }
    
    private static func generateSportsScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "sports_conversation_\(level)",
                title: "体育运动对话",
                emoji: "⚽",
                level: level,
                goal: "练习讨论体育运动",
                targetWords: words,
                targetGrammar: "I enjoy...",
                openingLine: "Do you like sports? What's your favorite?",
                openingZh: "你喜欢运动吗？你最喜欢什么？",
                hints: ["使用学过的运动相关词汇"],
                theme: .sunset,
                userRole: "Sports Fan",
                aiRole: "Coach"
            )
        ]
    }
    
    private static func generateTechnologyScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "technology_discussion_\(level)",
                title: "科技话题讨论",
                emoji: "💻",
                level: level,
                goal: "练习讨论科技话题",
                targetWords: words,
                targetGrammar: "Technology is...",
                openingLine: "What do you think about new technology?",
                openingZh: "你对新技术有什么看法？",
                hints: ["使用学过的科技相关词汇"],
                theme: .ocean,
                userRole: "Tech Enthusiast",
                aiRole: "Tech Expert"
            )
        ]
    }

    private static func generateDefaultScenes(grade: Grade, level: String, words: [TargetWord]) -> [ScenePack] {
        return [
            ScenePack(
                sceneId: "general_conversation_\(level)",
                title: "日常对话练习",
                emoji: "💬",
                level: level,
                goal: "练习日常英语对话",
                targetWords: words,
                targetGrammar: "How do you...",
                openingLine: "Hello! How are you today?",
                openingZh: "你好！今天怎么样？",
                hints: ["使用学过的词汇"],
                theme: .forest,
                userRole: "Student",
                aiRole: "Friend"
            )
        ]
    }
}

// MARK: - 示例数据（可按需修改/扩展）
extension ScenePack {
    static let cafeteria = ScenePack(
        sceneId: "cafeteria_lunch_L4",
        title: "Cafeteria: Ordering Lunch",
        emoji: "🥗",
        level: "L4",
        goal: "点一份素食午餐并索要收据",
        targetWords: [
            .init(en: "receipt", zh: "收据"),
            .init(en: "allergic", zh: "过敏的"),
            .init(en: "portion", zh: "分量"),
            .init(en: "vegetarian", zh: "素食者")
        ],
        targetGrammar: "Subjunctive: If I were ...",
        openingLine: "Hi there! What would you like for lunch today?",
        openingZh: "你好！今天午餐想吃点什么呢？",
        hints: ["尽量在一句话中同时使用 receipt 和 allergic。"],
        theme: .sunset,
        userRole: "Customer",
        aiRole: "Cashier"
    )

    static let library = ScenePack(
        sceneId: "library_book_L3",
        title: "Library: Borrow a Book",
        emoji: "📚",
        level: "L3",
        goal: "询问并借阅一本指定主题的书",
        targetWords: [
            .init(en: "borrow", zh: "借"),
            .init(en: "due date", zh: "归还日期"),
            .init(en: "recommendation", zh: "推荐")
        ],
        targetGrammar: "Polite requests: Could I… / May I…",
        openingLine: "Hello! How can I help you today?",
        openingZh: "你好！今天我能帮你什么？",
        hints: ["试着问 due date，再请求 recommendation。"],
        theme: .ocean,
        userRole: "Student",
        aiRole: "Librarian"
    )

    static let clinic = ScenePack(
        sceneId: "clinic_checkin_L3",
        title: "Clinic: Check-in & Symptoms",
        emoji: "🏥",
        level: "L3",
        goal: "描述症状并完成登记",
        targetWords: [
            .init(en: "symptom", zh: "症状"),
            .init(en: "appointment", zh: "预约"),
            .init(en: "pharmacy", zh: "药房")
        ],
        targetGrammar: "Present perfect: have/has + past participle",
        openingLine: "Good morning. Do you have an appointment?",
        openingZh: "早上好。你有预约吗？",
        hints: ["用 present perfect 描述近来状况，例如 I have had a fever for two days."],
        theme: .forest,
        userRole: "Patient",
        aiRole: "Nurse"
    )

    static let all: [ScenePack] = [.cafeteria, .library, .clinic]
}

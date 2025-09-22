import SwiftUI
import Foundation

// MARK: - 学习模式枚举
enum LearningModeType {
    case card       // 卡片模式（选择题）
    case list       // 列表模式（批量）
    case spelling   // 拼写模式（填空）
}

// MARK: - 触发器类型
enum NavigationTrigger {
    case user           // 用户主动切换
    case wrongAnswer    // 答题错误
    case sessionEnd     // 会话结束
}

// MARK: - 导航上下文
struct NavigationContext {
    let trigger: NavigationTrigger
    let sourceMode: LearningModeType?
    let targetMode: LearningModeType
    let wrongWords: [StudyWord]
    let sessionStats: SessionStats?
}

// MARK: - 会话统计
struct SessionStats {
    let totalWords: Int
    let correctCount: Int
    let wrongCount: Int
    let accuracy: Double
    let timeSpent: TimeInterval
}

// MARK: - 内嵌面板类型
enum EmbeddedPanelType {
    case none
    case spellingReinforcement  // 拼写强化面板
    case sessionComplete        // 会话结束面板
    case wordDetail            // 单词详情面板
}

// MARK: - 统一模式管理器
@MainActor
class UnifiedModeManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentMode: LearningModeType = .card
    @Published var showEmbeddedPanel: Bool = false
    @Published var embeddedPanelType: EmbeddedPanelType = .none
    @Published var navigationContext: NavigationContext?
    
    // MARK: - Private Properties
    private var wrongWordsInSession: [StudyWord] = []
    private var sessionStartTime: Date = Date()
    private var currentSessionStats: SessionStats?
    
    // MARK: - Core Navigation Methods
    
    /// 处理用户主动切换模式
    func handleUserModeSwitch(to targetMode: LearningModeType, from sourceMode: LearningModeType? = nil) {
        print("🔄 用户主动切换模式: \(sourceMode?.description ?? "nil") → \(targetMode.description)")
        
        let context = NavigationContext(
            trigger: .user,
            sourceMode: sourceMode,
            targetMode: targetMode,
            wrongWords: [],
            sessionStats: nil
        )
        
        navigationContext = context
        currentMode = targetMode
        hideEmbeddedPanel()
    }
    
    /// 处理答题错误触发
    func handleWrongAnswer(wrongWord: StudyWord, currentMode: LearningModeType) {
        print("❌ 答题错误触发: \(wrongWord.word) in \(currentMode.description)")
        
        // 记录错词
        wrongWordsInSession.append(wrongWord)
        
        // 显示拼写强化内嵌面板
        showSpellingReinforcementPanel(wrongWord: wrongWord, sourceMode: currentMode)
    }
    
    /// 处理会话结束触发
    func handleSessionEnd(stats: SessionStats, currentMode: LearningModeType) {
        print("🏁 会话结束触发: \(currentMode.description), 错词数: \(wrongWordsInSession.count)")
        
        currentSessionStats = stats
        
        let context = NavigationContext(
            trigger: .sessionEnd,
            sourceMode: currentMode,
            targetMode: currentMode, // 保持当前模式
            wrongWords: wrongWordsInSession,
            sessionStats: stats
        )
        
        navigationContext = context
        showSessionCompletePanel()
    }
    
    // MARK: - Embedded Panel Methods
    
    /// 显示拼写强化面板
    private func showSpellingReinforcementPanel(wrongWord: StudyWord, sourceMode: LearningModeType) {
        embeddedPanelType = .spellingReinforcement
        showEmbeddedPanel = true
    }
    
    /// 显示会话结束面板
    private func showSessionCompletePanel() {
        embeddedPanelType = .sessionComplete
        showEmbeddedPanel = true
    }
    
    /// 隐藏内嵌面板
    func hideEmbeddedPanel() {
        showEmbeddedPanel = false
        embeddedPanelType = .none
    }
    
    // MARK: - Panel Action Handlers
    
    /// 用户接受拼写强化
    func acceptSpellingReinforcement() {
        print("✅ 用户接受拼写强化")
        hideEmbeddedPanel()
        // 在当前上下文内弹出拼写输入面板
        // 这里会触发拼写模式的内嵌显示
    }
    
    /// 用户拒绝拼写强化
    func rejectSpellingReinforcement() {
        print("❌ 用户拒绝拼写强化")
        hideEmbeddedPanel()
        // 显示解析/下一题，不切模式
    }
    
    /// 用户选择练错题
    func practiceWrongWords() {
        print("📚 用户选择练错题")
        hideEmbeddedPanel()
        
        let context = NavigationContext(
            trigger: .sessionEnd,
            sourceMode: currentMode,
            targetMode: .spelling,
            wrongWords: wrongWordsInSession,
            sessionStats: currentSessionStats
        )
        
        navigationContext = context
        currentMode = .spelling
    }
    
    /// 用户选择回首页
    func returnToHome() {
        print("🏠 用户选择回首页")
        hideEmbeddedPanel()
        resetSession()
    }
    
    /// 用户选择再来一轮
    func startNewRound() {
        print("🔄 用户选择再来一轮")
        hideEmbeddedPanel()
        resetSession()
        // 保持当前模式，重新开始
    }
    
    // MARK: - Session Management
    
    /// 重置会话
    private func resetSession() {
        wrongWordsInSession.removeAll()
        sessionStartTime = Date()
        currentSessionStats = nil
        navigationContext = nil
    }
    
    /// 开始新会话
    func startNewSession(mode: LearningModeType) {
        resetSession()
        currentMode = mode
        sessionStartTime = Date()
    }
    
    /// 计算会话统计
    func calculateSessionStats(totalWords: Int, correctCount: Int) -> SessionStats {
        let wrongCount = totalWords - correctCount
        let accuracy = totalWords > 0 ? Double(correctCount) / Double(totalWords) : 0.0
        let timeSpent = Date().timeIntervalSince(sessionStartTime)
        
        return SessionStats(
            totalWords: totalWords,
            correctCount: correctCount,
            wrongCount: wrongCount,
            accuracy: accuracy,
            timeSpent: timeSpent
        )
    }
}

// MARK: - Extensions
extension LearningModeType {
    var description: String {
        switch self {
        case .card: return "卡片模式"
        case .list: return "列表模式"
        case .spelling: return "拼写模式"
        }
    }
    
    var icon: String {
        switch self {
        case .card: return "rectangle.on.rectangle"
        case .list: return "list.bullet"
        case .spelling: return "keyboard"
        }
    }
}

extension NavigationTrigger {
    var description: String {
        switch self {
        case .user: return "用户主动"
        case .wrongAnswer: return "答题错误"
        case .sessionEnd: return "会话结束"
        }
    }
}

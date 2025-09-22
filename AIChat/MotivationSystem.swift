import Foundation
import SwiftUI

// MARK: - 激励系统管理器
@MainActor
class MotivationSystem: ObservableObject {
    @Published var showingDailyFeedback = false
    @Published var showingReviewCompletion = false
    @Published var dailyFeedbackData: DailyFeedbackData?
    @Published var reviewCompletionData: ReviewCompletionData?
    
    // 连续使用统计
    @Published var consecutiveDays: Int = 0
    @Published var weeklyProgress: [Bool] = Array(repeating: false, count: 7)
    
    // 成就系统
    @Published var unlockedAchievements: [Achievement] = []
    @Published var showingAchievementUnlock = false
    @Published var newlyUnlockedAchievement: Achievement?
    
    // 成长点数系统
    @Published var growthPoints: Int = 0
    @Published var showingPointsGain = false
    @Published var pointsGained: Int = 0
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadMotivationData()
        checkDailyStreak()
    }
    
    // MARK: - 首页即时反馈
    func showDailyFeedback(wordsReviewed: Int, masteryImprovement: Double) {
        dailyFeedbackData = DailyFeedbackData(
            wordsReviewed: wordsReviewed,
            masteryImprovement: masteryImprovement,
            consecutiveDays: consecutiveDays
        )
        showingDailyFeedback = true
        
        // 增加成长点数
        let points = calculateDailyPoints(wordsReviewed: wordsReviewed, improvement: masteryImprovement)
        addGrowthPoints(points)
        
        // 检查成就解锁
        checkAchievementUnlock()
    }
    
    // MARK: - 复习完成激励
    func showReviewCompletion(
        totalWords: Int,
        correctAnswers: Int,
        masteryRate: Double,
        newWordsMastered: Int
    ) {
        reviewCompletionData = ReviewCompletionData(
            totalWords: totalWords,
            correctAnswers: correctAnswers,
            masteryRate: masteryRate,
            newWordsMastered: newWordsMastered
        )
        showingReviewCompletion = true
        
        // 计算并添加成长点数
        let points = calculateReviewPoints(
            totalWords: totalWords,
            correctAnswers: correctAnswers,
            masteryRate: masteryRate
        )
        addGrowthPoints(points)
        
        // 检查成就解锁
        checkAchievementUnlock()
    }
    
    // MARK: - 连续使用统计
    private func checkDailyStreak() {
        let today = Date()
        let lastLoginDate = userDefaults.object(forKey: "lastLoginDate") as? Date ?? Date.distantPast
        
        if Calendar.current.isDateInToday(lastLoginDate) {
            // 今天已经登录过
            return
        }
        
        if Calendar.current.isDateInYesterday(lastLoginDate) {
            // 昨天登录过，连续天数+1
            consecutiveDays += 1
        } else if Calendar.current.dateInterval(of: .day, for: lastLoginDate)?.end ?? Date() < today {
            // 超过一天没登录，重置连续天数
            consecutiveDays = 1
        }
        
        // 更新本周进度
        let weekday = Calendar.current.component(.weekday, from: today) - 1
        weeklyProgress[weekday] = true
        
        // 保存数据
        userDefaults.set(today, forKey: "lastLoginDate")
        userDefaults.set(consecutiveDays, forKey: "consecutiveDays")
        userDefaults.set(weeklyProgress, forKey: "weeklyProgress")
    }
    
    // MARK: - 成长点数系统
    private func addGrowthPoints(_ points: Int) {
        growthPoints += points
        pointsGained = points
        showingPointsGain = true
        
        userDefaults.set(growthPoints, forKey: "growthPoints")
    }
    
    private func calculateDailyPoints(wordsReviewed: Int, improvement: Double) -> Int {
        var points = wordsReviewed * 2 // 基础点数：每个单词2分
        
        if improvement > 0 {
            points += Int(improvement * 10) // 掌握率提升：每1%加10分
        }
        
        if consecutiveDays >= 7 {
            points += 50 // 连续7天奖励
        }
        
        return points
    }
    
    private func calculateReviewPoints(totalWords: Int, correctAnswers: Int, masteryRate: Double) -> Int {
        var points = correctAnswers * 3 // 答对每个单词3分
        
        if masteryRate >= 80 {
            points += 100 // 掌握率80%以上奖励
        } else if masteryRate >= 60 {
            points += 50 // 掌握率60%以上奖励
        }
        
        return points
    }
    
    // MARK: - 成就系统
    private func checkAchievementUnlock() {
        let newAchievements = Achievement.allCases.filter { achievement in
            !unlockedAchievements.contains(achievement) && achievement.isUnlocked(
                consecutiveDays: consecutiveDays,
                growthPoints: growthPoints,
                totalWords: 0 // 这里需要从WrongWordManager获取
            )
        }
        
        if let newAchievement = newAchievements.first {
            newlyUnlockedAchievement = newAchievement
            unlockedAchievements.append(newAchievement)
            showingAchievementUnlock = true
            
            // 保存成就数据
            let achievementIds = unlockedAchievements.map { $0.id }
            userDefaults.set(achievementIds, forKey: "unlockedAchievements")
        }
    }
    
    // MARK: - 数据持久化
    private func loadMotivationData() {
        consecutiveDays = userDefaults.integer(forKey: "consecutiveDays")
        growthPoints = userDefaults.integer(forKey: "growthPoints")
        
        if let progressData = userDefaults.array(forKey: "weeklyProgress") as? [Bool] {
            weeklyProgress = progressData
        }
        
        if let achievementIds = userDefaults.array(forKey: "unlockedAchievements") as? [String] {
            unlockedAchievements = Achievement.allCases.filter { achievement in
                achievementIds.contains(achievement.id)
            }
        }
    }
}

// MARK: - 数据模型
struct DailyFeedbackData {
    let wordsReviewed: Int
    let masteryImprovement: Double
    let consecutiveDays: Int
}

struct ReviewCompletionData {
    let totalWords: Int
    let correctAnswers: Int
    let masteryRate: Double
    let newWordsMastered: Int
}

// MARK: - 成就系统
enum Achievement: String, CaseIterable, Identifiable {
    case firstDay = "firstDay"
    case weekStreak = "weekStreak"
    case monthStreak = "monthStreak"
    case wordMaster = "wordMaster"
    case perfectReview = "perfectReview"
    case consistentLearner = "consistentLearner"
    case growthSeeker = "growthSeeker"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .firstDay: return "初来乍到"
        case .weekStreak: return "坚持一周"
        case .monthStreak: return "月度达人"
        case .wordMaster: return "单词大师"
        case .perfectReview: return "完美复习"
        case .consistentLearner: return "持之以恒"
        case .growthSeeker: return "成长探索者"
        }
    }
    
    var description: String {
        switch self {
        case .firstDay: return "完成第一次学习"
        case .weekStreak: return "连续学习7天"
        case .monthStreak: return "连续学习30天"
        case .wordMaster: return "掌握100个单词"
        case .perfectReview: return "单次复习100%正确"
        case .consistentLearner: return "连续学习50天"
        case .growthSeeker: return "获得1000成长点"
        }
    }
    
    var emoji: String {
        switch self {
        case .firstDay: return "🎯"
        case .weekStreak: return "🔥"
        case .monthStreak: return "🏆"
        case .wordMaster: return "👑"
        case .perfectReview: return "⭐"
        case .consistentLearner: return "💪"
        case .growthSeeker: return "🚀"
        }
    }
    
    var color: Color {
        switch self {
        case .firstDay: return .blue
        case .weekStreak: return .orange
        case .monthStreak: return .purple
        case .wordMaster: return .yellow
        case .perfectReview: return .green
        case .consistentLearner: return .red
        case .growthSeeker: return .pink
        }
    }
    
    func isUnlocked(consecutiveDays: Int, growthPoints: Int, totalWords: Int) -> Bool {
        switch self {
        case .firstDay: return true // 总是解锁
        case .weekStreak: return consecutiveDays >= 7
        case .monthStreak: return consecutiveDays >= 30
        case .wordMaster: return totalWords >= 100
        case .perfectReview: return false // 需要特殊触发
        case .consistentLearner: return consecutiveDays >= 50
        case .growthSeeker: return growthPoints >= 1000
        }
    }
}

// MARK: - 首页即时反馈弹窗
struct DailyFeedbackPopup: View {
    let data: DailyFeedbackData
    @Binding var isPresented: Bool
    @ObservedObject var motivationSystem: MotivationSystem
    
    @State private var animationProgress: Double = 0
    @State private var starsOpacity: Double = 0
    @State private var healthBarProgress: Double = 0
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }
            
            // 弹窗内容
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Text("🎉 今日成就")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("继续加油，每天进步一点点！")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // 统计数据
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        MotivationStatCard(
                            title: "复习单词",
                            value: "\(data.wordsReviewed)",
                            subtitle: "",
                            icon: "book.fill",
                            color: .blue
                        )
                        
                        MotivationStatCard(
                            title: "掌握率提升",
                            value: "+\(String(format: "%.1f", data.masteryImprovement))%",
                            subtitle: "",
                            icon: "arrow.up.circle.fill",
                            color: .green
                        )
                    }
                    
                    // 连续天数
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("连续学习 \(data.consecutiveDays) 天")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // 记忆健康度条
                VStack(spacing: 8) {
                    HStack {
                        Text("记忆健康度")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(healthBarProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * healthBarProgress, height: 8)
                                .animation(.easeOut(duration: 1.0), value: healthBarProgress)
                        }
                    }
                    .frame(height: 8)
                }
                
                // 星星奖励
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.title)
                            .foregroundStyle(.yellow)
                            .opacity(starsOpacity)
                            .scaleEffect(starsOpacity)
                            .animation(
                                .easeInOut(duration: 0.5)
                                .delay(Double(index) * 0.2),
                                value: starsOpacity
                            )
                    }
                }
                
                // 关闭按钮
                Button("太棒了！") {
                    dismissPopup()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .padding(.horizontal, 20)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 1.0)) {
            animationProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 1.0)) {
                healthBarProgress = min(1.0, 0.3 + data.masteryImprovement / 100)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                starsOpacity = 1.0
            }
        }
    }
    
    private func dismissPopup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - 统计卡片
struct MotivationStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 复习完成激励弹窗
struct ReviewCompletionPopup: View {
    let data: ReviewCompletionData
    @Binding var isPresented: Bool
    @ObservedObject var motivationSystem: MotivationSystem
    
    @State private var animationProgress: Double = 0
    @State private var numberAnimation: Double = 0
    @State private var curveAnimation: Double = 0
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }
            
            // 弹窗内容
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Text("🎯 复习完成")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("本次复习结果")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // 结果统计
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        MotivationStatCard(
                            title: "总单词",
                            value: "\(data.totalWords)",
                            subtitle: "",
                            icon: "list.bullet",
                            color: .blue
                        )
                        
                        MotivationStatCard(
                            title: "答对",
                            value: "\(data.correctAnswers)",
                            subtitle: "",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    
                    HStack(spacing: 20) {
                        MotivationStatCard(
                            title: "掌握率",
                            value: "\(Int(data.masteryRate))%",
                            subtitle: "",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .orange
                        )
                        
                        MotivationStatCard(
                            title: "新掌握",
                            value: "\(data.newWordsMastered)",
                            subtitle: "",
                            icon: "star.fill",
                            color: .purple
                        )
                    }
                }
                
                // 进度曲线
                VStack(spacing: 8) {
                    HStack {
                        Text("学习进度")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(curveAnimation * 100))%")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * curveAnimation, height: 8)
                                .animation(.easeOut(duration: 1.5), value: curveAnimation)
                        }
                    }
                    .frame(height: 8)
                }
                
                // 提示信息
                VStack(spacing: 8) {
                    if data.masteryRate >= 80 {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("太棒了！继续保持这个水平")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    } else if data.masteryRate >= 60 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("不错！错题已安排再次复习")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.blue)
                            Text("需要加强练习，错题已安排复习")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding()
                .background(.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 关闭按钮
                Button("继续学习") {
                    dismissPopup()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .padding(.horizontal, 20)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 1.0)) {
            animationProgress = 1.0
        }
        
        withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
            numberAnimation = 1.0
        }
        
        withAnimation(.easeOut(duration: 1.5).delay(0.6)) {
            curveAnimation = data.masteryRate / 100
        }
    }
    
    private func dismissPopup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - 成就解锁弹窗
struct AchievementUnlockPopup: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    
    @State private var animationProgress: Double = 0
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }
            
            // 成就弹窗
            VStack(spacing: 24) {
                // 成就图标
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animationProgress)
                    
                    Text(achievement.emoji)
                        .font(.system(size: 60))
                        .scaleEffect(animationProgress)
                }
                .overlay(
                    Circle()
                        .stroke(achievement.color, lineWidth: 3)
                        .scaleEffect(1.2)
                        .opacity(glowOpacity)
                )
                
                // 成就信息
                VStack(spacing: 8) {
                    Text("🎉 解锁新成就！")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(achievement.color)
                    
                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 关闭按钮
                Button("太棒了！") {
                    dismissPopup()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(achievement.color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .padding(.horizontal, 20)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animationProgress = 1.0
        }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }
    
    private func dismissPopup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - 成长点数获得提示
struct PointsGainPopup: View {
    let points: Int
    @Binding var isPresented: Bool
    
    @State private var animationProgress: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
            
            Text("+\(points) 成长点")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
        .offset(y: animationProgress * -100)
        .opacity(2 - animationProgress)
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                animationProgress = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isPresented = false
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DailyFeedbackPopup(
            data: DailyFeedbackData(wordsReviewed: 12, masteryImprovement: 6.0, consecutiveDays: 7),
            isPresented: .constant(true),
            motivationSystem: MotivationSystem()
        )
        
        ReviewCompletionPopup(
            data: ReviewCompletionData(totalWords: 10, correctAnswers: 7, masteryRate: 70.0, newWordsMastered: 2),
            isPresented: .constant(true),
            motivationSystem: MotivationSystem()
        )
    }
}

import SwiftUI
import Charts

// MARK: - 数据反馈板块
struct DataFeedbackView: View {
    @StateObject private var wrongWordManager = WrongWordManager()
    @StateObject private var motivationSystem = MotivationSystem()
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingDetailedStats = false
    
    enum TimeRange: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case quarter = "本季度"
        case year = "本年"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题和时间范围选择
                HeaderSection(selectedTimeRange: $selectedTimeRange)
                
                // 总体成就概览
                OverallAchievementSection(
                    wrongWordManager: wrongWordManager,
                    motivationSystem: motivationSystem
                )
                
                // 掌握率趋势
                MasteryTrendSection(
                    wrongWordManager: wrongWordManager,
                    timeRange: selectedTimeRange
                )
                
                // 错题减少情况
                ErrorReductionSection(
                    wrongWordManager: wrongWordManager,
                    timeRange: selectedTimeRange
                )
                
                // 学习进度图表
                LearningProgressSection(
                    wrongWordManager: wrongWordManager,
                    timeRange: selectedTimeRange
                )
                
                // 成就徽章展示
                AchievementSection(motivationSystem: motivationSystem)
                
                // 详细统计入口
                DetailedStatsButton(onTap: {
                    showingDetailedStats = true
                })
            }
            .padding()
        }
        .navigationTitle("学习数据")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingDetailedStats) {
            DetailedStatsView(wrongWordManager: wrongWordManager)
        }
    }
}

// MARK: - 标题和时间范围选择
struct HeaderSection: View {
    @Binding var selectedTimeRange: DataFeedbackView.TimeRange
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📊 学习成效")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    // 分享功能
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            
            // 时间范围选择器
            Picker("时间范围", selection: $selectedTimeRange) {
                ForEach(DataFeedbackView.TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - 总体成就概览
struct OverallAchievementSection: View {
    @ObservedObject var wrongWordManager: WrongWordManager
    @ObservedObject var motivationSystem: MotivationSystem
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🎯 总体成就")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AchievementCard(
                    title: "已挂曲线",
                    value: "\(wrongWordManager.totalWordsCount)",
                    subtitle: "个单词",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    trend: "+12"
                )
                
                AchievementCard(
                    title: "掌握率",
                    value: "\(Int(100 - wrongWordManager.averageErrorRate))",
                    subtitle: "%",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    trend: "+15%"
                )
                
                AchievementCard(
                    title: "连续学习",
                    value: "\(motivationSystem.consecutiveDays)",
                    subtitle: "天",
                    icon: "flame.fill",
                    color: .orange,
                    trend: "🔥"
                )
                
                AchievementCard(
                    title: "成长点数",
                    value: "\(motivationSystem.growthPoints)",
                    subtitle: "点",
                    icon: "star.fill",
                    color: .purple,
                    trend: "+50"
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 成就卡片
struct AchievementCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(trend)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 掌握率趋势
struct MasteryTrendSection: View {
    @ObservedObject var wrongWordManager: WrongWordManager
    let timeRange: DataFeedbackView.TimeRange
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📈 掌握率趋势")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(100 - wrongWordManager.averageErrorRate))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
            
            // 趋势图表
            Chart {
                ForEach(generateTrendData(), id: \.date) { dataPoint in
                    LineMark(
                        x: .value("日期", dataPoint.date),
                        y: .value("掌握率", dataPoint.masteryRate)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("日期", dataPoint.date),
                        y: .value("掌握率", dataPoint.masteryRate)
                    )
                    .foregroundStyle(.green.opacity(0.1))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        Text("\(value.as(Double.self)?.formatted(.number) ?? "")%")
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func generateTrendData() -> [TrendDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [TrendDataPoint] = []
        
        for i in 0..<timeRange.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let masteryRate = Double.random(in: 45...75) // 模拟数据
                dataPoints.append(TrendDataPoint(date: date, masteryRate: masteryRate))
            }
        }
        
        return dataPoints.reversed()
    }
}

// MARK: - 错题减少情况
struct ErrorReductionSection: View {
    @ObservedObject var wrongWordManager: WrongWordManager
    let timeRange: DataFeedbackView.TimeRange
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📉 错题减少情况")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("减少")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(calculateErrorReduction())")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
            }
            
            // 错题统计
            HStack(spacing: 20) {
                ErrorStatItem(
                    title: "总错题",
                    value: "\(wrongWordManager.totalWordsCount)",
                    color: .red
                )
                
                ErrorStatItem(
                    title: "已掌握",
                    value: "\(wrongWordManager.masteredWordsCount)",
                    color: .green
                )
                
                ErrorStatItem(
                    title: "待复习",
                    value: "\(wrongWordManager.unmasteredWordsCount)",
                    color: .orange
                )
            }
            
            // 减少趋势
            VStack(spacing: 8) {
                HStack {
                    Text("错题减少趋势")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                Chart {
                    ForEach(generateErrorReductionData(), id: \.date) { dataPoint in
                        BarMark(
                            x: .value("日期", dataPoint.date),
                            y: .value("错题数", dataPoint.errorCount)
                        )
                        .foregroundStyle(.red.opacity(0.7))
                    }
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            Text("\(value.as(Int.self)?.formatted() ?? "")")
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func calculateErrorReduction() -> String {
        let reduction = wrongWordManager.masteredWordsCount
        return "+\(reduction)"
    }
    
    private func generateErrorReductionData() -> [ErrorDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [ErrorDataPoint] = []
        
        for i in 0..<timeRange.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let errorCount = Int.random(in: 10...50) // 模拟数据
                dataPoints.append(ErrorDataPoint(date: date, errorCount: errorCount))
            }
        }
        
        return dataPoints.reversed()
    }
}

// MARK: - 错题统计项
struct ErrorStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
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
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 学习进度图表
struct LearningProgressSection: View {
    @ObservedObject var wrongWordManager: WrongWordManager
    let timeRange: DataFeedbackView.TimeRange
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📊 学习进度")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 进度环形图
            HStack(spacing: 20) {
                // 总体进度
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: overallProgress)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(overallProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    Text("总体进度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // 详细进度
                VStack(spacing: 12) {
                    ProgressRow(
                        title: "已掌握",
                        progress: masteredProgress,
                        color: .green
                    )
                    
                    ProgressRow(
                        title: "学习中",
                        progress: learningProgress,
                        color: .orange
                    )
                    
                    ProgressRow(
                        title: "待开始",
                        progress: pendingProgress,
                        color: .gray
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var overallProgress: Double {
        guard wrongWordManager.totalWordsCount > 0 else { return 0.0 }
        return Double(wrongWordManager.masteredWordsCount) / Double(wrongWordManager.totalWordsCount)
    }
    
    private var masteredProgress: Double {
        guard wrongWordManager.totalWordsCount > 0 else { return 0.0 }
        return Double(wrongWordManager.masteredWordsCount) / Double(wrongWordManager.totalWordsCount)
    }
    
    private var learningProgress: Double {
        guard wrongWordManager.totalWordsCount > 0 else { return 0.0 }
        return Double(wrongWordManager.unmasteredWordsCount) / Double(wrongWordManager.totalWordsCount)
    }
    
    private var pendingProgress: Double {
        return 1.0 - masteredProgress - learningProgress
    }
}

// MARK: - 进度行
struct ProgressRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - 成就徽章展示
struct AchievementSection: View {
    @ObservedObject var motivationSystem: MotivationSystem
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🏆 成就徽章")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(motivationSystem.unlockedAchievements.count)/\(Achievement.allCases.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(motivationSystem.unlockedAchievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
                
                // 未解锁的成就
                ForEach(Achievement.allCases.filter { !motivationSystem.unlockedAchievements.contains($0) }) { achievement in
                    AchievementBadge(achievement: achievement, isUnlocked: false)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 成就徽章
struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    init(achievement: Achievement, isUnlocked: Bool = true) {
        self.achievement = achievement
        self.isUnlocked = isUnlocked
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color.opacity(0.2) : .gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(achievement.emoji)
                    .font(.title2)
                    .opacity(isUnlocked ? 1.0 : 0.3)
            }
            
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 详细统计按钮
struct DetailedStatsButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("查看详细统计")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding()
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - 详细统计视图
struct DetailedStatsView: View {
    @ObservedObject var wrongWordManager: WrongWordManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("详细统计数据")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // 这里可以添加更多详细的统计信息
                    Text("更多详细统计功能正在开发中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("详细统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 数据模型
struct TrendDataPoint {
    let date: Date
    let masteryRate: Double
}

struct ErrorDataPoint {
    let date: Date
    let errorCount: Int
}

#Preview {
    NavigationView {
        DataFeedbackView()
    }
}

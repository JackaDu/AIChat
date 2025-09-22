import SwiftUI

// MARK: - 艾宾浩斯遗忘曲线可视化视图
struct EbbinghausCurveView: View {
    @ObservedObject var manager: WrongWordManager
    @State private var animationOffset: Double = 0
    @State private var curveAnimationProgress: Double = 0
    
    // 曲线参数
    private let curveHeight: CGFloat = 150
    private let curveWidth: CGFloat = 300
    private let pointSize: CGFloat = 8
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("📊 错题记忆曲线")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("共 \(manager.wrongWords.count) 个单词")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("点击红点查看详情")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            
            // 曲线图表区域
            ZStack {
                // 背景网格
                CurveBackgroundGrid()
                
                // 艾宾浩斯曲线（带动画）
                EbbinghausCurvePath()
                    .trim(from: 0, to: curveAnimationProgress)
                    .stroke(.blue.opacity(0.3), lineWidth: 2)
                    .animation(.easeInOut(duration: 2), value: curveAnimationProgress)
                
                // 简化复习提升效果
                
                // 单词记忆点
                ForEach(Array(manager.wrongWords.enumerated()), id: \.element.id) { index, word in
                    MemoryPointView(
                        word: word,
                        position: calculatePointPosition(for: word, index: index),
                        animationOffset: animationOffset
                    )
                }
                
                // 时间轴标签
                TimeAxisLabels()
            }
            .frame(height: curveHeight + 40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // 图例说明
            CurveLegendView()
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationOffset = 1.0
            }
            
            // 曲线绘制动画
            withAnimation(.easeInOut(duration: 1.5)) {
                curveAnimationProgress = 1.0
            }
            
            // 同步错题本数据到游戏化系统
            syncWithGameSystem()
        }
    }
    
    // 计算单词在曲线上的位置
    private func calculatePointPosition(for word: WrongWord, index: Int) -> CGPoint {
        let daysSinceAdded = 0 // 移除 dateAdded 引用，使用默认值
        let daysSinceLastReview = Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
        
        // X轴：基于时间（0-30天）
        let xProgress = min(Double(daysSinceLastReview) / 30.0, 1.0)
        let x = xProgress * Double(curveWidth)
        
        // Y轴：基于艾宾浩斯曲线公式
        let memoryStrength = calculateMemoryStrength(daysSinceLastReview: daysSinceLastReview, reviewCount: word.reviewCount)
        let y = Double(curveHeight) * (1.0 - memoryStrength)
        
        return CGPoint(x: x, y: y)
    }
    
    // 计算记忆强度（基于艾宾浩斯公式）
    private func calculateMemoryStrength(daysSinceLastReview: Int, reviewCount: Int) -> Double {
        let days = Double(daysSinceLastReview)
        let reviews = Double(max(reviewCount, 1))
        
        // 艾宾浩斯遗忘曲线：R = e^(-t/S)
        // R: 记忆保持率, t: 时间, S: 记忆强度（受复习次数影响）
        let memoryStrength = 1.0 + (reviews - 1.0) * 0.5 // 复习次数增加记忆强度
        let retention = exp(-days / memoryStrength)
        
        return max(retention, 0.1) // 最低保持10%
    }
    
    // 同步错题本数据到游戏化系统
    private func syncWithGameSystem() {
        // 数据同步已简化
    }
}

// MARK: - 记忆点视图
struct MemoryPointView: View {
    let word: WrongWord
    let position: CGPoint
    let animationOffset: Double
    
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            Circle()
                .fill(pointColor)
                .frame(width: pointSize, height: pointSize)
                .overlay(
                    Circle()
                        .stroke(pointBorderColor, lineWidth: 2)
                )
                .scaleEffect(isUrgent ? 1.0 + animationOffset * 0.3 : 1.0)
                .animation(.easeInOut(duration: 1), value: animationOffset)
        }
        .position(position)
        .sheet(isPresented: $showingDetail) {
            DetailedWordMemoryView(word: word)
                .presentationDetents([.medium, .large])
        }
    }
    
    private var pointSize: CGFloat {
        isUrgent ? 12 : 8
    }
    
    private var pointColor: Color {
        let daysSinceLastReview = Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
        let memoryStrength = calculateMemoryStrength(daysSinceLastReview: daysSinceLastReview)
        
        if isUrgent {
            return .red
        } else if memoryStrength > 0.7 {
            return .green
        } else if memoryStrength > 0.4 {
            return .orange
        } else {
            return .gray
        }
    }
    
    private var pointBorderColor: Color {
        isUrgent ? .red : .white
    }
    
    private var isUrgent: Bool {
        let daysSinceLastReview = Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
        let memoryStrength = calculateMemoryStrength(daysSinceLastReview: daysSinceLastReview)
        return memoryStrength < 0.3 && !word.isMastered
    }
    
    private func calculateMemoryStrength(daysSinceLastReview: Int) -> Double {
        let days = Double(daysSinceLastReview)
        let reviews = Double(max(word.reviewCount, 1))
        let memoryStrength = 1.0 + (reviews - 1.0) * 0.5
        return max(exp(-days / memoryStrength), 0.1)
    }
}

// MARK: - 艾宾浩斯曲线路径
struct EbbinghausCurvePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let steps = 100
        let width = rect.width
        let height = rect.height
        
        for i in 0...steps {
            let x = Double(i) / Double(steps) * width
            let normalizedTime = Double(i) / Double(steps) * 30 // 30天
            
            // 艾宾浩斯遗忘曲线：y = e^(-t/τ)
            let retention = exp(-normalizedTime / 5.0) // τ = 5天
            let y = height * (1.0 - retention)
            
            let point = CGPoint(x: x, y: y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        return path
    }
}

// MARK: - 背景网格
struct CurveBackgroundGrid: View {
    var body: some View {
        ZStack {
            // 水平网格线
            VStack(spacing: 0) {
                ForEach(0..<6) { i in
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .frame(height: 0.5)
                    
                    if i < 5 {
                        Spacer()
                    }
                }
            }
            
            // 垂直网格线
            HStack(spacing: 0) {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .frame(width: 0.5)
                    
                    if i < 7 {
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - 时间轴标签
struct TimeAxisLabels: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Text("今天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("7天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("15天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("30天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
        }
    }
}

// MARK: - 图例说明
struct CurveLegendView: View {
    var body: some View {
        HStack(spacing: 20) {
            LegendItem(color: .green, text: "记忆良好")
            LegendItem(color: .orange, text: "记忆下降")
            LegendItem(color: .red, text: "即将遗忘")
            LegendItem(color: .gray, text: "需要复习")
        }
        .font(.caption2)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 单词记忆详情弹窗
struct WordMemoryDetailView: View {
    let word: WrongWord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 单词信息
            HStack {
                Text(word.word)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Circle()
                    .fill(memoryStatusColor)
                    .frame(width: 16, height: 16)
            }
            
            Text(word.meaning)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Divider()
            
            // 记忆统计
            VStack(alignment: .leading, spacing: 8) {
                Text("记忆状态")
                    .font(.headline)
                
                HStack {
                    Text("记忆强度:")
                    Spacer()
                    Text("\(Int(memoryStrength * 100))%")
                        .fontWeight(.semibold)
                        .foregroundStyle(memoryStatusColor)
                }
                
                HStack {
                    Text("复习次数:")
                    Spacer()
                    Text("\(word.reviewCount)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("距离上次复习:")
                    Spacer()
                    Text("\(daysSinceLastReview)天")
                        .fontWeight(.semibold)
                }
                
                if needsReview {
                    Text("⚠️ 建议立即复习")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .frame(width: 250)
    }
    
    private var daysSinceLastReview: Int {
        Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
    }
    
    private var memoryStrength: Double {
        let days = Double(daysSinceLastReview)
        let reviews = Double(max(word.reviewCount, 1))
        let strength = 1.0 + (reviews - 1.0) * 0.5
        return max(exp(-days / strength), 0.1)
    }
    
    private var memoryStatusColor: Color {
        if memoryStrength > 0.7 {
            return .green
        } else if memoryStrength > 0.4 {
            return .orange
        } else if memoryStrength > 0.2 {
            return .red
        } else {
            return .gray
        }
    }
    
    private var needsReview: Bool {
        memoryStrength < 0.3 && !word.isMastered
    }
}

// MARK: - 改进曲线路径（复习后上升效果）
struct ImprovementCurvePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let steps = 50
        let width = rect.width
        let height = rect.height
        
        for i in 0...steps {
            let x = Double(i) / Double(steps) * width
            let normalizedTime = Double(i) / Double(steps) * 15 // 15天的改进效果
            
            // 改进后的记忆曲线：更缓慢的衰减
            let improvedRetention = exp(-normalizedTime / 10.0) // τ = 10天（比原来更好）
            let y = height * (1.0 - improvedRetention)
            
            let point = CGPoint(x: x, y: y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        return path
    }
}

// MARK: - 详细单词记忆分析视图
struct DetailedWordMemoryView: View {
    let word: WrongWord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. 单词基本信息
                    WordBasicInfoCard(word: word)
                    
                    // 2. 记忆统计分析
                    MemoryStatisticsCard(word: word)
                    
                    // 3. 记忆曲线分析
                    IndividualMemoryCurveCard(word: word)
                    
                    // 4. 复习历史
                    ReviewHistoryCard(word: word)
                    
                    // 5. 建议行动
                    ActionRecommendationCard(word: word)
                }
                .padding()
            }
            .navigationTitle("记忆分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 单词基本信息卡片
private struct WordBasicInfoCard: View {
    let word: WrongWord
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.word)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(word.meaning)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    if !word.context.isEmpty && !word.context.contains("示例句子") {
                        Text("例句：\(word.context)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // 紧急程度指示器
                VStack(spacing: 8) {
                    Circle()
                        .fill(urgencyColor)
                        .frame(width: 20, height: 20)
                    
                    Text(urgencyText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var urgencyColor: Color {
        let daysSinceLastReview = Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
        let memoryStrength = calculateMemoryStrength(daysSinceLastReview: daysSinceLastReview)
        
        if memoryStrength < 0.3 {
            return .red
        } else if memoryStrength < 0.6 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var urgencyText: String {
        let daysSinceLastReview = Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
        let memoryStrength = calculateMemoryStrength(daysSinceLastReview: daysSinceLastReview)
        
        if memoryStrength < 0.3 {
            return "紧急"
        } else if memoryStrength < 0.6 {
            return "注意"
        } else {
            return "良好"
        }
    }
    
    private func calculateMemoryStrength(daysSinceLastReview: Int) -> Double {
        let days = Double(daysSinceLastReview)
        let reviews = Double(max(word.reviewCount, 1))
        let memoryStrength = 1.0 + (reviews - 1.0) * 0.5
        return max(exp(-days / memoryStrength), 0.1)
    }
}

// MARK: - 记忆统计卡片
private struct MemoryStatisticsCard: View {
    let word: WrongWord
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📊 记忆统计")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                DetailStatItem(
                    title: "复习次数",
                    value: "\(word.reviewCount)",
                    color: .blue
                )
                
                DetailStatItem(
                    title: "记忆强度",
                    value: "\(Int(currentMemoryStrength * 100))%",
                    color: memoryStrengthColor
                )
                
                DetailStatItem(
                    title: "天数间隔",
                    value: "\(daysSinceLastReview)天",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var currentMemoryStrength: Double {
        let days = Double(daysSinceLastReview)
        let reviews = Double(max(word.reviewCount, 1))
        let memoryStrength = 1.0 + (reviews - 1.0) * 0.5
        return max(exp(-days / memoryStrength), 0.1)
    }
    
    private var daysSinceLastReview: Int {
        Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
    }
    
    private var memoryStrengthColor: Color {
        if currentMemoryStrength > 0.7 { return .green }
        if currentMemoryStrength > 0.4 { return .orange }
        return .red
    }
}

// MARK: - 统计项组件（错题本专用）
private struct DetailStatItem: View {
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
    }
}

// MARK: - 个人记忆曲线卡片
private struct IndividualMemoryCurveCard: View {
    let word: WrongWord
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📈 记忆曲线预测")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("基于艾宾浩斯遗忘曲线")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            
            // 简化的个人记忆曲线
            IndividualMemoryCurve(word: word)
                .frame(height: 120)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 个人记忆曲线
private struct IndividualMemoryCurve: View {
    let word: WrongWord
    
    var body: some View {
        ZStack {
            // 背景网格
            Path { path in
                let width: CGFloat = 280
                let height: CGFloat = 100
                
                // 水平线
                for i in 1...3 {
                    let y = height * CGFloat(i) / 4
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                
                // 垂直线
                for i in 1...6 {
                    let x = width * CGFloat(i) / 7
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            
            // 遗忘曲线
            Path { path in
                let width: CGFloat = 280
                let height: CGFloat = 100
                let reviews = Double(max(word.reviewCount, 1))
                let memoryStrengthBase = 1.0 + (reviews - 1.0) * 0.5
                
                path.move(to: CGPoint(x: 0, y: height * 0.1)) // 起点：90%记忆强度
                
                for day in 1...30 {
                    let x = width * CGFloat(day) / 30.0
                    let retention = exp(-Double(day) / memoryStrengthBase)
                    let y = height * (1.0 - retention)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(.blue, lineWidth: 2)
            
            // 当前位置标记
            let daysSinceLastReview = Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
            let currentX = 280 * CGFloat(min(daysSinceLastReview, 30)) / 30.0
            let reviews = Double(max(word.reviewCount, 1))
            let memoryStrengthBase = 1.0 + (reviews - 1.0) * 0.5
            let currentRetention = exp(-Double(daysSinceLastReview) / memoryStrengthBase)
            let currentY = 100 * (1.0 - currentRetention)
            
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .position(x: currentX, y: currentY)
        }
    }
}

// MARK: - 复习历史卡片
private struct ReviewHistoryCard: View {
    let word: WrongWord
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📅 复习历史")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("最近 \(min(word.reviewDates.count, 5)) 次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if word.reviewDates.isEmpty {
                Text("暂无复习记录")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(word.reviewDates.suffix(5).reversed().enumerated()), id: \.offset) { index, date in
                        ReviewHistoryItem(date: date, isLatest: index == 0)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 复习历史项
private struct ReviewHistoryItem: View {
    let date: Date
    let isLatest: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isLatest ? .green : .gray)
                .frame(width: 8, height: 8)
            
            Text(formattedDate)
                .font(.body)
                .foregroundStyle(isLatest ? .primary : .secondary)
            
            Spacer()
            
            Text(timeAgo)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }
    
    private var timeAgo: String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 {
            return "今天"
        } else if days == 1 {
            return "昨天"
        } else {
            return "\(days)天前"
        }
    }
}

// MARK: - 行动建议卡片
private struct ActionRecommendationCard: View {
    let word: WrongWord
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("💡 复习建议")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                RecommendationItem(
                    icon: "clock",
                    title: "下次复习时间",
                    description: nextReviewRecommendation,
                    color: .blue
                )
                
                RecommendationItem(
                    icon: "target",
                    title: "复习重点",
                    description: focusRecommendation,
                    color: .orange
                )
                
                RecommendationItem(
                    icon: "lightbulb",
                    title: "学习建议",
                    description: studyRecommendation,
                    color: .green
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var nextReviewRecommendation: String {
        let daysSinceLastReview = Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0
        let memoryStrength = calculateMemoryStrength(daysSinceLastReview: daysSinceLastReview)
        
        if memoryStrength < 0.3 {
            return "立即复习！记忆强度已降至危险水平"
        } else if memoryStrength < 0.6 {
            return "建议今天复习，巩固记忆"
        } else {
            let nextReviewDay = calculateNextReviewDay()
            return "建议 \(nextReviewDay) 天后复习"
        }
    }
    
    private var focusRecommendation: String {
        if word.reviewCount <= 1 {
            return "重点记忆单词拼写和基本含义"
        } else if word.reviewCount <= 3 {
            return "加强词汇搭配和语境应用练习"
        } else {
            return "通过阅读和写作巩固深度理解"
        }
    }
    
    private var studyRecommendation: String {
        let memoryStrength = calculateMemoryStrength(daysSinceLastReview: Calendar.current.dateComponents([.day], from: word.reviewDates.last ?? Date(), to: Date()).day ?? 0)
        
        if memoryStrength < 0.4 {
            return "使用多种记忆方法：联想、词根、例句"
        } else {
            return "保持定期复习，避免记忆衰减"
        }
    }
    
    private func calculateMemoryStrength(daysSinceLastReview: Int) -> Double {
        let days = Double(daysSinceLastReview)
        let reviews = Double(max(word.reviewCount, 1))
        let memoryStrength = 1.0 + (reviews - 1.0) * 0.5
        return max(exp(-days / memoryStrength), 0.1)
    }
    
    private func calculateNextReviewDay() -> Int {
        let reviewCount = word.reviewCount + 1
        switch reviewCount {
        case 1: return 1
        case 2: return 3
        case 3: return 7
        case 4: return 15
        default: return 30
        }
    }
}

// MARK: - 建议项
private struct RecommendationItem: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    EbbinghausCurveView(manager: WrongWordManager())
        .padding()
}

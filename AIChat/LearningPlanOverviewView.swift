import SwiftUI

struct LearningPlanOverviewView: View {
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    VStack(spacing: 8) {
                        Text("学习规划总览")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("了解您的个性化学习系统架构")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 学习系统架构图
                    LearningSystemArchitectureCard()
                    
                    // 学习模式对比
                    LearningModesComparisonCard()
                    
                    // 复习时间线
                    ReviewTimelineCard()
                    
                    // 艾宾浩斯学习规划表
                    EbbinghausScheduleCard()
                    
                    // 学习进度统计
                    LearningProgressCard()
                    
                    // 个性化设置
                    PersonalizedSettingsCard()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
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

// MARK: - 学习系统架构卡片
struct LearningSystemArchitectureCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sitemap")
                    .foregroundStyle(.blue)
                    .font(.title2)
                
                Text("学习系统架构")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                // 数据源层
                ArchitectureLayer(
                    title: "数据源层",
                    icon: "externaldrive.connected",
                    color: .green,
                    items: [
                        "📚 教材词汇库",
                        "❌ 错题本",
                        "✅ 已掌握词汇",
                        "📊 学习记录"
                    ]
                )
                
                // 学习模式层
                ArchitectureLayer(
                    title: "学习模式层",
                    icon: "brain.head.profile",
                    color: .blue,
                    items: [
                        "🎯 智能学习 (错题+新词)",
                        "📋 列表学习 (批量检测)",
                        "🚨 紧急复习 (遗忘曲线)",
                        "🎲 随机复习 (巩固记忆)"
                    ]
                )
                
                // 智能算法层
                ArchitectureLayer(
                    title: "智能算法层",
                    icon: "cpu",
                    color: .purple,
                    items: [
                        "🧠 艾宾浩斯遗忘曲线",
                        "🎯 个性化推荐算法",
                        "📈 学习进度追踪",
                        "⚡ 自适应学习节奏"
                    ]
                )
                
                // 用户界面层
                ArchitectureLayer(
                    title: "用户界面层",
                    icon: "iphone",
                    color: .orange,
                    items: [
                        "📱 直观的卡片界面",
                        "📊 实时进度统计",
                        "🎨 个性化主题设置",
                        "🔊 多语言发音支持"
                    ]
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ArchitectureLayer: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - 学习模式对比卡片
struct LearningModesComparisonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "rectangle.split.3x1")
                    .foregroundStyle(.green)
                    .font(.title2)
                
                Text("学习模式对比")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                LearningModeRow(
                    title: "智能学习",
                    icon: "brain.head.profile",
                    color: .blue,
                    description: "错题复习 + 新词学习",
                    features: ["平衡发展", "深度学习", "个性化推荐"],
                    bestFor: "日常学习"
                )
                
                LearningModeRow(
                    title: "列表学习",
                    icon: "list.bullet",
                    color: .orange,
                    description: "批量检测单词掌握情况",
                    features: ["高效检测", "快速筛选", "批量操作"],
                    bestFor: "快速检测"
                )
                
                LearningModeRow(
                    title: "紧急复习",
                    icon: "alarm.fill",
                    color: .red,
                    description: "基于遗忘曲线科学复习",
                    features: ["科学算法", "防止遗忘", "精准时机"],
                    bestFor: "防止遗忘"
                )
                
                LearningModeRow(
                    title: "随机复习",
                    icon: "shuffle",
                    color: .purple,
                    description: "巩固已掌握词汇",
                    features: ["随机性", "巩固记忆", "保持熟练"],
                    bestFor: "巩固记忆"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct LearningModeRow: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let features: [String]
    let bestFor: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(bestFor)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.2))
                    )
            }
            
            HStack {
                ForEach(features, id: \.self) { feature in
                    Text(feature)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.gray.opacity(0.2))
                        )
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.05))
        )
    }
}

// MARK: - 复习时间线卡片
struct ReviewTimelineCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.purple)
                    .font(.title2)
                
                Text("艾宾浩斯复习时间线")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                ReviewTimelineItem(
                    day: "第1天",
                    description: "初次学习",
                    color: .blue,
                    icon: "star.fill"
                )
                
                ReviewTimelineItem(
                    day: "第2天",
                    description: "第一次复习",
                    color: .green,
                    icon: "arrow.clockwise"
                )
                
                ReviewTimelineItem(
                    day: "第4天",
                    description: "第二次复习",
                    color: .orange,
                    icon: "arrow.clockwise"
                )
                
                ReviewTimelineItem(
                    day: "第7天",
                    description: "第三次复习",
                    color: .red,
                    icon: "arrow.clockwise"
                )
                
                ReviewTimelineItem(
                    day: "第15天",
                    description: "第四次复习",
                    color: .purple,
                    icon: "arrow.clockwise"
                )
                
                ReviewTimelineItem(
                    day: "第30天",
                    description: "第五次复习",
                    color: .indigo,
                    icon: "arrow.clockwise"
                )
                
                ReviewTimelineItem(
                    day: "第60天",
                    description: "长期记忆巩固",
                    color: .gray,
                    icon: "checkmark.circle.fill"
                )
            }
            
            Text("💡 基于艾宾浩斯遗忘曲线，系统会自动计算每个单词的最佳复习时间")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ReviewTimelineItem: View {
    let day: String
    let description: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(day)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 学习进度统计卡片
struct LearningProgressCard: View {
    @EnvironmentObject var wrongWordManager: WrongWordManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
                
                Text("学习进度统计")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                ProgressStatRow(
                    title: "错词总数",
                    value: "\(wrongWordManager.wrongWords.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                ProgressStatRow(
                    title: "已掌握词汇",
                    value: "\(wrongWordManager.masteredWords)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                ProgressStatRow(
                    title: "今日复习",
                    value: "\(wrongWordManager.todayReviewWords.count)",
                    icon: "alarm.fill",
                    color: .orange
                )
                
                ProgressStatRow(
                    title: "总复习次数",
                    value: "\(wrongWordManager.totalReviewCount)",
                    icon: "arrow.clockwise",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProgressStatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 个性化设置卡片
struct PersonalizedSettingsCard: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.gray)
                    .font(.title2)
                
                Text("个性化设置")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                SettingRow(
                    title: "学习目标",
                    value: "\(preferencesManager.userPreferences.dailyStudyAmount.rawValue) 个/天",
                    icon: "target",
                    color: .blue
                )
                
                SettingRow(
                    title: "学习模式",
                    value: preferencesManager.userPreferences.defaultLearningMode.displayName,
                    icon: "brain.head.profile",
                    color: .green
                )
                
                SettingRow(
                    title: "发音类型",
                    value: preferencesManager.userPreferences.pronunciationType.displayName,
                    icon: "speaker.wave.2.fill",
                    color: .orange
                )
                
                SettingRow(
                    title: "主题模式",
                    value: preferencesManager.userPreferences.isNightMode ? "夜间模式" : "日间模式",
                    icon: "moon.fill",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SettingRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 艾宾浩斯学习规划表卡片
struct EbbinghausScheduleCard: View {
    @State private var showingSchedule = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.indigo)
                    .font(.title2)
                
                Text("艾宾浩斯学习规划表")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "table.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("详细学习计划")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("查看每日记忆和复习安排")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showingSchedule = true
                    } label: {
                        Text("查看详情")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.green)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("科学复习间隔")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("1天→2天→4天→7天→15天→30天")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.badge.xmark")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("进度可视化")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("清晰显示已完成、今日任务和未来计划")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.indigo.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingSchedule) {
            EbbinghausLearningScheduleView()
                .environmentObject(WrongWordManager())
                .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
        }
    }
}

#Preview {
    LearningPlanOverviewView()
        .environmentObject(WrongWordManager())
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}

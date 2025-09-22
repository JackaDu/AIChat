import SwiftUI

struct EbbinghausLearningScheduleView: View {
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    // 学习计划数据
    @State private var learningSchedule: [DaySchedule] = []
    @State private var currentDay = 1
    @State private var selectedUnit: Unit = .unit1
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 头部信息
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Day \(currentDay)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("\(preferencesManager.userPreferences.selectedTextbookVersion.rawValue)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // 单元选择器
                        Picker("单元", selection: $selectedUnit) {
                            ForEach(Unit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                // 学习规划表
                ScrollView {
                    VStack(spacing: 0) {
                        // 表头
                        HStack(spacing: 0) {
                            Text("Day")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 60, alignment: .leading)
                            
                            Text("记忆")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 80, alignment: .center)
                            
                            ForEach(1...5, id: \.self) { reviewNumber in
                                Text("复习\(reviewNumber)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 80, alignment: .center)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        
                        // 学习计划行
                        ForEach(learningSchedule, id: \.day) { schedule in
                            DayScheduleRow(
                                schedule: schedule,
                                currentDay: currentDay,
                                onDayTapped: { day in
                                    currentDay = day
                                }
                            )
                        }
                    }
                }
                
                // 底部说明
                VStack(spacing: 8) {
                    Text("艾宾浩斯遗忘曲线学习计划")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("基于科学记忆规律，在遗忘前及时复习巩固")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // 图例
                    HStack(spacing: 16) {
                        ScheduleLegendItem(icon: "checkmark.circle.fill", color: .green, text: "已完成")
                        ScheduleLegendItem(icon: "circle.fill", color: .blue, text: "今日任务")
                        ScheduleLegendItem(icon: "circle", color: .gray, text: "未来计划")
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            generateLearningSchedule()
        }
        .onChange(of: selectedUnit) { _, _ in
            generateLearningSchedule()
        }
    }
    
    private func generateLearningSchedule() {
        learningSchedule = []
        
        // 生成30天的学习计划
        for day in 1...30 {
            var schedule = DaySchedule(day: day)
            
            // 记忆新单词（每天一个新列表）
            schedule.memory = "List\(day)"
            
            // 根据艾宾浩斯遗忘曲线安排复习
            // 第1天：记忆
            // 第2天：复习1
            // 第4天：复习2
            // 第7天：复习3
            // 第15天：复习4
            // 第30天：复习5
            
            if day >= 2 {
                schedule.review1 = "List\(day - 1)"
            }
            if day >= 4 {
                schedule.review2 = "List\(day - 3)"
            }
            if day >= 7 {
                schedule.review3 = "List\(day - 6)"
            }
            if day >= 15 {
                schedule.review4 = "List\(day - 14)"
            }
            if day >= 30 {
                schedule.review5 = "List\(day - 29)"
            }
            
            learningSchedule.append(schedule)
        }
    }
}

// MARK: - 学习计划数据结构
struct DaySchedule {
    let day: Int
    var memory: String?
    var review1: String?
    var review2: String?
    var review3: String?
    var review4: String?
    var review5: String?
    
    var isCompleted: Bool {
        // 根据实际学习进度判断是否完成
        return false // 这里可以根据实际数据判断
    }
    
    var isToday: Bool {
        // 判断是否为今天
        return false // 这里可以根据实际日期判断
    }
}

// MARK: - 每日学习计划行
struct DayScheduleRow: View {
    let schedule: DaySchedule
    let currentDay: Int
    let onDayTapped: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 天数
            Button {
                onDayTapped(schedule.day)
            } label: {
                Text("Day \(schedule.day)")
                    .font(.subheadline)
                    .fontWeight(schedule.day == currentDay ? .bold : .medium)
                    .foregroundStyle(schedule.day == currentDay ? .blue : .primary)
                    .frame(width: 60, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 记忆
            ScheduleCell(
                content: schedule.memory,
                isCompleted: schedule.isCompleted,
                isToday: schedule.day == currentDay
            )
            
            // 复习1-5
            ScheduleCell(
                content: schedule.review1,
                isCompleted: schedule.isCompleted,
                isToday: schedule.day == currentDay
            )
            
            ScheduleCell(
                content: schedule.review2,
                isCompleted: schedule.isCompleted,
                isToday: schedule.day == currentDay
            )
            
            ScheduleCell(
                content: schedule.review3,
                isCompleted: schedule.isCompleted,
                isToday: schedule.day == currentDay
            )
            
            ScheduleCell(
                content: schedule.review4,
                isCompleted: schedule.isCompleted,
                isToday: schedule.day == currentDay
            )
            
            ScheduleCell(
                content: schedule.review5,
                isCompleted: schedule.isCompleted,
                isToday: schedule.day == currentDay
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(schedule.day == currentDay ? .blue.opacity(0.1) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(schedule.day == currentDay ? .blue : .clear, lineWidth: 1)
        )
    }
}

// MARK: - 学习计划单元格
struct ScheduleCell: View {
    let content: String?
    let isCompleted: Bool
    let isToday: Bool
    
    var body: some View {
        HStack {
            if let content = content {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                } else if isToday {
                    Text(content)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text(content)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            } else {
                Text("")
            }
        }
        .frame(width: 80, alignment: .center)
    }
}

// MARK: - 图例项
struct ScheduleLegendItem: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    EbbinghausLearningScheduleView()
        .environmentObject(WrongWordManager())
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}

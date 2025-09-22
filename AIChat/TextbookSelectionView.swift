import SwiftUI

struct TextbookSelectionView: View {
    @Binding var userPreferences: UserPreferences
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @EnvironmentObject var wrongWordManager: WrongWordManager
    @EnvironmentObject var appwriteService: AppwriteService
    @State private var showingMainApp = false
    
    // 根据当前选择的教材获取可用单元
    private var availableUnits: [Unit] {
        let courseType = userPreferences.selectedCourseType
        let course = courseType == .required ? 
            userPreferences.selectedRequiredCourse.rawValue :
            userPreferences.selectedElectiveCourse.rawValue
        return Unit.availableUnits(for: courseType, course: course)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // 标题
                    VStack(spacing: 16) {
                        Text("选择教材版本")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("请选择你使用的英语教材版本和课程")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 教材版本选择
                    VStack(alignment: .leading, spacing: 16) {
                        Text("教材版本")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(TextbookVersion.allCases, id: \.self) { version in
                                TextbookVersionCard(
                                    version: version,
                                    isSelected: userPreferences.selectedTextbookVersion == version
                                ) {
                                    userPreferences.selectedTextbookVersion = version
                                }
                            }
                        }
                    }
                    
                    // 课程类型选择
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("课程类型")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            // 快速切换按钮
                            Button {
                                // 在必修和选修之间快速切换
                                if userPreferences.selectedCourseType == .required {
                                    userPreferences.selectedCourseType = .elective
                                    userPreferences.selectedElectiveCourse = .book1
                                } else {
                                    userPreferences.selectedCourseType = .required
                                    userPreferences.selectedRequiredCourse = .book1
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption)
                                    Text("切换")
                                        .font(.caption)
                                        .bold()
                                }
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        HStack(spacing: 16) {
                            ForEach(CourseType.allCases, id: \.self) { type in
                                CourseTypeCard(
                                    type: type,
                                    isSelected: userPreferences.selectedCourseType == type
                                ) {
                                    userPreferences.selectedCourseType = type
                                    // 重置课程选择
                                    if type == .required {
                                        userPreferences.selectedRequiredCourse = .book1
                                    } else {
                                        userPreferences.selectedElectiveCourse = .book1
                                    }
                                    // 重置单元选择为第一个单元
                                    let newAvailableUnits = Unit.availableUnits(for: type, course: type == .required ? RequiredCourse.book1.rawValue : ElectiveCourse.book1.rawValue)
                                    userPreferences.selectedUnits = newAvailableUnits.isEmpty ? [] : [newAvailableUnits[0]]
                                }
                            }
                        }
                        
                        // 当前选择提示
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("当前选择：\(userPreferences.selectedCourseType.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // 具体课程选择
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("具体课程")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            // 课程信息提示
                            Text("\(userPreferences.selectedCourseType == .required ? "必修" : "选修")课程")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        if userPreferences.selectedCourseType == .required {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                                ForEach(RequiredCourse.allCases, id: \.self) { course in
                                    CourseCard(
                                        course: course.rawValue,
                                        emoji: course.emoji,
                                        isSelected: userPreferences.selectedRequiredCourse == course,
                                        subtitle: ""
                                    ) {
                                        userPreferences.selectedRequiredCourse = course
                                    }
                                }
                            }
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                ForEach(ElectiveCourse.allCases, id: \.self) { course in
                                    CourseCard(
                                        course: course.rawValue,
                                        emoji: course.emoji,
                                        isSelected: userPreferences.selectedElectiveCourse == course,
                                        subtitle: ""
                                    ) {
                                        userPreferences.selectedElectiveCourse = course
                                    }
                                }
                            }
                        }
                        
                        // 课程选择提示
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("已选择：\(userPreferences.selectedCourseType == .required ? userPreferences.selectedRequiredCourse.rawValue : userPreferences.selectedElectiveCourse.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // 单元选择
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("学习单元")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("单选模式")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        Text("选择一个单元开始学习")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(availableUnits, id: \.self) { unit in
                                UnitSelectionCard(
                                    unit: unit,
                                    isSelected: userPreferences.selectedUnits.contains(unit)
                                ) {
                                    // 单选模式：选择新单元时清除其他选择
                                    userPreferences.selectedUnits = [unit]
                                }
                            }
                        }
                        
                        // 选择提示
                        if !userPreferences.selectedUnits.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("已选择单元")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    

                    
                    // 开始学习按钮
                    Button {
                        showingMainApp = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("开始学习")
                        }
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("教材选择")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingMainApp) {
                MainTabView()
                    .environmentObject(preferencesManager)
                    .environmentObject(wrongWordManager)
                    .environmentObject(appwriteService)
            }
        }
    }
}

// MARK: - 教材版本卡片
struct TextbookVersionCard: View {
    let version: TextbookVersion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(version.emoji)
                    .font(.system(size: 40))
                
                Text(version.rawValue)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? .blue : .gray.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - 课程类型卡片
struct CourseTypeCard: View {
    let type: CourseType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(type.emoji)
                    .font(.system(size: 40))
                
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? .green : .gray.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - 课程卡片
struct CourseCard: View {
    let course: String
    let emoji: String
    let isSelected: Bool
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 32))
                
                Text(course)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? .orange : .gray.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - 单元选择卡片
struct UnitSelectionCard: View {
    let unit: Unit
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(unit.rawValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text("单元")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(width: 50, height: 50)
            .background(isSelected ? .blue : .gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? .blue : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TextbookSelectionView(userPreferences: .constant(UserPreferences()))
}

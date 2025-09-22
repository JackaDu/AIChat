import SwiftUI

// MARK: - 单元选择界面
struct UnitSelectionView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUnits: Set<Unit>
    
    init() {
        // 从UserPreferencesManager获取当前选择的单元
        _selectedUnits = State(initialValue: [.unit1])
    }
    
    // 根据当前选择的教材获取可用单元
    private var availableUnits: [Unit] {
        let courseType = preferencesManager.userPreferences.selectedCourseType
        let course = courseType == .required ? 
            preferencesManager.userPreferences.selectedRequiredCourse.rawValue :
            preferencesManager.userPreferences.selectedElectiveCourse.rawValue
        return Unit.availableUnits(for: courseType, course: course)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部说明
                    VStack(spacing: 16) {
                        Image(systemName: "list.number")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        Text("选择学习单元")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("选择一个单元开始学习\n背单词时将只学习该单元的内容")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 20)
                    
                    // 当前教材信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text("当前教材")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            Text(preferencesManager.userPreferences.selectedTextbookVersion.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(getCurrentCourseText())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 单元网格选择
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("选择单元")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("单选模式")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(availableUnits, id: \.self) { unit in
                                UnitCard(
                                    unit: unit,
                                    isSelected: selectedUnits.contains(unit)
                                ) {
                                    toggleUnit(unit)
                                }
                            }
                        }
                    }
                    
                    // 选择总结
                    if !selectedUnits.isEmpty {
                        VStack(spacing: 12) {
                            Text("已选择学习单元")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            let sortedUnits = selectedUnits.sorted { $0.rawValue < $1.rawValue }
                            Text(sortedUnits.map { $0.displayName }.joined(separator: "、"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("背单词时将只学习该单元的内容")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 12) {
                            Text("请选择一个学习单元")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("选择一个单元开始背单词学习")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // 为按钮留空间
            }
            .navigationTitle("单元设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveSelection()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedUnits.isEmpty)
                }
            }
            .onAppear {
                selectedUnits = preferencesManager.userPreferences.selectedUnits
            }
        }
    }
    
    private func getCurrentCourseText() -> String {
        let courseType = preferencesManager.userPreferences.selectedCourseType
        switch courseType {
        case .required:
            return preferencesManager.userPreferences.selectedRequiredCourse.rawValue
        case .elective:
            return preferencesManager.userPreferences.selectedElectiveCourse.rawValue
        }
    }
    
    private func toggleUnit(_ unit: Unit) {
        // 单选模式：如果点击的是已选中的单元，则取消选择；否则选择该单元并取消其他单元
        if selectedUnits.contains(unit) {
            selectedUnits.remove(unit)
        } else {
            selectedUnits = [unit] // 只选择当前单元
        }
    }
    
    private func saveSelection() {
        preferencesManager.userPreferences.selectedUnits = selectedUnits
        dismiss()
    }
}

// MARK: - 单元卡片
struct UnitCard: View {
    let unit: Unit
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 单元数字标识
                Text("\(unit.rawValue)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                // 单元标题
                Text("单元")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .blue : .gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .blue : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览
#Preview {
    UnitSelectionView()
        .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}

import SwiftUI

struct GradeSelectionView: View {
    @Binding var userPreferences: UserPreferences
    @State private var selectedGrade: Grade
    @State private var selectedVocabularyType: VocabularyType
    @State private var showingMainApp = false
    
    init(userPreferences: Binding<UserPreferences>) {
        self._userPreferences = userPreferences
        self._selectedGrade = State(initialValue: userPreferences.wrappedValue.selectedGrade)
        self._selectedVocabularyType = State(initialValue: userPreferences.wrappedValue.selectedVocabularyType)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // 标题
                    VStack(spacing: 16) {
                        Text("英语错题本")
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        Text("基于艾宾浩斯记忆曲线的智能复习系统")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // 年级选择
                    VStack(alignment: .leading, spacing: 16) {
                        Text("选择年级")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(Grade.allCases, id: \.self) { grade in
                                GradeCard(
                                    grade: grade,
                                    isSelected: selectedGrade == grade,
                                    onTap: { selectedGrade = grade }
                                )
                            }
                        }
                    }
                    
                    // 词汇类型选择
                    VStack(alignment: .leading, spacing: 16) {
                        Text("选择词汇类型")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(VocabularyType.allCases, id: \.self) { type in
                                VocabularyTypeCard(
                                    type: type,
                                    isSelected: selectedVocabularyType == type,
                                    onTap: { selectedVocabularyType = type }
                                )
                            }
                        }
                    }
                    
                    // 按钮区域
                    VStack(spacing: 16) {
                        // 开始按钮
                        Button {
                            userPreferences.selectedGrade = selectedGrade
                            userPreferences.selectedVocabularyType = selectedVocabularyType
                            userPreferences.isFirstLaunch = false
                            showingMainApp = true
                        } label: {
                            HStack {
                                Text("开始学习")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        

                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingMainApp) {
            RootTabView()
        }
    }
}

// MARK: - 年级卡片
struct GradeCard: View {
    let grade: Grade
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(grade.englishName)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text(grade.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding()
            .frame(height: 80)
            .background(isSelected ? .blue : .gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 词汇类型卡片
struct VocabularyTypeCard: View {
    let type: VocabularyType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(type.emoji)
                    .font(.title)
                
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(height: 80)
            .background(isSelected ? .blue : .gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GradeSelectionView(userPreferences: .constant(UserPreferences()))
}

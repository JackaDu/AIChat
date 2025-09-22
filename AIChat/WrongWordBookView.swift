import SwiftUI

struct WrongWordBookView: View {
    @EnvironmentObject var manager: WrongWordManager
    @EnvironmentObject var phoneticService: PhoneticService
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @State private var showPDFExport = false
    
    // 计算未掌握和已掌握的单词
    private var unmasteredWords: [WrongWord] {
        manager.wrongWords.filter { !$0.isMastered }.sorted { $0.errorCount > $1.errorCount }
    }
    
    private var masteredWords: [WrongWord] {
        manager.wrongWords.filter { $0.isMastered }.sorted { $0.errorCount > $1.errorCount }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if manager.wrongWords.isEmpty {
                    ContentUnavailableView(
                        "暂无错题",
                        systemImage: "checkmark.circle",
                        description: Text("继续学习来收集错题吧！")
                    )
                } else {
                    // 调试信息
                    let _ = print("🔍 错词本调试信息:")
                    let _ = print("   总错词数: \(manager.wrongWords.count)")
                    let _ = print("   未掌握: \(unmasteredWords.count)")
                    let _ = print("   已掌握: \(masteredWords.count)")
                    let _ = manager.wrongWords.forEach { word in
                        print("   - \(word.word): isMastered=\(word.isMastered)")
                    }
                    List {
                        // 未掌握的错词板块
                        if !unmasteredWords.isEmpty {
                            Section {
                                ForEach(unmasteredWords) { word in
                                    WrongWordRowView(
                                        word: word,
                                        manager: manager,
                                        showMasteredAction: true
                                    )
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                    Text("需要复习 (\(unmasteredWords.count))")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        
                        // 已掌握的错词板块
                        if !masteredWords.isEmpty {
                            Section {
                                ForEach(masteredWords) { word in
                                    WrongWordRowView(
                                        word: word,
                                        manager: manager,
                                        showMasteredAction: false
                                    )
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("已掌握 (\(masteredWords.count))")
                                        .font(.headline)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("错词本")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showPDFExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(unmasteredWords.isEmpty)
                }
            }
            .sheet(isPresented: $showPDFExport) {
                SharedPDFExportView(
                    words: unmasteredWords.map { StudyWord.fromWrongWord($0) },
                    title: "错词本导出"
                )
            }
        }
    }
}

struct WrongWordRowView: View {
    let word: WrongWord
    @ObservedObject var manager: WrongWordManager
    let showMasteredAction: Bool
    @EnvironmentObject var phoneticService: PhoneticService
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @State private var dragOffset: CGFloat = 0
    @State private var showDeleteButton = false
    
    var body: some View {
        ZStack {
            // 背景删除按钮 - 仅在未掌握的单词上显示
            if showMasteredAction {
                HStack {
                    Spacer()
                    if showDeleteButton {
                        Button(action: {
                            markAsMastered()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                                Text("已掌握")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 90, height: 90)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.mint]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 16)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
            }
            
            // 主要内容卡片
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(word.word)
                            .font(.headline)
                            .foregroundStyle(word.isMastered ? .secondary : .primary)
                        
                        ClickablePhoneticView(word: word.word)
                    }
                    
                    Text(word.meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text("错误 \(word.errorCount) 次")
                            .font(.caption)
                            .foregroundStyle(.red)
                        
                        Spacer()
                        
                        Text("复习 \(word.reviewCount) 次")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        if word.isMastered {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    phoneticService.playPronunciation(for: word.word, pronunciationType: preferencesManager.userPreferences.pronunciationType) {}
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 8)
            .background(word.isMastered ? .green.opacity(0.05) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(word.isMastered ? .green.opacity(0.2) : .clear, lineWidth: 1)
            )
            .offset(x: showMasteredAction ? dragOffset : 0)
        }
        .simultaneousGesture(
            // 只有未掌握的单词才能滑动
            showMasteredAction ? DragGesture()
                .onChanged { value in
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    let isValidHorizontalSwipe = horizontalMovement > verticalMovement * 2 && horizontalMovement > 20
                    
                    if isValidHorizontalSwipe {
                        // 限制左滑距离，最多滑动120px以容纳按钮
                        if value.translation.width < 0 {
                            dragOffset = max(value.translation.width, -120)
                        } else {
                            dragOffset = value.translation.width
                        }
                        
                        // 当左滑超过60px时显示删除按钮
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showDeleteButton = dragOffset < -60
                        }
                    }
                }
                .onEnded { value in
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    let isValidHorizontalSwipe = horizontalMovement > verticalMovement * 2 && horizontalMovement > 50
                    
                    if isValidHorizontalSwipe {
                        let threshold: CGFloat = 80
                        
                        if value.translation.width < -threshold {
                            // 左滑 - 保持删除按钮显示状态
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                dragOffset = -100 // 固定在显示删除按钮的位置
                                showDeleteButton = true
                            }
                        } else {
                            // 未达到阈值，重置
                            resetOffset()
                        }
                    } else {
                        // 不符合条件，重置偏移
                        resetOffset()
                    }
                } : nil
        )
        .onTapGesture {
            // 如果删除按钮正在显示，点击卡片时隐藏删除按钮
            if showDeleteButton {
                resetOffset()
            }
        }
    }
    
    private func resetOffset() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = 0
            showDeleteButton = false
        }
    }
    
    private func markAsMastered() {
        print("✅ 标记单词为已掌握: \(word.word)")
        print("   标记前 isMastered: \(word.isMastered)")
        
        // 添加成功的触觉反馈
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        manager.markAsMastered(word)
        
        // 检查标记后的状态
        if let updatedWord = manager.wrongWords.first(where: { $0.id == word.id }) {
            print("   标记后 isMastered: \(updatedWord.isMastered)")
        }
        
        // 重置状态
        resetOffset()
    }
}

#Preview {
    WrongWordBookView()
}

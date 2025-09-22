import SwiftUI

struct UrgentReviewQuizView: View {
    @EnvironmentObject var manager: WrongWordManager
    @EnvironmentObject var wordDataManager: WordDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPreloadingOptions = false
    @State private var preloadProgress = 0.0
    @State private var showingQuizView = false
    @State private var preloadedOptions: [String: [String]] = [:]
    
    private let confusionGenerator = AIConfusionGenerator(apiKey: AppConfig.shared.openAIAPIKey)
    
    // 使用与WrongWordManager一致的紧急复习逻辑
    private var urgentWords: [WrongWord] {
        manager.todayReviewWords
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                if urgentWords.isEmpty {
                    // 没有紧急单词
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        
                        VStack(spacing: 12) {
                            Text("太棒了！")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("暂无需要紧急复习的错词")
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Text("基于艾宾浩斯遗忘曲线，所有错词都在最佳复习时间范围内")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // 说明卡片
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("科学复习系统")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("根据记忆衰减规律，自动计算最佳复习时间")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("专注错词复习")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("只复习错题本中的单词，不包含新词学习")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                } else {
                    // 详细的紧急复习信息
                    VStack(spacing: 24) {
                        // 标题和图标
                        HStack {
                            Image(systemName: "alarm.fill")
                                .foregroundStyle(.red)
                                .font(.title2)
                            
                            Text("紧急复习")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        // 主要信息
                        VStack(spacing: 8) {
                            Text("\(urgentWords.count) 个错词需要复习")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Text("基于艾宾浩斯遗忘曲线科学推算")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .fontWeight(.medium)
                        }
                        
                        // 详细说明卡片
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("科学复习原理")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("根据记忆衰减规律，在遗忘前及时巩固")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("仅复习错词")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("不包含新词，专注巩固已学过的错词")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("复习间隔")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("1天→2天→4天→7天→15天→30天→60天")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
                
                if !urgentWords.isEmpty {
                    // 简化的开始按钮
                    Button {
                        startPreloadingOptions()
                    } label: {
                        HStack(spacing: 12) {
                            if isPreloadingOptions {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16))
                            }
                            
                            Text(isPreloadingOptions ? "准备中..." : "开始复习")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isPreloadingOptions ? .gray : .red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isPreloadingOptions)
                    .padding(.horizontal, 40)
                    
                    // 简化的进度显示
                    if isPreloadingOptions {
                        Text("正在准备测试...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingQuizView) {
            WrongWordQuizView(filterWords: urgentWords, preloadedOptions: preloadedOptions)
                .environmentObject(manager)
        }
    }
    
    // MARK: - 预加载选项
    private func startPreloadingOptions() {
        guard !urgentWords.isEmpty else { return }
        
        isPreloadingOptions = true
        preloadProgress = 0.0
        preloadedOptions.removeAll()
        
        Task {
            // 为每个紧急单词预生成选项
            for (index, word) in urgentWords.enumerated() {
                do {
                    let preGeneratedOptions = self.getPreGeneratedOptions(for: word, learningDirection: word.learningDirection)
                    let options = try await confusionGenerator.generateConfusionOptions(
                        for: word.learningDirection == .recognizeMeaning ? word.word : word.meaning,
                        correctAnswer: word.learningDirection == .recognizeMeaning ? word.meaning : word.word,
                        learningDirection: word.learningDirection,
                        textbook: word.textbookSource?.textbookVersion.rawValue,
                        coursebook: word.textbookSource?.courseBook,
                        unit: word.textbookSource?.unit.shortName,
                        phonetic: PhoneticService().getPhoneticSymbol(for: word.word),
                        partOfSpeech: word.partOfSpeech?.rawValue,
                        preGeneratedOptions: preGeneratedOptions
                    )
                    
                    // 保存生成的选项
                    await MainActor.run {
                        preloadedOptions[word.word] = options
                        preloadProgress = Double(index + 1) / Double(urgentWords.count)
                    }
                    
                    // 添加小延迟，让用户看到进度
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                    
                } catch {
                    print("预生成选项失败: \(error)")
                    // 生成失败时使用备用选项
                    await MainActor.run {
                        preloadedOptions[word.word] = generateFallbackOptions(for: word)
                        preloadProgress = Double(index + 1) / Double(urgentWords.count)
                    }
                }
            }
            
            // 预加载完成，显示测试界面
            await MainActor.run {
                isPreloadingOptions = false
                showingQuizView = true
            }
        }
    }
    
    // MARK: - 生成备用选项
    private func generateFallbackOptions(for word: WrongWord) -> [String] {
        var options = [word.meaning]
        
        // 从其他错题中随机选择3个作为干扰选项
        let otherWords = manager.wrongWords.filter { $0.word != word.word }
        let randomOptions = otherWords.shuffled().prefix(3).map { $0.meaning }
        options.append(contentsOf: randomOptions)
        
        // 如果选项不够4个，添加一些通用干扰选项
        while options.count < 4 {
            let genericOptions = ["不知道", "其他选项", "无法确定", "不清楚"]
            for option in genericOptions {
                if !options.contains(option) && options.count < 4 {
                    options.append(option)
                }
            }
        }
        
        return options.shuffled()
    }
    
    // MARK: - 获取Excel预生成选项
    // 直接使用WrongWord中的预生成选项
    private func getPreGeneratedOptions(for word: WrongWord, learningDirection: LearningDirection) -> [String]? {
        print("🔍 获取单词预生成选项: \(word.word) - \(word.meaning)")
        
        // 根据学习方向返回对应的预生成选项
        let misleadingOptions: [String]
        switch learningDirection {
        case .recognizeMeaning:
            misleadingOptions = word.misleadingChineseOptions
        case .recallWord:
            misleadingOptions = word.misleadingEnglishOptions
        case .dictation:
            return nil
        }
        
        // 检查选项是否为空
        guard !misleadingOptions.isEmpty else {
            print("⚠️ 单词 \(word.word) 的预生成选项为空")
            return nil
        }
        
        print("✅ 找到单词 \(word.word) 的预生成选项: \(misleadingOptions)")
        
        // 构建完整的选项列表（包含正确答案）
        let correctAnswer = learningDirection == .recognizeMeaning ? word.meaning : word.word
        var allOptions = misleadingOptions
        
        // 确保正确答案包含在选项中
        if !allOptions.contains(correctAnswer) {
            allOptions.append(correctAnswer)
        }
        
        // 打乱顺序并限制为4个选项
        return Array(allOptions.shuffled().prefix(4))
    }
}

#Preview {
    UrgentReviewQuizView()
        .environmentObject(WrongWordManager())
}

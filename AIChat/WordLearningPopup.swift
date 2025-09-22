import SwiftUI

struct WordLearningPopup: View {
    let word: WrongWord
    @Environment(\.dismiss) private var dismiss
    @StateObject private var phoneticService = PhoneticService()
    @StateObject private var wordAnalysisService = WordAnalysisService()
    
    // 学习状态
    @State private var currentStep = 0
    @State private var showingPhonetic = false
    @State private var showingTranslation = false
    @State private var showingSpelling = false
    @State private var showingWordAnalysis = false
    @State private var showingExamples = false
    
    // 学习进度节点
    private let learningSteps = ["听说", "学", "选", "拆分", "拼读", "拼写"]
    
    // 单词分析数据
    @State private var wordAnalysis: WordAnalysis?
    @State private var isLoadingAnalysis = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("学练一体 (\(currentStep + 1)/\(learningSteps.count))")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button {
                        // 收藏功能
                    } label: {
                        Image(systemName: "star")
                            .foregroundStyle(.yellow)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // 学习进度条
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        ForEach(0..<learningSteps.count, id: \.self) { index in
                            HStack(spacing: 0) {
                                // 节点
                                ZStack {
                                    Circle()
                                        .fill(index <= currentStep ? .green : .white)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(.green, lineWidth: 2)
                                        )
                                    
                                    if index < currentStep {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(index <= currentStep ? .white : .green)
                                    }
                                }
                                
                                // 连接线
                                if index < learningSteps.count - 1 {
                                    Rectangle()
                                        .fill(index < currentStep ? .green : .gray.opacity(0.3))
                                        .frame(height: 2)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    
                    // 步骤标签
                    HStack(spacing: 0) {
                        ForEach(0..<learningSteps.count, id: \.self) { index in
                            Text(learningSteps[index])
                                .font(.caption)
                                .foregroundStyle(index <= currentStep ? .green : .secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 主要内容卡片
                ScrollView {
                    VStack(spacing: 24) {
                        // 单词卡片
                        VStack(spacing: 20) {
                            // 单词显示（带音节拆分）
                            VStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    Text("pen")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.gray.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text("cil")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.gray.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Text(word.word)
                                    .font(.system(size: 48, weight: .bold, design: .default))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // 音标和发音
                            HStack {
                                Text("[\(phoneticService.getPhoneticSymbol(for: word.word))]")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                
                                Button {
                                    phoneticService.playPronunciation(for: word.word) {}
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            
                            // 词性和中文意思
                            VStack(spacing: 8) {
                                Text("n. \(word.meaning)")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                            
                            // 词根助记（如果有）
                            if let analysis = wordAnalysis, !analysis.etymology.isEmpty {
                                VStack(spacing: 8) {
                                    Text("词根助记")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(analysis.etymology)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.orange.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            // 功能按钮行
                            HStack(spacing: 12) {
                                Button {
                                    showingTranslation.toggle()
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("完整翻译")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Button {
                                    showingWordAnalysis.toggle()
                                } label: {
                                    HStack {
                                        Image(systemName: "brain.head.profile")
                                        Text("词根分析")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.green.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Button {
                                    showingExamples.toggle()
                                } label: {
                                    HStack {
                                        Image(systemName: "text.quote")
                                        Text("高考例句")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.purple.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(24)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // 学习按钮
                        HStack(spacing: 16) {
                            Button {
                                showingPhonetic.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: "waveform")
                                    Text("拆分发音")
                                }
                                .font(.headline)
                                .foregroundStyle(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.purple, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            Button {
                                showingSpelling.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: "textformat.abc")
                                    Text("自然拼读")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        // 字母音标网格
                        VStack(spacing: 16) {
                            Text("字母音标对照")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(Array(word.word.enumerated()), id: \.offset) { index, char in
                                    VStack(spacing: 4) {
                                        Text(String(char))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                        
                                        Text(getPhoneticForChar(char, at: index, in: word.word))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(8)
                                    .background(.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(20)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        // 加强学习按钮
                        Button {
                            // 进入加强学习模式
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("加强学习")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.purple, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple.opacity(0.1), .blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .sheet(isPresented: $showingPhonetic) {
            PhoneticLearningView(word: word, phoneticService: phoneticService)
        }
        .sheet(isPresented: $showingTranslation) {
            TranslationDetailView(word: word)
        }
        .sheet(isPresented: $showingSpelling) {
            SpellingLearningView(word: word, phoneticService: phoneticService)
        }
        .sheet(isPresented: $showingWordAnalysis) {
            WordAnalysisView(word: word, wordAnalysis: wordAnalysis)
        }
        .sheet(isPresented: $showingExamples) {
            ExamplesView(word: word, wordAnalysis: wordAnalysis)
        }
        .onAppear {
            // 自动播放发音
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                phoneticService.playPronunciation(for: word.word) {}
            }
            
            // 加载单词分析数据
            loadWordAnalysis()
        }
    }
    
    // 加载单词分析数据
    private func loadWordAnalysis() {
        isLoadingAnalysis = true
        Task {
            do {
                let analysis = try await wordAnalysisService.analyzeWord(word.word)
                await MainActor.run {
                    self.wordAnalysis = analysis
                    self.isLoadingAnalysis = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingAnalysis = false
                }
            }
        }
    }
    
    // 获取字母对应的音标
    private func getPhoneticForChar(_ char: Character, at index: Int, in word: String) -> String {
        let charStr = String(char).lowercased()
        
        // 简单的音标映射（实际应用中可以使用更复杂的规则）
        switch charStr {
        case "a": return "/æ/"
        case "e": return "/e/"
        case "i": return "/ɪ/"
        case "o": return "/ɒ/"
        case "u": return "/ʌ/"
        case "p": return "/p/"
        case "b": return "/b/"
        case "t": return "/t/"
        case "d": return "/d/"
        case "k": return "/k/"
        case "g": return "/g/"
        case "f": return "/f/"
        case "v": return "/v/"
        case "s": return "/s/"
        case "z": return "/z/"
        case "m": return "/m/"
        case "n": return "/n/"
        case "l": return "/l/"
        case "r": return "/r/"
        case "h": return "/h/"
        case "w": return "/w/"
        case "j": return "/j/"
        case "c": return "/s/"
        case "q": return "/kw/"
        case "x": return "/ks/"
        default: return "/\(charStr)/"
        }
    }
}

// MARK: - 单词分析视图
struct WordAnalysisView: View {
    let word: WrongWord
    let wordAnalysis: WordAnalysis?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let analysis = wordAnalysis {
                        // 词根分析
                        VStack(spacing: 16) {
                            Text("词根分析")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 12) {
                                if !analysis.etymology.isEmpty {
                                    InfoCard(title: "词源", content: analysis.etymology, color: .orange)
                                }
                                
                                if !analysis.root.isEmpty {
                                    InfoCard(title: "词根", content: analysis.root, color: .blue)
                                }
                                
                                if !analysis.prefix.isEmpty {
                                    InfoCard(title: "前缀", content: analysis.prefix, color: .green)
                                }
                                
                                if !analysis.suffix.isEmpty {
                                    InfoCard(title: "后缀", content: analysis.suffix, color: .purple)
                                }
                            }
                        }
                        
                        // 语法变形
                        VStack(spacing: 16) {
                            Text("语法变形")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                if !analysis.plural.isEmpty {
                                    InfoCard(title: "复数", content: analysis.plural, color: .indigo)
                                }
                                
                                if !analysis.pastTense.isEmpty {
                                    InfoCard(title: "过去式", content: analysis.pastTense, color: .red)
                                }
                                
                                if !analysis.presentParticiple.isEmpty {
                                    InfoCard(title: "现在分词", content: analysis.presentParticiple, color: .teal)
                                }
                                
                                if !analysis.pastParticiple.isEmpty {
                                    InfoCard(title: "过去分词", content: analysis.pastParticiple, color: .brown)
                                }
                                
                                if !analysis.gerund.isEmpty {
                                    InfoCard(title: "动名词", content: analysis.gerund, color: .pink)
                                }
                            }
                        }
                        
                        // 相关词汇
                        if !analysis.relatedWords.isEmpty {
                            VStack(spacing: 16) {
                                Text("相关词汇")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(analysis.relatedWords, id: \.self) { relatedWord in
                                        Text(relatedWord)
                                            .font(.body)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(.blue.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    } else {
                        ProgressView("正在分析单词...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
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

// MARK: - 例句视图
struct ExamplesView: View {
    let word: WrongWord
    let wordAnalysis: WordAnalysis?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    if let analysis = wordAnalysis {
                        ExamExamplesSection(analysis: analysis)
                        PracticalExamplesSection(analysis: analysis)
                        GrammarUsageSection(analysis: analysis)
                    } else {
                        ProgressView("正在加载例句...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
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

// MARK: - 例句视图分解组件
struct ExamExamplesSection: View {
    let analysis: WordAnalysis
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                
                Text("高考真题例句")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            if !analysis.examExamples.isEmpty {
                ForEach(Array(analysis.examExamples.enumerated()), id: \.offset) { index, example in
                    EnhancedExamExampleCard(example: example, index: index + 1)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    
                    Text("暂无高考真题例句")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("这个单词还没有高考真题例句")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PracticalExamplesSection: View {
    let analysis: WordAnalysis
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text("实用例句")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            if !analysis.practicalExamples.isEmpty {
                ForEach(Array(analysis.practicalExamples.enumerated()), id: \.offset) { index, example in
                    EnhancedPracticalExampleCard(example: example, index: index + 1)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    
                    Text("暂无实用例句")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("这个单词还没有实用例句")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct GrammarUsageSection: View {
    let analysis: WordAnalysis
    
    var body: some View {
        if !analysis.grammarUsage.isEmpty {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    Text("语法用法")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                ForEach(analysis.grammarUsage, id: \.self) { usage in
                    EnhancedGrammarUsageCard(usage: usage)
                }
            }
            .padding(20)
            .background(.green.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.green.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - 辅助视图组件
struct InfoCard: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 增强的例句卡片组件
struct EnhancedExamExampleCard: View {
    let example: ExamExample
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部信息
            HStack(spacing: 12) {
                Text("例\(index)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(example.year)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(example.province)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
            }
            
            // 例句内容
            Text(example.sentence)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            // 翻译
            if !example.translation.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("翻译")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(example.translation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineSpacing(2)
                }
            }
        }
        .padding(20)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

struct EnhancedPracticalExampleCard: View {
    let example: PracticalExample
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部信息
            HStack(spacing: 12) {
                Text("例\(index)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(example.category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
            }
            
            // 例句内容
            Text(example.sentence)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            // 翻译
            if !example.translation.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("翻译")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(example.translation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineSpacing(2)
                }
            }
        }
        .padding(20)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

struct EnhancedGrammarUsageCard: View {
    let usage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                
                Text("语法要点")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Text(usage)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}


struct ExamExampleCard: View {
    let example: ExamExample
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("例\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Text(example.year)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(example.province)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            
            Text(example.sentence)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            if !example.translation.isEmpty {
                Text(example.translation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(.red.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PracticalExampleCard: View {
    let example: PracticalExample
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("例\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Text(example.category)
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                Spacer()
            }
            
            Text(example.sentence)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            if !example.translation.isEmpty {
                Text(example.translation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(.blue.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 拆分发音学习视图
struct PhoneticLearningView: View {
    let word: WrongWord
    let phoneticService: PhoneticService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("拆分发音学习")
                    .font(.title)
                    .fontWeight(.bold)
                
                // 音节拆分
                VStack(spacing: 16) {
                    Text("音节拆分")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        ForEach(splitIntoSyllables(word.word), id: \.self) { syllable in
                            VStack(spacing: 8) {
                                Text(syllable)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Button {
                                    // 播放音节发音
                                } label: {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                            .background(.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
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
    }
    
    private func splitIntoSyllables(_ word: String) -> [String] {
        // 简单的音节拆分逻辑
        if word.count <= 3 {
            return [word]
        } else if word.count == 4 {
            let mid = word.index(word.startIndex, offsetBy: 2)
            return [String(word[..<mid]), String(word[mid...])]
        } else {
            let mid = word.index(word.startIndex, offsetBy: word.count / 2)
            return [String(word[..<mid]), String(word[mid...])]
        }
    }
}

// MARK: - 完整翻译视图
struct TranslationDetailView: View {
    let word: WrongWord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("完整翻译")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text(word.word)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(word.meaning)
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    if !word.context.isEmpty {
                        Text("例句：\(word.context)")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
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
    }
}

// MARK: - 拼读学习视图
struct SpellingLearningView: View {
    let word: WrongWord
    let phoneticService: PhoneticService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("自然拼读学习")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text("跟着发音练习拼读")
                        .font(.headline)
                    
                    Button {
                        phoneticService.playPronunciation(for: word.word) {}
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("播放发音")
                        }
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
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
    }
}

#Preview {
    WordLearningPopup(word: WrongWord(
        word: "pencil",
        meaning: "铅笔",
        context: "This is a pencil.",
        learningDirection: .recognizeMeaning
    ))
}

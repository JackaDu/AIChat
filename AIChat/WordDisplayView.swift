import SwiftUI

// MARK: - 通用单词显示组件
struct WordDisplayView: View {
    let word: WrongWord
    let showPhonetic: Bool
    let showPartOfSpeech: Bool
    let fontSize: Font
    let textColor: Color
    let showPlayButton: Bool
    
    @StateObject private var phoneticService = PhoneticService()
    
    init(
        word: WrongWord,
        showPhonetic: Bool = true,
        showPartOfSpeech: Bool = true,
        fontSize: Font = .title2,
        textColor: Color = .primary,
        showPlayButton: Bool = true
    ) {
        self.word = word
        self.showPhonetic = showPhonetic
        self.showPartOfSpeech = showPartOfSpeech
        self.fontSize = fontSize
        self.textColor = textColor
        self.showPlayButton = showPlayButton
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 单词和词性
            HStack(spacing: 8) {
                Text(word.word)
                    .font(fontSize)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor)
                
                if showPartOfSpeech, let partOfSpeech = word.partOfSpeech {
                    PartOfSpeechBadge(partOfSpeech: partOfSpeech)
                }
            }
            
            // 音标和发音按钮
            if showPhonetic {
                HStack(spacing: 8) {
                    Text("[\(phoneticService.getPhoneticSymbol(for: word.word))]")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if showPlayButton {
                        Button {
                            phoneticService.playPronunciation(for: word.word) {}
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - 词性标签
struct PartOfSpeechBadge: View {
    let partOfSpeech: PartOfSpeech
    
    var body: some View {
        Text(partOfSpeech.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(partOfSpeech.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 紧凑版单词显示（用于列表）
struct CompactWordDisplayView: View {
    let word: WrongWord
    let showPhonetic: Bool
    
    @StateObject private var phoneticService = PhoneticService()
    
    init(word: WrongWord, showPhonetic: Bool = false) {
        self.word = word
        self.showPhonetic = showPhonetic
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 单词
            Text(word.word)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            // 词性
            if let partOfSpeech = word.partOfSpeech {
                PartOfSpeechBadge(partOfSpeech: partOfSpeech)
            }
            
            Spacer()
            
            // 音标（可选）
            if showPhonetic {
                Text("[\(phoneticService.getPhoneticSymbol(for: word.word))]")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - 卡片版单词显示
struct CardWordDisplayView: View {
    let word: WrongWord
    let showDifficulty: Bool
    
    @StateObject private var phoneticService = PhoneticService()
    
    init(word: WrongWord, showDifficulty: Bool = true) {
        self.word = word
        self.showDifficulty = showDifficulty
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 单词和词性
            HStack(spacing: 8) {
                Text(word.word)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                if let partOfSpeech = word.partOfSpeech {
                    PartOfSpeechBadge(partOfSpeech: partOfSpeech)
                }
            }
            
            // 音标和发音
            HStack(spacing: 8) {
                Text("[\(phoneticService.getPhoneticSymbol(for: word.word))]")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button {
                    phoneticService.playPronunciation(for: word.word) {}
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 难度标签（可选）
            if showDifficulty {
                DifficultyBadge(difficulty: word.difficulty)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
    }
}

// MARK: - 难度标签
struct DifficultyBadge: View {
    let difficulty: WordDifficulty
    
    var body: some View {
        HStack(spacing: 4) {
            Text(difficulty.emoji)
                .font(.caption)
            
            Text(difficulty.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(difficulty.color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 学习模式单词显示
struct LearningWordDisplayView: View {
    let word: WrongWord
    let learningDirection: LearningDirection
    let showHint: Bool
    
    @StateObject private var phoneticService = PhoneticService()
    
    init(word: WrongWord, learningDirection: LearningDirection, showHint: Bool = false) {
        self.word = word
        self.learningDirection = learningDirection
        self.showHint = showHint
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 学习方向提示
            HStack {
                Text(learningDirection.emoji)
                    .font(.title2)
                
                Text(learningDirection.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            // 单词显示
            VStack(spacing: 8) {
                Text(word.word)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                if let partOfSpeech = word.partOfSpeech {
                    PartOfSpeechBadge(partOfSpeech: partOfSpeech)
                }
                
                Text("[\(phoneticService.getPhoneticSymbol(for: word.word))]")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Button {
                    phoneticService.playPronunciation(for: word.word) {}
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 提示信息（可选）
            if showHint {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    
                    Text("点击播放按钮听发音")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
    }
}

// MARK: - 复习模式单词显示
struct ReviewWordDisplayView: View {
    let word: WrongWord
    let showAnswer: Bool
    
    @StateObject private var phoneticService = PhoneticService()
    
    init(word: WrongWord, showAnswer: Bool = false) {
        self.word = word
        self.showAnswer = showAnswer
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 单词
            Text(word.word)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // 词性和音标
            HStack(spacing: 12) {
                if let partOfSpeech = word.partOfSpeech {
                    PartOfSpeechBadge(partOfSpeech: partOfSpeech)
                }
                
                Text("[\(phoneticService.getPhoneticSymbol(for: word.word))]")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Button {
                    phoneticService.playPronunciation(for: word.word) {}
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 答案（可选）
            if showAnswer {
                VStack(spacing: 8) {
                    Divider()
                    
                    Text("释义")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(word.meaning)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 创建测试数据
        let sampleTextbookSource = TextbookSource(
            courseType: .required,
            courseBook: "必修1",
            unit: .unit1,
            textbookVersion: .renjiao
        )
        
        let testWord = WrongWord(
            word: "beautiful",
            meaning: "美丽的",
            context: "She is a beautiful girl.",
            learningDirection: .recognizeMeaning,
            textbookSource: sampleTextbookSource,
            partOfSpeech: .adjective,
            examSource: .gaokao,
            difficulty: .medium
        )
        
        WordDisplayView(word: testWord)
        
        CompactWordDisplayView(word: testWord, showPhonetic: true)
        
        CardWordDisplayView(word: testWord)
        
        LearningWordDisplayView(word: testWord, learningDirection: .recognizeMeaning, showHint: true)
        
        ReviewWordDisplayView(word: testWord, showAnswer: true)
    }
    .padding()
}

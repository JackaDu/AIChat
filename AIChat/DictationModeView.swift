import SwiftUI

// MARK: - 听写模式视图
struct DictationModeView: View {
    let word: StudyWord
    let onAnswer: (Bool) -> Void
    @ObservedObject var phoneticService: PhoneticService
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    
    @State private var userInput: String = ""
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    @State private var hasSubmitted: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var showSettings: Bool = false
    @State private var showHint: Bool = false
    @State private var delayedNextWordTask: DispatchWorkItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部设置按钮 - 更紧凑的布局
            HStack {
                Spacer()
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Spacer()
            
            // 中文含义显示 - 调整字体大小和间距
            Text(word.meaning)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .lineLimit(3)
            
            Spacer().frame(height: 40)
            
            // 发音按钮 - 更紧凑的设计
            Button(action: {
                playPronunciation()
            }) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(.blue)
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.2), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 小提示按钮
            if !hasSubmitted {
                Button(action: {
                    if preferencesManager.userPreferences.dictationShowUnderlines {
                        // 下划线模式：在下划线中显示第一个字母
                        showHint = true
                    } else {
                        // 隐藏下划线模式：直接显示第一个字母提示
                        let firstLetter = getFirstLetterFromCurrentWord()
                        if !firstLetter.isEmpty && userInput.isEmpty {
                            userInput = firstLetter
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                        Text("小提示")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 16)
            }
            
            Spacer().frame(height: 40)
            
            // 下划线输入区域 - 减少间距
            VStack(spacing: 24) {
                // 根据用户设置决定是否显示下划线
                if preferencesManager.userPreferences.dictationShowUnderlines {
                    // 显示下划线模式
                    UnderlineInputView(
                        targetWord: word.word,
                        userInput: userInput,
                        hasSubmitted: hasSubmitted,
                        isCorrect: isCorrect,
                        showHint: showHint
                    )
                } else {
                    // 隐藏下划线模式 - 显示带空格的输入模板
                    VStack(spacing: 16) {
                        // 显示当前输入的内容，保留空格等特殊字符
                        Text(getNoUnderlineDisplayText())
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(userInput.isEmpty ? .secondary : .primary)
                            .frame(minHeight: 40)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // 显示提示信息
                        Text("无长度提示 - 挑战模式")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 隐藏的输入框（用于接收键盘输入）
                TextField("", text: $userInput)
                    .opacity(0)
                    .frame(height: 1)
                    .focused($isTextFieldFocused)
                    .keyboardType(.asciiCapable) // 只允许ASCII字符，禁用中文输入
                    .textCase(.lowercase) // 强制小写
                    .autocorrectionDisabled() // 禁用自动纠错
                    .textInputAutocapitalization(.never) // 禁用自动大写
                    .disableAutocorrection(true) // 额外确保禁用自动纠错
                    .textContentType(.none) // 禁用文本内容类型推断
                    .onChange(of: userInput) { _, newValue in
                        // 如果已经提交答案，不允许继续输入
                        if hasSubmitted {
                            userInput = ""
                            return
                        }
                        
                        // 确保输入始终是小写字母，过滤特殊字符
                        let filteredValue = newValue.lowercased().filter { $0.isLetter }
                        if filteredValue != newValue {
                            userInput = filteredValue
                        }
                    }
                    .onSubmit {
                        if !hasSubmitted {
                            submitAnswer()
                        } else if showResult {
                            // 答错显示正确答案后，按回车继续下一题
                            // 取消延迟任务，避免重复调用nextWord()
                            delayedNextWordTask?.cancel()
                            delayedNextWordTask = nil
                            nextWord()
                        }
                    }
                    .disabled(false) // 始终保持输入框可用，以便接收回车键
                
                // 提示文字：按回车进入下一个单词 - 更简洁的提示
                if !userInput.isEmpty || showResult {
                    Text("按回车继续")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                }
            }
            
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            // 点击任意位置聚焦输入框
            isTextFieldFocused = true
        }
        .overlay {
            // 反馈结果显示（反馈模式下或答错时显示）
            if showResult && (preferencesManager.userPreferences.dictationShowFeedback || !isCorrect) {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(isCorrect ? .green : .red)
                            
                            Text(isCorrect ? "正确！" : "答案错误")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(isCorrect ? .green : .red)
                        }
                        
                        if !isCorrect {
                            VStack(spacing: 12) {
                                Text("正确答案:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(word.word)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                // 显示中文含义
                                Text(word.meaning)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // 添加按回车继续的提示
                        HStack(spacing: 6) {
                            Image(systemName: "return")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("按回车继续")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 10)
                }
            }
        }
        .onAppear {
            // 重新启用音频播放
            phoneticService.resumeAudio()
            
            // 只在第一次出现时播放发音
            if !hasSubmitted && userInput.isEmpty {
                // 自动播放发音
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playPronunciation()
                }
            }
            
            // 自动聚焦输入框，延迟时间减少以提高响应速度
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
        .sheet(isPresented: $showSettings) {
            DictationSettingsView()
                .environmentObject(preferencesManager)
        }
        .onDisappear {
            // 视图消失时停止所有音频播放
            phoneticService.stopAllAudio()
            // 取消延迟任务
            delayedNextWordTask?.cancel()
            delayedNextWordTask = nil
        }
    }
    
    // 播放发音
    private func playPronunciation() {
        let voiceMode = preferencesManager.userPreferences.dictationVoiceMode
        
        switch voiceMode {
        case .english:
            // 播放英文发音
            phoneticService.playPronunciation(
                for: word.word,
                pronunciationType: preferencesManager.userPreferences.pronunciationType
            ) {}
            print("🔊 播放英文发音: \(word.word)")
            
        case .chinese:
            // 播放中文含义（使用系统TTS）
            playChineseMeaning()
            print("🔊 播放中文含义: \(word.meaning)")
            
        case .none:
            // 不播放声音
            print("🔇 静音模式，不播放声音")
        }
    }
    
    // 播放中文含义
    private func playChineseMeaning() {
        // 使用系统的文本转语音播放中文含义
        phoneticService.playChineseText(word.meaning)
    }
    
    // 判断字符是否为特殊符号（不需要用户输入）
    private func isSpecialCharacter(_ char: Character) -> Bool {
        let specialChars: Set<Character> = [" ", ".", ",", "-", "'", ":", ";", "!", "?", "(", ")", "[", "]", "{", "}", "/", "\\", "&", "@", "#", "$", "%", "^", "*", "+", "=", "_", "~", "`"]
        return specialChars.contains(char)
    }
    
    // 获取需要用户输入的字符（过滤掉特殊符号）
    private func getInputRequiredChars() -> [Character] {
        return Array(word.word.lowercased()).filter { !isSpecialCharacter($0) }
    }
    
    // 提交答案
    private func submitAnswer() {
        guard !userInput.isEmpty && !hasSubmitted else { return }
        
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // 只比较需要用户输入的字符（过滤掉特殊符号）
        let correctInputChars = getInputRequiredChars().map { String($0) }.joined()
        
        isCorrect = trimmedInput == correctInputChars
        hasSubmitted = true
        
        print("📝 听写模式答题:")
        print("- 完整单词: \(word.word)")
        print("- 需要输入的字符: \(correctInputChars)")
        print("- 用户输入: \(userInput)")
        print("- 结果: \(isCorrect ? "正确" : "错误")")
        
        // 根据用户设置和答题结果决定是否显示反馈
        if preferencesManager.userPreferences.dictationShowFeedback || !isCorrect {
            // 显示反馈模式：显示结果，延迟后进入下一个单词
            // 或者答错时：总是显示正确答案
            showResult = true
            
            // 确保输入框保持焦点，以便用户按回车继续
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
            
            // 延迟时间：反馈模式1.5秒，答错时2.5秒（给更多时间学习）
            let delayTime = preferencesManager.userPreferences.dictationShowFeedback ? 1.5 : (isCorrect ? 0 : 2.5)
            
            // 创建可取消的延迟任务
            let task = DispatchWorkItem {
                nextWord()
            }
            delayedNextWordTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime, execute: task)
        } else {
            // 快速模式且答对：直接进入下一个单词，不显示结果
            nextWord()
        }
    }
    
    // 下一个单词
    private func nextWord() {
        // 保存当前结果
        let currentResult = isCorrect
        
        // 重置所有状态
        userInput = ""
        hasSubmitted = false
        showResult = false
        isCorrect = false
        showHint = false
        
        // 清理延迟任务
        delayedNextWordTask?.cancel()
        delayedNextWordTask = nil
        
        // 重置输入焦点，解决第一个字母需要按2遍的问题
        isTextFieldFocused = false
        
        // 调用回调，传递正确的结果
        onAnswer(currentResult)
        
        // 延迟重新聚焦，确保输入系统正确重置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }
    
    // 获取当前单词的第一个字母（用于提示）
    private func getFirstLetterFromCurrentWord() -> String {
        for char in Array(word.word.lowercased()) {
            if !isSpecialCharacter(char) {
                return String(char)
            }
        }
        return ""
    }
    
    // 获取无下划线模式的显示文本（保留空格等特殊字符）
    private func getNoUnderlineDisplayText() -> String {
        if userInput.isEmpty {
            return "开始输入..."
        }
        
        let targetChars = Array(word.word.lowercased())
        let inputChars = Array(userInput.lowercased())
        var result = ""
        var inputIndex = 0
        
        for char in targetChars {
            if isSpecialCharacter(char) {
                // 直接显示特殊字符（空格、标点等）
                result += String(char)
            } else {
                // 对于字母，如果用户已输入则显示，否则显示占位符
                if inputIndex < inputChars.count {
                    result += String(inputChars[inputIndex])
                    inputIndex += 1
                } else {
                    // 用户还未输入到这个位置，不显示任何内容
                    break
                }
            }
        }
        
        return result
    }
}

// MARK: - 听写设置视图
struct DictationSettingsView: View {
    @EnvironmentObject var preferencesManager: UserPreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("听写模式设置")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("选择您偏好的听写体验模式")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 24) {
                    // 反馈模式设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("反馈模式")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            // 快速模式
                            SettingOptionCard(
                                title: "快速模式",
                                description: "答题后立即进入下一个单词，追求速度",
                                icon: "bolt.fill",
                                iconColor: .orange,
                                isSelected: !preferencesManager.userPreferences.dictationShowFeedback
                            ) {
                                preferencesManager.userPreferences.dictationShowFeedback = false
                            }
                            
                            // 反馈模式
                            SettingOptionCard(
                                title: "反馈模式",
                                description: "显示答对/答错结果，帮助学习",
                                icon: "checkmark.circle.fill",
                                iconColor: .green,
                                isSelected: preferencesManager.userPreferences.dictationShowFeedback
                            ) {
                                preferencesManager.userPreferences.dictationShowFeedback = true
                            }
                        }
                    }
                    
                    // 语音播报设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("语音播报")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(DictationVoiceMode.allCases, id: \.self) { mode in
                                SettingOptionCard(
                                    title: mode.displayName,
                                    description: getVoiceModeDescription(mode),
                                    icon: mode.icon,
                                    iconColor: mode.iconColor,
                                    isSelected: preferencesManager.userPreferences.dictationVoiceMode == mode
                                ) {
                                    preferencesManager.userPreferences.dictationVoiceMode = mode
                                }
                            }
                        }
                    }
                    
                    // 下划线显示设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("难度设置")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            // 显示下划线
                            SettingOptionCard(
                                title: "显示下划线",
                                description: "显示单词长度提示，适合初学者",
                                icon: "underline",
                                iconColor: .blue,
                                isSelected: preferencesManager.userPreferences.dictationShowUnderlines
                            ) {
                                preferencesManager.userPreferences.dictationShowUnderlines = true
                            }
                            
                            // 隐藏下划线
                            SettingOptionCard(
                                title: "隐藏下划线",
                                description: "不显示单词长度提示，更有挑战性",
                                icon: "eye.slash.fill",
                                iconColor: .red,
                                isSelected: !preferencesManager.userPreferences.dictationShowUnderlines
                            ) {
                                preferencesManager.userPreferences.dictationShowUnderlines = false
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("听写设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // 获取语音模式描述
    private func getVoiceModeDescription(_ mode: DictationVoiceMode) -> String {
        switch mode {
        case .english:
            return "播报英文单词发音，帮助记忆"
        case .chinese:
            return "播报中文含义，加深理解"
        case .none:
            return "静音模式，专注拼写练习"
        }
    }
}

// MARK: - 设置选项卡片
struct SettingOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding(16)
            .background(isSelected ? .blue.opacity(0.1) : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 下划线输入视图
struct UnderlineInputView: View {
    let targetWord: String
    let userInput: String
    let hasSubmitted: Bool
    let isCorrect: Bool
    let showHint: Bool
    
    @State private var cursorVisible = true
    private let maxLettersPerRow = 8 // 每行最多8个字母
    
    var body: some View {
        VStack(spacing: 16) {
            // 将字母分组，每行最多8个
            ForEach(letterRows, id: \.0) { rowIndex, letters in
                HStack(spacing: 8) {
                    ForEach(letters, id: \.0) { letterIndex, _ in
                        let targetChar = Array(targetWord.lowercased())[letterIndex]
                        let userChar = getUserInputAtPosition(letterIndex)
                        let isSpecial = isSpecialCharacter(targetChar)
                        let isCurrentPosition = !isSpecial && letterIndex == getCurrentInputPosition() && !hasSubmitted
                        
                        VStack(spacing: 8) {
                            // 显示用户输入的字母、光标或特殊符号
                            ZStack {
                                // 特殊符号直接显示，用户输入的字母显示输入内容
                                if isSpecial {
                                    Text(String(targetChar))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(.primary)
                                } else {
                                    // 显示用户输入、提示或空白
                                    let displayText = getDisplayText(targetChar: targetChar, userChar: userChar, letterIndex: letterIndex)
                                    Text(displayText)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(getLetterColor(targetChar: targetChar, userChar: userChar, letterIndex: letterIndex))
                                }
                                
                                // 闪动光标
                                if isCurrentPosition {
                                    Rectangle()
                                        .fill(.blue)
                                        .frame(width: 2, height: 30)
                                        .opacity(cursorVisible ? 1.0 : 0.0)
                                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: cursorVisible)
                                }
                            }
                            .frame(width: 30, height: 40)
                            
                            // 下划线（特殊符号不显示下划线）
                            if !isSpecial {
                                Rectangle()
                                    .fill(getUnderlineColor(targetChar: targetChar, userChar: userChar, isCurrentPosition: isCurrentPosition))
                                    .frame(width: 30, height: 3)
                                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
                            } else {
                                // 特殊符号位置用透明占位符保持布局一致
                                Rectangle()
                                    .fill(.clear)
                                    .frame(width: 30, height: 3)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // 启动光标闪动动画
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                cursorVisible.toggle()
            }
        }
    }
    
    // 计算字母行分组
    private var letterRows: [(Int, [(Int, Character)])] {
        let letters = Array(targetWord.lowercased()).enumerated().map { ($0, $1) }
        var rows: [(Int, [(Int, Character)])] = []
        
        for i in stride(from: 0, to: letters.count, by: maxLettersPerRow) {
            let endIndex = min(i + maxLettersPerRow, letters.count)
            let rowLetters = Array(letters[i..<endIndex])
            rows.append((i / maxLettersPerRow, rowLetters))
        }
        
        return rows
    }
    
    // 判断字符是否为特殊符号（不需要用户输入）
    private func isSpecialCharacter(_ char: Character) -> Bool {
        let specialChars: Set<Character> = [" ", ".", ",", "-", "'", ":", ";", "!", "?", "(", ")", "[", "]", "{", "}", "/", "\\", "&", "@", "#", "$", "%", "^", "*", "+", "=", "_", "~", "`"]
        return specialChars.contains(char)
    }
    
    // 获取需要用户输入的字符（过滤掉特殊符号）
    private var inputRequiredChars: [Character] {
        return Array(targetWord.lowercased()).filter { !isSpecialCharacter($0) }
    }
    
    // 获取用户输入在原单词中的映射位置
    private func getUserInputAtPosition(_ position: Int) -> Character? {
        let inputChars = Array(userInput.lowercased())
        var inputIndex = 0
        
        for (originalIndex, char) in Array(targetWord.lowercased()).enumerated() {
            if originalIndex == position {
                if isSpecialCharacter(char) {
                    return char // 特殊符号直接返回
                } else {
                    return inputIndex < inputChars.count ? inputChars[inputIndex] : nil
                }
            }
            if !isSpecialCharacter(char) {
                inputIndex += 1
            }
        }
        return nil
    }
    
    // 获取当前输入光标应该在的位置
    private func getCurrentInputPosition() -> Int {
        let inputChars = Array(userInput.lowercased())
        var inputIndex = 0
        
        for (originalIndex, char) in Array(targetWord.lowercased()).enumerated() {
            if !isSpecialCharacter(char) {
                if inputIndex == inputChars.count {
                    return originalIndex
                }
                inputIndex += 1
            }
        }
        return targetWord.count // 如果已经输入完所有字符，返回末尾位置
    }
    
    // 获取要显示的文本（用户输入、提示或空白）
    private func getDisplayText(targetChar: Character, userChar: Character?, letterIndex: Int) -> String {
        // 如果用户已经输入了这个位置的字符，显示用户输入
        if let userChar = userChar {
            return String(userChar).lowercased()
        }
        
        // 如果显示提示且这是第一个字母，显示首字母提示
        if showHint && letterIndex == getFirstLetterIndex() {
            return String(targetChar).lowercased()
        }
        
        // 否则显示空白
        return " "
    }
    
    // 获取第一个需要输入的字母的索引位置
    private func getFirstLetterIndex() -> Int {
        for (index, char) in Array(targetWord.lowercased()).enumerated() {
            if !isSpecialCharacter(char) {
                return index
            }
        }
        return 0
    }
    
    
    private func getLetterColor(targetChar: Character, userChar: Character?, letterIndex: Int) -> Color {
        if !hasSubmitted {
            // 如果用户已经输入，显示正常颜色
            if userChar != nil {
                return .primary
            }
            // 如果显示提示且这是第一个字母，显示橙色提示
            if showHint && letterIndex == getFirstLetterIndex() {
                return .orange
            }
            // 否则透明
            return .clear
        }
        
        guard let userChar = userChar else {
            return .clear
        }
        
        return userChar == targetChar ? .green : .red
    }
    
    private func getUnderlineColor(targetChar: Character, userChar: Character?, isCurrentPosition: Bool) -> Color {
        if !hasSubmitted {
            if isCurrentPosition {
                return .blue // 当前位置使用蓝色高亮
            }
            return userChar != nil ? .blue : .gray.opacity(0.5)
        }
        
        guard let userChar = userChar else {
            return .gray.opacity(0.5)
        }
        
        return userChar == targetChar ? .green : .red
    }
}

// MARK: - 预览
#Preview {
    DictationModeView(
        word: StudyWord(
            word: "apple",
            meaning: "苹果",
            example: "I eat an apple every day.",
            difficulty: "中等",
            category: "词汇",
            grade: .high1,
            source: .imported,
            isCorrect: nil,
            answerTime: nil,
            preGeneratedOptions: nil,
            imageURL: nil,
            etymology: nil,
            memoryTip: nil,
            relatedWords: nil
        ),
        onAnswer: { _ in },
        phoneticService: PhoneticService()
    )
    .environmentObject(UserPreferencesManager(appwriteService: AppwriteService()))
}
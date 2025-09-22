import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - 家长听写模块主视图
struct ParentDictationView: View {
    @StateObject private var phoneticService = PhoneticService()
    @StateObject private var preferencesManager = UserPreferencesManager(appwriteService: AppwriteService())
    @ObservedObject var hybridManager: HybridLearningManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentWordIndex = 0
    @State private var isPlaying = false
    @State private var playCount = 0
    @State private var showSettings = false
    @State private var showPhotoCapture = false
    @State private var capturedImage: UIImage?
    @State private var showResults = false
    @State private var recognitionResults: [WordRecognitionResult] = []
    @State private var isAnalyzing = false
    
    // 听写设置
    @State private var playSpeed: Double = 1.0 // 播放速度 (0.5 - 2.0)
    @State private var repeatCount: Int = 2 // 重复次数 (1-5)
    @State private var intervalDelay: Double = 2.0 // 间隔时间 (1-5秒)
    @State private var autoPlayNext: Bool = true // 自动播放下一个单词
    @State private var showEnglishWord: Bool = false // 是否显示英文单词
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if hybridManager.todayWords.isEmpty {
                    // 加载状态
                    ProgressView("准备听写单词...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 主要内容
                    ScrollView {
                        VStack(spacing: 24) {
                            // 进度显示
                            progressSection
                            
                            // 当前单词信息
                            currentWordSection
                            
                            // 控制按钮
                            controlButtonsSection
                            
                            // 说明文字
                            instructionsSection
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // 底部按钮
                    bottomButtonsSection
                }
            }
            .navigationTitle("家长听写")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("退出") {
                        // 停止当前播放
                        isPlaying = false
                        phoneticService.stopAllAudio()
                        // 退出家长听写模式
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
            ParentDictationSettingsView(
                playSpeed: $playSpeed,
                repeatCount: $repeatCount,
                intervalDelay: $intervalDelay,
                autoPlayNext: $autoPlayNext,
                parentDictationLanguage: $preferencesManager.userPreferences.parentDictationLanguage
            )
            }
            .sheet(isPresented: $showPhotoCapture) {
                PhotoCaptureView(
                    capturedImage: $capturedImage,
                    onImageCaptured: handleImageCaptured
                )
            }
            .sheet(isPresented: $showResults) {
                DictationResultsView(
                    results: recognitionResults,
                    words: getCurrentWords(),
                    onRetry: retryDictation,
                    onNext: nextBatch
                )
            }
        }
        .onAppear {
            setupDictation()
        }
    }
    
    // MARK: - 进度显示区域
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("听写进度")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(currentWordIndex + 1) / \(hybridManager.todayWords.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(currentWordIndex + 1), total: Double(hybridManager.todayWords.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding(16)
        .background(.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - 当前单词信息区域
    private var currentWordSection: some View {
        VStack(spacing: 16) {
            if currentWordIndex < hybridManager.todayWords.count {
                let currentWord = hybridManager.todayWords[currentWordIndex]
                
                VStack(spacing: 12) {
                    // 单词序号
                    Text("第 \(currentWordIndex + 1) 个单词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    // 单词显示区域（带眼睛图标控制）
                    VStack(spacing: 8) {
                        if showEnglishWord {
                            Text(currentWord.word)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                        } else {
                            // 隐藏状态显示遮罩
                            HStack(spacing: 8) {
                                ForEach(0..<currentWord.word.count, id: \.self) { _ in
                                    Text("●")
                                        .font(.title2)
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // 眼睛图标按钮
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEnglishWord.toggle()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: showEnglishWord ? "eye.slash.fill" : "eye.fill")
                                    .font(.caption)
                                Text(showEnglishWord ? "隐藏单词" : "显示单词")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // 中文意思（始终显示）
                    Text(currentWord.meaning)
                        .font(.title3)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(minHeight: 120)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 控制按钮区域
    private var controlButtonsSection: some View {
        HStack(spacing: 20) {
            // 播放按钮
            Button(action: playCurrentWord) {
                HStack(spacing: 8) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                    Text(isPlaying ? "暂停" : "播放")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(currentWordIndex >= hybridManager.todayWords.count)
            
            // 重播按钮
            Button(action: replayCurrentWord) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                    Text("重播")
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(currentWordIndex >= hybridManager.todayWords.count)
        }
    }
    
    // MARK: - 说明文字区域
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("使用说明")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                instructionItem("1. 点击播放按钮开始听写")
                instructionItem("2. 在纸上写下听到的英文单词")
                instructionItem("3. 完成所有单词后拍照上传")
                instructionItem("4. 系统将自动检查书写正确性")
            }
        }
        .padding(16)
        .background(.orange.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func instructionItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(.orange)
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // MARK: - 底部按钮区域
    private var bottomButtonsSection: some View {
        VStack(spacing: 12) {
            if currentWordIndex >= hybridManager.todayWords.count - 1 || capturedImage != nil {
                // 拍照上传按钮
                Button(action: { showPhotoCapture = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text(capturedImage == nil ? "拍照上传听写结果" : "重新拍照")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if capturedImage != nil && !isAnalyzing {
                    // 提交分析按钮
                    Button(action: analyzeHandwriting) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("提交分析")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if isAnalyzing {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("正在分析手写内容...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                
                // 测试按钮 - 使用预设的听写测试图片
                Button(action: useTestImage) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.badge.checkmark")
                            .font(.title2)
                        Text("使用测试图片")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // 下一个单词按钮
                Button(action: nextWord) {
                    HStack(spacing: 12) {
                        Text("下一个单词")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(currentWordIndex >= hybridManager.todayWords.count)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - 功能方法
    private func setupDictation() {
        // 初始化听写设置
        playSpeed = preferencesManager.userPreferences.dictationVoiceMode == .english ? 1.0 : 0.8
        
        // 自动开始播放第一个单词
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if !hybridManager.todayWords.isEmpty && !isPlaying {
                playCurrentWord()
            }
        }
    }
    
    private func playCurrentWord() {
        guard currentWordIndex < hybridManager.todayWords.count else { return }
        
        let currentWord = hybridManager.todayWords[currentWordIndex]
        isPlaying = true
        
        // 根据语言设置播放音频
        playAudioForCurrentWord(currentWord) {
            DispatchQueue.main.asyncAfter(deadline: .now() + intervalDelay) {
                playCount += 1
                if playCount < repeatCount {
                    // 继续重复播放
                    playCurrentWord()
                } else {
                    // 播放完成
                    isPlaying = false
                    playCount = 0
                    
                    // 根据设置决定是否自动播放下一个单词
                    if autoPlayNext {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            autoPlayNextWord()
                        }
                    }
                }
            }
        }
    }
    
    private func playAudioForCurrentWord(_ word: StudyWord, completion: @escaping () -> Void) {
        let language = preferencesManager.userPreferences.parentDictationLanguage
        
        switch language {
        case .english:
            // 只播放英文
            phoneticService.playEnglishText(word.word, completion: completion)
            
        case .chinese:
            // 只播放中文
            phoneticService.playChineseText(word.meaning, completion: completion)
            
        case .both:
            // 先播放英文，再播放中文
            phoneticService.playEnglishText(word.word) {
                // 英文播放完成后，延迟0.8秒播放中文
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    phoneticService.playChineseText(word.meaning, completion: completion)
                }
            }
        }
    }
    
    private func autoPlayNextWord() {
        // 检查是否还有下一个单词
        if currentWordIndex < hybridManager.todayWords.count - 1 {
            nextWord()
            // 延迟一下再自动播放，给用户一点准备时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                playCurrentWord()
            }
        }
    }
    
    private func replayCurrentWord() {
        playCount = 0
        playCurrentWord()
    }
    
    private func nextWord() {
        if currentWordIndex < hybridManager.todayWords.count - 1 {
            currentWordIndex += 1
            isPlaying = false
            playCount = 0
            showEnglishWord = false // 重置为隐藏状态
        }
    }
    
    private func handleImageCaptured() {
        // 图片捕获完成的处理
        showPhotoCapture = false
    }
    
    private func useTestImage() {
        // 使用项目中的测试图片
        if let testImage = UIImage(named: "听写测试") {
            capturedImage = testImage
            analyzeHandwriting()
        } else {
            print("❌ 无法加载测试图片")
            // 显示错误提示
            showErrorAndFallback()
        }
    }
    
    private func analyzeHandwriting() {
        guard let image = capturedImage else { 
            print("❌ 错误: 没有捕获到图片")
            return 
        }
        
        print("🚀 ===== 开始分析手写内容 =====")
        print("📱 调用位置: ParentDictationView.analyzeHandwriting()")
        print("📷 图片来源: \(capturedImage != nil ? "已加载" : "未加载")")
        
        isAnalyzing = true
        
        let expectedWords = getCurrentWords().map { $0.word }
        print("🎯 当前批次期望单词: \(expectedWords)")
        
        HandwritingRecognitionService.shared.recognizeHandwriting(
            image: image,
            expectedWords: expectedWords
        ) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                
                switch result {
                case .success(let handwritingResults):
                    print("✅ 识别服务返回成功")
                    print("📊 识别结果数量: \(handwritingResults.count)")
                    
                    // 转换为WordRecognitionResult格式
                    self.recognitionResults = handwritingResults.map { handwritingResult in
                        let result = WordRecognitionResult(
                            expectedWord: handwritingResult.expectedWord,
                            recognizedWord: handwritingResult.recognizedWord,
                            isCorrect: handwritingResult.isCorrect,
                            confidence: handwritingResult.confidence,
                            isOrderCorrect: handwritingResult.isOrderCorrect,
                            actualPosition: handwritingResult.actualPosition
                        )
                        print("🔄 转换结果: \(handwritingResult.expectedWord) -> \(handwritingResult.recognizedWord)")
                        print("   - 正确性: \(handwritingResult.isCorrect ? "✅" : "❌")")
                        print("   - 顺序正确: \(handwritingResult.isOrderCorrect ? "✅" : "❌")")
                        print("   - 置信度: \(String(format: "%.2f", handwritingResult.confidence))")
                        return result
                    }
                    
                    print("🎉 准备显示识别结果界面")
                    self.showResults = true
                    
                case .failure(let error):
                    print("❌ 手写识别失败: \(error.localizedDescription)")
                    print("🔄 回退到错误处理流程")
                    // 显示错误提示或回退到模拟结果
                    self.showErrorAndFallback()
                }
                print("🚀 ===== 分析手写内容完成 =====")
            }
        }
    }
    
    private func showErrorAndFallback() {
        // 如果识别失败，显示错误并提供重试选项
        let alert = UIAlertController(
            title: "识别失败",
            message: "手写识别遇到问题，请重新拍照或稍后重试。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "重新拍照", style: .default) { _ in
            self.showPhotoCapture = true
        })
        
        alert.addAction(UIAlertAction(title: "跳过", style: .cancel) { _ in
            // 生成模拟结果作为备选方案
            self.generateFallbackResults()
        })
        
        // 获取当前的根视图控制器来显示alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func generateFallbackResults() {
        // 生成备选的模拟结果
        recognitionResults = getCurrentWords().map { word in
            let isCorrect = [true, true, true, false].randomElement()! // 75%正确率
            return WordRecognitionResult(
                expectedWord: word.word,
                recognizedWord: word.word, // 假设识别正确
                isCorrect: isCorrect,
                confidence: Double.random(in: 0.7...0.95),
                isOrderCorrect: isCorrect, // 简化：如果正确则顺序也正确
                actualPosition: nil // 模拟结果不提供实际位置
            )
        }
        showResults = true
    }
    
    private func getCurrentWords() -> [StudyWord] {
        let startIndex = max(0, currentWordIndex - 4)
        let endIndex = min(currentWordIndex + 1, hybridManager.todayWords.count)
        return Array(hybridManager.todayWords[startIndex..<endIndex])
    }
    
    private func retryDictation() {
        // 重新开始当前批次的听写
        currentWordIndex = max(0, currentWordIndex - 4)
        capturedImage = nil
        recognitionResults = []
        showResults = false
    }
    
    private func nextBatch() {
        // 进入下一批听写
        currentWordIndex = min(currentWordIndex + 5, hybridManager.todayWords.count)
        capturedImage = nil
        recognitionResults = []
        showResults = false
    }
}

// MARK: - 听写设置视图
struct ParentDictationSettingsView: View {
    @Binding var playSpeed: Double
    @Binding var repeatCount: Int
    @Binding var intervalDelay: Double
    @Binding var autoPlayNext: Bool
    @Binding var parentDictationLanguage: ParentDictationLanguage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("播放设置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("播放速度: \(playSpeed, specifier: "%.1f")x")
                            .font(.subheadline)
                        Slider(value: $playSpeed, in: 0.5...2.0, step: 0.1)
                    }
                    
                    Stepper("重复次数: \(repeatCount)", value: $repeatCount, in: 1...5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("间隔时间: \(intervalDelay, specifier: "%.1f")秒")
                            .font(.subheadline)
                        Slider(value: $intervalDelay, in: 1.0...5.0, step: 0.5)
                    }
                    
                    Toggle("自动播放下一个单词", isOn: $autoPlayNext)
                }
                
                Section("语言设置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("播放语言")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(ParentDictationLanguage.allCases, id: \.self) { language in
                            Button(action: {
                                parentDictationLanguage = language
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: language.icon)
                                        .font(.title2)
                                        .foregroundColor(language.iconColor)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(language.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text(language.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if parentDictationLanguage == language {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section("说明") {
                    Text("• 播放速度：调整单词朗读的快慢")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• 重复次数：每个单词重复播放的次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• 间隔时间：每次播放之间的停顿时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("听写设置")
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

// MARK: - 拍照视图
struct PhotoCaptureView: View {
    @Binding var capturedImage: UIImage?
    let onImageCaptured: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let image = capturedImage {
                    // 显示已捕获的图片
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                } else {
                    // 占位符
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.1))
                        .frame(height: 300)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("请拍照或选择听写结果")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                VStack(spacing: 16) {
                    // 拍照按钮
                    Button(action: { showCamera = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("拍照")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 从相册选择按钮
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                            Text("从相册选择")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("上传听写结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                if capturedImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("确定") {
                            onImageCaptured()
                        }
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage)
        }
    }
}

// MARK: - 相机视图
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 听写结果视图
struct DictationResultsView: View {
    let results: [WordRecognitionResult]
    let words: [StudyWord]
    let onRetry: () -> Void
    let onNext: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showPDFPreview = false
    
    var correctCount: Int {
        results.filter { $0.isCorrect }.count
    }
    
    var accuracy: Double {
        guard !results.isEmpty else { return 0 }
        return Double(correctCount) / Double(results.count) * 100
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 总体结果
                    summarySection
                    
                    // 详细结果
                    detailsSection
                    
                    // 操作按钮
                    actionsSection
                }
                .padding(20)
            }
            .navigationTitle("听写结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(spacing: 16) {
            // 准确率圆环
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: accuracy / 100)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(accuracy))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("准确率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 统计信息
            HStack(spacing: 32) {
                statItem("总计", "\(results.count)", .blue)
                statItem("正确", "\(correctCount)", .green)
                statItem("错误", "\(results.count - correctCount)", .red)
            }
        }
        .padding(20)
        .background(.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func statItem(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("详细结果")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                    resultCard(result, index: index + 1)
                }
            }
        }
    }
    
    private func resultCard(_ result: WordRecognitionResult, index: Int) -> some View {
        HStack(spacing: 16) {
            // 序号和状态图标
            VStack(spacing: 4) {
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(result.isCorrect ? .green : .red)
                    .clipShape(Circle())
                
                // 错误类型图标
                if !result.isCorrect {
                    Image(systemName: "textformat.abc")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // 期望单词
                HStack {
                    Text("期望: \(result.expectedWord)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.isCorrect ? .green : .red)
                }
                
                // 识别结果（如果错误）
                if !result.isCorrect {
                    Text("识别: \(result.recognizedWord)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // 错误详情
                HStack(spacing: 12) {
                    // 错误类型标签
                    Text(result.errorType)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(result.isCorrect ? .green : .orange)
                        )
                    
                    // 置信度
                    Text("置信度: \(Int(result.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 书写位置信息
                    if let actualPos = result.actualPosition {
                        Text("书写位置: \(actualPos + 1)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            // 左侧边框颜色指示
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 4)
                .foregroundColor(result.isCorrect ? .green : .orange),
            alignment: .leading
        )
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // PDF导出按钮
            Button(action: {
                showPDFPreview = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                    Text("导出单词表")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if accuracy < 80 {
                Button(action: onRetry) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                        Text("重新听写")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            Button(action: onNext) {
                HStack(spacing: 12) {
                    Text("继续下一批")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $showPDFPreview) {
            PDFPreviewView(words: words, recognitionResults: results)
        }
    }
}

// MARK: - 单词识别结果模型
struct WordRecognitionResult {
    let expectedWord: String
    let recognizedWord: String
    let isCorrect: Bool
    let confidence: Double
    let isOrderCorrect: Bool // 顺序是否正确
    let actualPosition: Int? // 实际书写位置
    
    // 错误类型
    var errorType: String {
        if isCorrect {
            return "正确"
        } else if recognizedWord.lowercased() != expectedWord.lowercased() {
            return "拼写错误"
        } else {
            return "识别错误"
        }
    }
}

#Preview {
    ParentDictationView(hybridManager: HybridLearningManager(appwriteService: AppwriteService()))
}

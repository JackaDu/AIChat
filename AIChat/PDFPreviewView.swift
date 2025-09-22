import SwiftUI
import PDFKit

// MARK: - PDF预览视图
struct PDFPreviewView: View {
    let words: [StudyWord]
    let recognitionResults: [WordRecognitionResult]? // 可选的识别结果，用于筛选错词
    @State private var selectedMode: PDFExportMode = .dictationWord // 默认选择"默写单词"
    @State private var selectedStyleIndex: Int = 0
    @State private var showWrongWordsOnly: Bool = false // 只看错词选项
    @State private var pdfDocument: PDFDocument?
    @State private var isGenerating: Bool = false
    @State private var showShareSheet: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // 计算属性：根据筛选条件获取要导出的单词
    private var filteredWords: [StudyWord] {
        guard showWrongWordsOnly, let results = recognitionResults else {
            return words
        }
        
        // 根据识别结果筛选错词
        let wrongWordSet = Set(results.filter { !$0.isCorrect }.map { $0.expectedWord.lowercased() })
        return words.filter { wrongWordSet.contains($0.word.lowercased()) }
    }
    
    private let styleConfigs: [PDFStyleConfig] = [
        .default, .orange, .purple, .navy, .dark
    ]
    
    private let styleNames = ["青色", "橙色", "紫色", "深蓝", "深灰"]
    private let styleColors: [Color] = [
        Color(red: 0.2, green: 0.7, blue: 0.9),
        Color(red: 1.0, green: 0.6, blue: 0.2),
        Color(red: 0.6, green: 0.4, blue: 0.9),
        Color(red: 0.2, green: 0.3, blue: 0.5),
        Color(red: 0.3, green: 0.3, blue: 0.3)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 控制面板
                controlPanel
                
                // PDF预览
                pdfPreviewArea
            }
            .navigationTitle("预览 PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("导出 PDF") {
                        exportPDF()
                    }
                    .disabled(pdfDocument == nil || isGenerating)
                }
            }
            .onAppear {
                generatePreview()
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfDocument = pdfDocument {
                    ShareSheet(items: [createPDFURL(pdfDocument)])
                }
            }
        }
    }
    
    // MARK: - 控制面板
    private var controlPanel: some View {
        VStack(spacing: 16) {
            // 导出模式选择
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("导出模式")
                        .font(.headline)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    ForEach(PDFExportMode.allCases, id: \.self) { mode in
                        ModeSelectionCard(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            onTap: {
                                selectedMode = mode
                                generatePreview()
                            }
                        )
                    }
                }
            }
            
            // 筛选选项
            if recognitionResults != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.red)
                        Text("筛选选项")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Toggle("只看错词", isOn: $showWrongWordsOnly)
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        .onChange(of: showWrongWordsOnly) {
                            generatePreview()
                        }
                }
            }
            
            // 样式选择
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "paintbrush")
                        .foregroundColor(.orange)
                    Text("样式选择")
                        .font(.headline)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    ForEach(0..<styleConfigs.count, id: \.self) { index in
                        StyleSelectionCard(
                            name: styleNames[index],
                            color: styleColors[index],
                            isSelected: selectedStyleIndex == index,
                            onTap: {
                                selectedStyleIndex = index
                                generatePreview()
                            }
                        )
                    }
                }
            }
            
            Divider()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - PDF预览区域
    private var pdfPreviewArea: some View {
        Group {
            if isGenerating {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在生成预览...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else if let pdfDocument = pdfDocument {
                PDFKitView(pdfDocument: pdfDocument)
                    .background(Color(.systemBackground))
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("预览生成失败")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button("重新生成") {
                        generatePreview()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - 生成预览
    private func generatePreview() {
        print("🔄 开始生成PDF预览...")
        print("📊 预览参数:")
        print("   - 原始单词数量: \(words.count)")
        print("   - 筛选后单词数量: \(filteredWords.count)")
        print("   - 导出模式: \(selectedMode.displayName)")
        print("   - 样式索引: \(selectedStyleIndex)")
        print("   - 只看错词: \(showWrongWordsOnly)")
        
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let exportData = PDFExportData(
                words: filteredWords,
                mode: selectedMode,
                style: styleConfigs[selectedStyleIndex]
            )
            
            let generatedPDF = PDFExportService.shared.generatePDF(data: exportData)
            
            DispatchQueue.main.async {
                self.pdfDocument = generatedPDF
                self.isGenerating = false
                
                if generatedPDF != nil {
                    print("✅ PDF预览生成成功")
                } else {
                    print("❌ PDF预览生成失败")
                }
            }
        }
    }
    
    // MARK: - 导出PDF
    private func exportPDF() {
        guard let pdfDocument = pdfDocument else { return }
        
        print("📤 开始导出PDF...")
        showShareSheet = true
    }
    
    // MARK: - 创建PDF文件URL
    private func createPDFURL(_ pdfDocument: PDFDocument) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "Vocabulary_\(selectedMode.rawValue)_\(timestamp)"
        
        return PDFExportService.shared.savePDF(pdfDocument, filename: filename) ?? 
               FileManager.default.temporaryDirectory.appendingPathComponent("\(filename).pdf")
    }
}

// MARK: - 模式选择卡片
struct ModeSelectionCard: View {
    let mode: PDFExportMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(mode.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 样式选择卡片
struct StyleSelectionCard: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(color, lineWidth: isSelected ? 2 : 0)
                    )
                
                Text(name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? color : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - PDFKit视图包装
struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== pdfDocument {
            pdfView.document = pdfDocument
        }
    }
}

// MARK: - 分享表单
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 便利初始化方法
extension PDFPreviewView {
    init(words: [StudyWord]) {
        self.words = words
        self.recognitionResults = nil
    }
}

// MARK: - 预览
#Preview {
    // 创建示例单词数据
    let sampleWords: [StudyWord] = []
    return PDFPreviewView(words: sampleWords, recognitionResults: nil)
}

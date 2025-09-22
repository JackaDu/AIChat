import SwiftUI
import PDFKit

// MARK: - 通用PDF导出视图
struct SharedPDFExportView: View {
    let words: [StudyWord]
    let title: String // 自定义标题，如"错词本导出"、"列表学习导出"等
    let recognitionResults: [WordRecognitionResult]? // 可选的识别结果，用于筛选错词
    @State private var selectedMode: PDFExportMode = .chineseEnglish // 默认选择"中英词表"
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
                    Button("导出") {
                        showShareSheet = true
                    }
                    .disabled(pdfDocument == nil || isGenerating)
                }
            }
            .onAppear {
                generatePreview()
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfDocument = pdfDocument {
                    ShareSheet(items: [pdfDocument.dataRepresentation() as Any])
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
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    ForEach(PDFExportMode.allCases, id: \.self) { mode in
                        Button(action: {
                            selectedMode = mode
                            generatePreview()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: mode.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedMode == mode ? .white : .blue)
                                
                                Text(mode.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedMode == mode ? .white : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedMode == mode ? Color.blue : Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // 筛选选项（仅在有识别结果时显示）
            if recognitionResults != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.orange)
                        Text("筛选选项")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Toggle("只看错词", isOn: $showWrongWordsOnly)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                        .onChange(of: showWrongWordsOnly) { generatePreview() }
                }
            }
            
            // 样式选择
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "paintbrush")
                        .foregroundColor(.purple)
                    Text("样式选择")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    ForEach(0..<styleColors.count, id: \.self) { index in
                        Button(action: {
                            selectedStyleIndex = index
                            generatePreview()
                        }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(styleColors[index])
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedStyleIndex == index ? 3 : 0)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                
                                Text(styleNames[index])
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - PDF预览区域
    private var pdfPreviewArea: some View {
        VStack(spacing: 12) {
            HStack {
                Text("预览")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isGenerating {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("生成中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("共 \(filteredWords.count) 个单词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            if let pdfDocument = pdfDocument {
                PDFViewRepresentable(document: pdfDocument)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("生成预览中...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - 生成预览
    private func generatePreview() {
        guard !filteredWords.isEmpty else {
            pdfDocument = nil
            return
        }
        
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let exportData = PDFExportData(
                words: filteredWords,
                mode: selectedMode,
                style: styleConfigs[selectedStyleIndex],
                customTitle: title
            )
            
            let document = PDFExportService.shared.generatePDF(data: exportData)
            
            DispatchQueue.main.async {
                self.pdfDocument = document
                self.isGenerating = false
            }
        }
    }
    
    // 便利初始化器（不带识别结果）
    init(words: [StudyWord], title: String) {
        self.words = words
        self.title = title
        self.recognitionResults = nil
    }
    
    // 完整初始化器（带识别结果）
    init(words: [StudyWord], title: String, recognitionResults: [WordRecognitionResult]) {
        self.words = words
        self.title = title
        self.recognitionResults = recognitionResults
    }
}

// MARK: - PDFView包装器
struct PDFViewRepresentable: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

// ShareSheet已在PDFPreviewView中定义，此处不重复定义

// MARK: - 预览
#Preview {
    SharedPDFExportView(
        words: [],
        title: "错词本导出"
    )
}
